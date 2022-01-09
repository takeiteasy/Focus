//
//  Texture.m
//  test_focus
//
//  Created by George Watson on 05/07/2017.
//  Copyright © 2017 George Watson. All rights reserved.
//

#import "Texture.h"
#define STB_IMAGE_IMPLEMENTATION
#include "3rdparty/stb_image.h"

@implementation Texture
-(nullable instancetype)initWithFileAtLocation:(nonnull const char*)tgaLocation {
  stbi_set_flip_vertically_on_load(true);
  unsigned char* img = stbi_load(tgaLocation, &_width, &_height, &_chans, STBI_rgb_alpha);
  
  _data = [[NSData alloc] initWithBytes:img
                                 length:(_width * _height * _chans)];
  stbi_image_free(img);
  return self;
}
@end
