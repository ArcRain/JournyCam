//
//  JournyCamCore+Utility.m
//  JournyCam
//
//  Created by Sora Yang on 1/30/16.
//  Copyright © 2016 Sora Yang. All rights reserved.
//

#import "JournyCamCore+Utility.h"

@implementation JournyCamCore (Utility)

- (NSDictionary *)metaDataFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (NULL == sampleBuffer) {
        return nil;
    }
    
    CMAttachmentMode mode = kCMAttachmentMode_ShouldPropagate;
    CFDictionaryRef metaDataCopyRef = CMCopyDictionaryOfAttachments(NULL, sampleBuffer, mode);
    if (NULL == metaDataCopyRef) {
        return nil;
    }
    return (__bridge_transfer NSDictionary *)metaDataCopyRef;
}

- (UIImageOrientation)UIImageOrientationFromCGImageOrientation:(int)value {
    switch (value) {
        case 1:
            return UIImageOrientationUp;
        case 3:
            return UIImageOrientationDown;
        case 8:
            return UIImageOrientationLeft;
        case 6:
            return UIImageOrientationRight;
        case 2:
            return UIImageOrientationUpMirrored;
        case 4:
            return UIImageOrientationDownMirrored;
        case 5:
            return UIImageOrientationLeftMirrored;
        case 7:
            return UIImageOrientationRightMirrored;
        default:
            return UIImageOrientationUp;
    }
}

- (CGImageRef)CGImageARGBFromImageBuffer:(CMSampleBufferRef)sampleBuffer CF_RETURNS_RETAINED
{
    CVImageBufferRef imageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (NULL == imageBufferRef) {
        return NULL;
    }
    
    CVReturn result = CVPixelBufferLockBaseAddress(imageBufferRef, kCVPixelBufferLock_ReadOnly);
    if (kCVReturnSuccess != result) {
        return NULL;
    }
    CGImageRef imageRef = NULL;
    uint8_t *lumaBuffer = (uint8_t *)CVPixelBufferGetBaseAddress(imageBufferRef);
    if (NULL != lumaBuffer) {
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(lumaBuffer,
                                                     CVPixelBufferGetWidth(imageBufferRef),
                                                     CVPixelBufferGetHeight(imageBufferRef),
                                                     8,
                                                     CVPixelBufferGetBytesPerRow(imageBufferRef),
                                                     rgbColorSpace,
                                                     kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGColorSpaceRelease(rgbColorSpace);
        imageRef = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
    }
    CVPixelBufferUnlockBaseAddress(imageBufferRef, kCVPixelBufferLock_ReadOnly);
    return imageRef;
}

@end
