//
//  JournyCamCore+Utility.h
//  JournyCam
//
//  Created by Sora Yang on 1/30/16.
//  Copyright © 2016 Sora Yang. All rights reserved.
//

#import "JournyCamCore.h"

@interface JournyCamCore (Utility)

- (NSDictionary *)metaDataFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (UIImageOrientation)UIImageOrientationFromCGImageOrientation:(int)value;
- (CGImageRef)CGImageARGBFromImageBuffer:(CMSampleBufferRef)sampleBuffer;

@end
