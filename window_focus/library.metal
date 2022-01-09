//
//  library.metal
//  test_focus
//
//  Created by George Watson on 05/07/2017.
//  Copyright © 2017 George Watson. All rights reserved.
//

#import <metal_stdlib>
using namespace metal;

typedef struct {
  float4 clipSpacePosition [[position]];
  float2 textureCoordinate;
} RasterizerData;

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

vertex RasterizerData
vertexShader(uint vertexID [[ vertex_id ]],
             constant AAPLVertex *vertexArray [[ buffer(AAPLVertexInputIndexVertices) ]],
             constant vector_uint2 *viewportSizePointer  [[ buffer(AAPLVertexInputIndexViewportSize) ]]) {
  RasterizerData out;
  
  float2 pixelSpacePosition = vertexArray[vertexID].position.xy;
  
  out.clipSpacePosition.xy = pixelSpacePosition;
  out.clipSpacePosition.z = 0.0;
  out.clipSpacePosition.w = 1.0;
  out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
  
  return out;
}

fragment float4
samplingShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(AAPLTextureIndexInput) ]]) {
  constexpr sampler textureSampler(mag_filter::nearest,
                                   min_filter::nearest);
  
  const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
  
  return float4(colorSample);
}

kernel void
gaussian_blur_2d(texture2d<float, access::read> inTexture [[texture(AAPLTextureIndexInput)]],
                 texture2d<float, access::write> outTexture [[texture(AAPLTextureIndexOutput)]],
                 texture2d<float, access::read> weights [[texture(AAPLTextureIndexWeight)]],
                 uint2 gid [[thread_position_in_grid]]) {
  int size = weights.get_width();
  int radius = size / 2;

  float4 accumColor(0, 0, 0, 0);
  for (int j = 0; j < size; ++j) {
    for (int i = 0; i < size; ++i) {
      uint2 kernelIndex(i, j);
      uint2 textureIndex(gid.x + (i - radius), gid.y + (j - radius));
      float4 color = inTexture.read(textureIndex).rgba;
      float4 weight = weights.read(kernelIndex).rrrr;
      accumColor += weight * color;
    }
  }
  outTexture.write(float4(accumColor.rgb, 1), gid);
}
