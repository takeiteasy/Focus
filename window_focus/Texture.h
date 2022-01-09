//
//  Texture.h
//  test_focus
//
//  Created by George Watson on 05/07/2017.
//  Copyright © 2017 George Watson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Texture : NSObject
-(nullable instancetype) initWithFileAtLocation:(nonnull const char*)location;
@property (nonatomic, readonly) int width, height, chans;
@property (nonatomic, readonly, nonnull) NSData *data;
@end
