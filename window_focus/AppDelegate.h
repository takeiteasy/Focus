//
//  AppDelegate.h
//  test_focus
//
//  Created by George Watson on 05/07/2017.
//  Copyright © 2017 George Watson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import "Texture.h"

typedef enum AAPLVertexInputIndex {
  AAPLVertexInputIndexVertices     = 0,
  AAPLVertexInputIndexViewportSize = 1,
} AAPLVertexInputIndex;

typedef enum AAPLTextureIndex {
  AAPLTextureIndexInput  = 0,
  AAPLTextureIndexOutput = 1,
  AAPLTextureIndexWeight = 2
} AAPLTextureIndex;

typedef struct {
  vector_float2 position;
  vector_float2 textureCoordinate;
} AAPLVertex;

static const AAPLVertex quadVertices[] = {
  { {  1.f,  -1.f }, { 1.f, 0.f } },
  { { -1.f,  -1.f }, { 0.f, 0.f } },
  { { -1.f,   1.f }, { 0.f, 1.f } },
  
  { {  1.f,  -1.f }, { 1.f, 0.f } },
  { { -1.f,   1.f }, { 0.f, 1.f } },
  { {  1.f,   1.f }, { 1.f, 1.f } },
};

@interface AppDelegate : NSObject <NSApplicationDelegate, MTKViewDelegate> {
  NSWindow* _window;
  id<MTLDevice> _device;
  id<MTLLibrary> _library;
  id<MTLRenderPipelineState> _pipelineState;
  id<MTLBuffer> _vertexBuffer;
  NSUInteger _numVertices;
  id<MTLCommandQueue> _commandQueue;
  id<MTLTexture> _in_texture, _out_texture, _weight_texture;
  vector_uint2 _viewportSize;
  
  id<MTLComputePipelineState> _pipeline;
  id<MTLBuffer> _uniformBuffer;
  
  MTLSize _threadgroupSize;
  MTLSize _threadgroupCount;
}
@end
