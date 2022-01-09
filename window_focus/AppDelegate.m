//
//  AppDelegate.m
//  test_focus
//
//  Created by George Watson on 05/07/2017.
//  Copyright © 2017 George Watson. All rights reserved.
//

#import "AppDelegate.h"
#import "helper.h"

static const char* original_app = NULL;
static int enable_check = 0;

@implementation AppDelegate
-(id)init {
  NSError *error = NULL;
  
  original_app = [CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListExcludeDesktopElements | kCGWindowListOptionOnScreenOnly, 0))[0][@"kCGWindowOwnerName"] UTF8String];
  
  NSAppleScript* hide_script = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:get_file_contents(RES("hide.scpt")), original_app]];
  if (![hide_script executeAndReturnError:nil]) {
    NSLog(@"Failed to minimize current program");
    return nil;
  }
  
  NSAppleScript* capture_script = [[NSAppleScript alloc] initWithSource:get_file_contents(RES("capture.scpt"))];
  if (![capture_script executeAndReturnError:nil] || access(TMP_BG_LOC, F_OK)) {
    NSLog(@"Failed to take screenshot");
    return nil;
  }
  
  NSScreen *screen = [NSScreen mainScreen];
  CGFloat scale_f = [screen backingScaleFactor];
  NSRect frame = [screen visibleFrame];
  _viewportSize.x = frame.size.width * scale_f;
  _viewportSize.y = (frame.size.height * scale_f) + (4 * scale_f);
  frame.size.height += (4 * scale_f);
  
  _window = [[NSWindow alloc] initWithContentRect:frame
                                        styleMask:NSWindowStyleMaskBorderless
                                          backing:NSBackingStoreBuffered
                                            defer:NO];
  [_window center];
  [_window setTitle: [[NSProcessInfo processInfo] processName]];
  
  _device = MTLCreateSystemDefaultDevice();
  
  MTKView* view = [[MTKView alloc] initWithFrame:frame
                                          device:_device];
  [view setDelegate:self];
  
  view.clearColor = MTLClearColorMake(220.0f / 255.0f, 220.0f / 255.0f, 220.0f / 255.0f, 1.0f);
  
  _commandQueue = [_device newCommandQueue];
  
  Texture* bg = [[Texture alloc] initWithFileAtLocation:TMP_BG_LOC];
  if (!bg) {
    NSLog(@"Failed to create the image from from screenshot!");
    return nil;
  }
  
  MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
  textureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
  textureDescriptor.width = bg.width;
  textureDescriptor.height = bg.height;
  
  _in_texture = [_device newTextureWithDescriptor:textureDescriptor];
  NSUInteger bytesPerRow = bg.chans * bg.width;
  MTLRegion region = {
    {0 ,       0,         0}, // MTLOrigin
    {bg.width, bg.height, 1}  // MTLSize
  };
  
  [_in_texture replaceRegion:region
                 mipmapLevel:0
                   withBytes:bg.data.bytes
                 bytesPerRow:bytesPerRow];
  
  textureDescriptor.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;
  _out_texture = [_device newTextureWithDescriptor:textureDescriptor];
  
  const float radius = 10.f;
  const float sigma = 3.f;
  const int size = (round(radius) * 2) + 1;
  
  float delta = 0;
  float expScale = 0;
  if (radius > 0.0) {
    delta = (radius * 2) / (size - 1);;
    expScale = -1 / (2 * sigma * sigma);
  }
  
  float *weights = malloc(sizeof(float) * size * size);
  
  float weightSum = 0;
  float y = -radius;
  for (int j = 0; j < size; ++j, y += delta) {
    float x = -radius;
    for (int i = 0; i < size; ++i, x += delta) {
      float weight = expf((x * x + y * y) * expScale);
      weights[j * size + i] = weight;
      weightSum += weight;
    }
  }
  
  const float weightScale = 1 / weightSum;
  for (int j = 0; j < size; ++j) {
    for (int i = 0; i < size; ++i) {
      weights[j * size + i] *= weightScale;
    }
  }
  
  MTLTextureDescriptor *w_textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR32Float
                                                                                                 width:size
                                                                                                height:size
                                                                                             mipmapped:NO];
  _weight_texture = [_device newTextureWithDescriptor:w_textureDescriptor];
  
  MTLRegion w_region = MTLRegionMake2D(0, 0, size, size);
  [_weight_texture replaceRegion:w_region mipmapLevel:0 withBytes:weights bytesPerRow:sizeof(float) * size];
  
  free(weights);
  
  _vertexBuffer = [_device newBufferWithBytes:quadVertices
                                       length:sizeof(quadVertices)
                                      options:MTLResourceStorageModeShared];
  
  _numVertices = sizeof(quadVertices) / sizeof(AAPLVertex);
  
#ifdef NO_XCODE
  _library = [_device newLibraryWithSource:get_file_contents(RES("library.metal"))
                                   options:nil
                                     error:&error];
  if(!_library) {
    NSLog(@"Failed to compile shaders: %@", [error localizedDescription]);
    return nil;
  }
#else
  _library = [_device newDefaultLibrary];
#endif
  
  id<MTLFunction> vertexFunction   = [_library newFunctionWithName:@"vertexShader"];
  id<MTLFunction> fragmentFunction = [_library newFunctionWithName:@"samplingShader"];
  
  MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
  pipelineStateDescriptor.label = @"Texturing Pipeline";
  pipelineStateDescriptor.vertexFunction = vertexFunction;
  pipelineStateDescriptor.fragmentFunction = fragmentFunction;
  pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
  
  _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                           error:&error];
  if (!_pipelineState) {
    NSLog(@"Failed to created pipeline state, error %@", error);
    return nil;
  }
  
  _pipeline = [_device newComputePipelineStateWithFunction:[_library newFunctionWithName:@"gaussian_blur_2d"]
                                                     error:&error];
  if (!_pipeline) {
    NSLog(@"Faield to create pipeline, error %@", error);
    return nil;
  }
  
  _threadgroupSize = MTLSizeMake(16, 16, 1);
  _threadgroupCount.width  = (_in_texture.width  + _threadgroupSize.width -  1) / _threadgroupSize.width;
  _threadgroupCount.height = (_in_texture.height + _threadgroupSize.height - 1) / _threadgroupSize.height;
  _threadgroupCount.depth = 1;
  
  [_window setContentView:view];
  [_window makeKeyAndOrderFront:NSApp];
  [_window setIgnoresMouseEvents:YES];
  
  NSAppleScript* focus_script = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:get_file_contents(RES("focus.scpt")), original_app]];
  if (![focus_script executeAndReturnError:nil]) {
    NSLog(@"Failed focus running process");
    return nil;
  }
  
  enable_check = 1;
  
  return self;
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)theApplication {
  (void)theApplication;
  return YES;
}

-(void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size {
  (void)view;
  (void)size;
}

-(void)drawInMTKView:(MTKView*)view {
  if (enable_check) {
    const char* test_app = [CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListExcludeDesktopElements | kCGWindowListOptionOnScreenOnly, 0))[0][@"kCGWindowOwnerName"] UTF8String];
    if (strcmp(original_app, test_app))
      [NSApp terminate:nil];
  }
  
  id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  commandBuffer.label = @"MyCommand";
  
  id <MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
  
  [computeEncoder setComputePipelineState:_pipeline];
  
  [computeEncoder setTexture:_in_texture
                     atIndex:AAPLTextureIndexInput];
  
  [computeEncoder setTexture:_out_texture
                     atIndex:AAPLTextureIndexOutput];
  
  [computeEncoder setTexture:_weight_texture
                     atIndex:AAPLTextureIndexWeight];
  
  [computeEncoder dispatchThreadgroups:_threadgroupCount
                 threadsPerThreadgroup:_threadgroupSize];
  
  [computeEncoder endEncoding];
  
  MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
  if(renderPassDescriptor != nil) {
    id <MTLRenderCommandEncoder> renderEncoder =
    [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    renderEncoder.label = @"MyRenderEncoder";
    
    [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];
    
    [renderEncoder setRenderPipelineState:_pipelineState];
    
    [renderEncoder setVertexBuffer:_vertexBuffer
                            offset:0
                           atIndex:AAPLVertexInputIndexVertices];
    
    [renderEncoder setVertexBytes:&_viewportSize
                           length:sizeof(_viewportSize)
                          atIndex:AAPLVertexInputIndexViewportSize];
    
    [renderEncoder setFragmentTexture:_out_texture
                              atIndex:AAPLTextureIndexInput];
    
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:0
                      vertexCount:_numVertices];
    
    [renderEncoder endEncoding];
    [commandBuffer presentDrawable:view.currentDrawable];
  }
  
  [commandBuffer commit];
}

-(void)dealloc {
  int ret = remove(TMP_BG_LOC);
  if (ret != 0)
    NSLog(@"Failed to delete temporary screenshot (%d): \"%s\"", ret, TMP_BG_LOC);
}
@end
