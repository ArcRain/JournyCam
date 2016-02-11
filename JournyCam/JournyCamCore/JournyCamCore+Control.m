//
//  JournyCamCore+Control.m
//  JournyCam
//
//  Created by Sora Yang on 10/1/15.
//  Copyright © 2015 Sora Yang. All rights reserved.
//

#import <objc/runtime.h>
#import <ImageIO/ImageIO.h>
#import "JournyCamCore+Utility.h"
#import "JournyCamCore+Control.h"

#pragma mark - JournyCamCore (Control)

@implementation JournyCamCore (Control)

- (BOOL)deviceLockForConfig:(NSError **)error {
    return [self.captureDevice lockForConfiguration:error];
}

- (void)deviceUnlockForConfig {
    [self.captureDevice unlockForConfiguration];
}

- (void)setTorchMode:(AVCaptureTorchMode)mode {
    if (![self.captureDevice isTorchModeSupported:mode]) {
        return;
    }
    [self.captureDevice setTorchMode:mode];
}

- (AVCaptureTorchMode)torchMode {
    return self.captureDevice.torchMode;
}

- (BOOL)setTorchModeOnWithLevel:(CGFloat)level {
    level = MIN(level, AVCaptureMaxAvailableTorchLevel);
    return [self.captureDevice setTorchModeOnWithLevel:level error:nil];
}

- (void)setFlashMode:(AVCaptureFlashMode)mode {
    if (![self.captureDevice isFlashModeSupported:mode]) {
        return;
    }
    [self.captureDevice setFlashMode:mode];
}

- (AVCaptureFlashMode)flashMode {
    return self.captureDevice.flashMode;
}

- (void)setFocusMode:(AVCaptureFocusMode)mode {
    if (![self.captureDevice isFocusModeSupported:mode]) {
        return;
    }
    [self.captureDevice setFocusMode:mode];
}

- (AVCaptureFocusMode)focusMode {
    return self.captureDevice.focusMode;
}

- (void)setFocusPointOfInterest:(CGPoint)point {
    if (![self.captureDevice isFocusPointOfInterestSupported]) {
        return;
    }
    [self.captureDevice setFocusPointOfInterest:point];
}

- (CGPoint)focusPointOfInterest {
    return self.captureDevice.focusPointOfInterest;
}

- (void)setExposureMode:(AVCaptureExposureMode)mode {
    if (![self.captureDevice isExposureModeSupported:mode]) {
        return;
    }
    [self.captureDevice setExposureMode:mode];
}

- (AVCaptureExposureMode)exposureMode {
    return self.captureDevice.exposureMode;
}

- (void)setExposurePointOfInterest:(CGPoint)point {
    if (![self.captureDevice isExposurePointOfInterestSupported]) {
        return;
    }
    [self.captureDevice setExposurePointOfInterest:point];
}

- (CGPoint)exposurePointOfInterest {
    return self.captureDevice.exposurePointOfInterest;
}

- (void)setWhiteBalanceMode:(AVCaptureWhiteBalanceMode)mode {
    if (![self.captureDevice isWhiteBalanceModeSupported:mode]) {
        return;
    }
    [self.captureDevice setWhiteBalanceMode:mode];
}

- (AVCaptureWhiteBalanceMode)whiteBalanceMode {
    return self.captureDevice.whiteBalanceMode;
}

- (void)setVideoZoomFactor:(CGFloat)factor {
    [self.captureDevice setVideoZoomFactor:factor];
}

- (CGFloat)videoZoomFactor {
    return self.captureDevice.videoZoomFactor;
}

- (CGFloat)videoMaxZoomFactor {
    return self.captureDevice.activeFormat.videoMaxZoomFactor;
}

- (JCTimeRange)rangeOfVideoFrameDuration {
    JCTimeRange frameDuration;
    frameDuration.minValue = self.captureDevice.activeVideoMinFrameDuration;
    frameDuration.maxValue = self.captureDevice.activeVideoMaxFrameDuration;
    return frameDuration;
}
#pragma mark - IOS 8 only
- (JCFloatRange)rangeOfExposureTargetBias NS_AVAILABLE_IOS(8_0) {
    JCFloatRange exposureTargetBias;
    exposureTargetBias.minValue = self.captureDevice.minExposureTargetBias;
    exposureTargetBias.maxValue = self.captureDevice.maxExposureTargetBias;
    return exposureTargetBias;
}

- (JCTimeRange)rangeOfExposureDuration NS_AVAILABLE_IOS(8_0) {
    JCTimeRange exposureDuration;
    exposureDuration.minValue = self.captureDevice.activeFormat.minExposureDuration;
    exposureDuration.maxValue = self.captureDevice.activeFormat.maxExposureDuration;
    return exposureDuration;
}

- (JCFloatRange)rangeOfISO NS_AVAILABLE_IOS(8_0) {
    JCFloatRange iso;
    iso.minValue = self.captureDevice.activeFormat.minISO;
    iso.maxValue = self.captureDevice.activeFormat.maxISO;
    return iso;
}

- (void)setExposureModeCustomWithDuration:(CMTime)duration ISO:(float)ISO completionHandler:(void (^)(CMTime syncTime))handler NS_AVAILABLE_IOS(8_0) {
    if (![self.captureDevice isExposureModeSupported:AVCaptureExposureModeCustom]) {
        handler(kCMTimeInvalid);
        return;
    }
    [self.captureDevice setExposureModeCustomWithDuration:duration ISO:ISO completionHandler:handler];
}

- (void)setExposureTargetBias:(float)bias completionHandler:(void (^)(CMTime syncTime))handler NS_AVAILABLE_IOS(8_0) {
    [self.captureDevice setExposureTargetBias:bias completionHandler:handler];
}

- (void)setFocusModeLockedWithLensPosition:(float)lensPosition completionHandler:(void (^)(CMTime syncTime))handler NS_AVAILABLE_IOS(8_0) {
    if (![self.captureDevice isFocusModeSupported:AVCaptureFocusModeLocked]) {
        handler(kCMTimeInvalid);
        return;
    }
    [self.captureDevice setFocusModeLockedWithLensPosition:lensPosition completionHandler:handler];
}

- (void)setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:(AVCaptureWhiteBalanceGains)whiteBalanceGains completionHandler:(void (^)(CMTime syncTime))handler NS_AVAILABLE_IOS(8_0) {
    if (![self.captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked]) {
        handler(kCMTimeInvalid);
        return;
    }
    [self.captureDevice setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:whiteBalanceGains completionHandler:handler];
}

@end

#pragma mark - JournyCamCore (Shot)

@implementation JournyCamCore (Shot)

@dynamic burstShotMaxCount;
@dynamic burstShotTimeInterval;
@dynamic squareShot;
@dynamic volumeShot;

- (void)setBurstShotTimeInterval:(NSTimeInterval)burstShotTimeInterval {
    objc_setAssociatedObject(self, @"JournyCamCore_BurstShotTimeInterval", [NSNumber numberWithDouble:burstShotTimeInterval], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval)burstShotTimeInterval {
    NSNumber *timeInterval = objc_getAssociatedObject(self, @"JournyCamCore_BurstShotTimeInterval");
    if (nil == timeInterval) {
        return 0.f;
    }
    return [timeInterval doubleValue];
}

- (void)setBurstShotCount:(NSUInteger)burstShotCount {
    objc_setAssociatedObject(self, @"JournyCamCore_BurstShotCount", [NSNumber numberWithUnsignedInteger:burstShotCount], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSUInteger)burstShotCount {
    NSNumber *count = objc_getAssociatedObject(self, @"JournyCamCore_BurstShotCount");
    if (nil == count) {
        return 0;
    }
    return [count unsignedIntegerValue];
}

- (void)setBurstShotMaxCount:(NSUInteger)burstShotMaxCount {
    objc_setAssociatedObject(self, @"JournyCamCore_BurstShotMaxCount", [NSNumber numberWithUnsignedInteger:burstShotMaxCount], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSUInteger)burstShotMaxCount {
    NSNumber *maxCount = objc_getAssociatedObject(self, @"JournyCamCore_BurstShotMaxCount");
    if (nil == maxCount) {
        return 5;
    }
    return [maxCount unsignedIntegerValue];
}

- (void)setSquareShot:(BOOL)squareShot {
    objc_setAssociatedObject(self, @"JournyCamCore_SquareShot", [NSNumber numberWithBool:squareShot], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)squareShot {
    NSNumber *isSquareShot = objc_getAssociatedObject(self, @"JournyCamCore_SquareShot");
    if (nil == isSquareShot) {
        return NO;
    }
    return [isSquareShot boolValue];
}

- (BOOL)isSquareShot {
    return [self squareShot];
}

- (void)setVolumeShot:(BOOL)volumeShot {
    objc_setAssociatedObject(self, @"JournyCamCore_VolumeShot", [NSNumber numberWithBool:volumeShot], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    NSString *observerName = @"AVSystemController_SystemVolumeDidChangeNotification";
    if (volumeShot) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(volumeDidChange:)
                                                     name:observerName
                                                   object:nil];
    }
    else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:observerName object:nil];
    }
}

- (BOOL)volumeShot {
    NSNumber *isVolumeShot = objc_getAssociatedObject(self, @"JournyCamCore_VolumeShot");
    if (nil == isVolumeShot) {
        return NO;
    }
    return [isVolumeShot boolValue];
}

- (BOOL)isVolumeShot {
    return [self volumeShot];
}

- (void)volumeDidChange:(NSNotification *)notification {
    [self shotImageCompletionHandler:nil];
}

- (void)shotImageCompletionHandler:(void (^)(UIImage *, NSDictionary *, NSError *))completion
{
    AVCaptureConnection *connection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    [self.imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        UIImage *image = nil;
        CGImageRef imageRef = [self CGImageARGBFromImageBuffer:imageDataSampleBuffer];
        NSDictionary *metaData = [self metaDataFromSampleBuffer:imageDataSampleBuffer];
        if (NULL != imageRef) {
            id orientation = [metaData objectForKey:(NSString *)kCGImagePropertyOrientation];
            UIImageOrientation imageOrientation = [self UIImageOrientationFromCGImageOrientation:[orientation intValue]];
            image = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:imageOrientation];
            CGImageRelease(imageRef);
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(JournyCamCore:didShotImage:withMetaData:)]) {
            [self.delegate JournyCamCore:self didShotImage:image withMetaData:metaData];
        }
        if (nil != completion) {
            completion(image, metaData, error);
        }
    }];
}

- (void)delayShotImage:(NSTimeInterval)timeout counterHandler:(BOOL (^)(NSTimeInterval))counterHandler completionHandler:(void (^)(UIImage *, NSDictionary *, NSError *))completionHandler
{
    [self delayShotCheckSeconds:timeout sinceDate:[NSDate date] counterHandler:counterHandler completionHandler:^(BOOL isCancelled) {
        if (isCancelled) {
            NSError *error = [NSError errorWithDomain:AVFoundationErrorDomain code:AVErrorNoDataCaptured userInfo:nil];
            completionHandler(nil, nil, error);
            return;
        }
        [self shotImageCompletionHandler:completionHandler];
    }];
}

- (void)delayShotCheckSeconds:(NSTimeInterval)seconds sinceDate:(NSDate *)date counterHandler:(BOOL (^)(NSTimeInterval))counterHandler completionHandler:(void (^)(BOOL isCancelled))completionHandler
{
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:date];
    if (interval >= seconds) {
        completionHandler(NO);
        return;
    }
    if (!counterHandler(ceil(seconds - interval))) {
        //Cancel
        completionHandler(YES);
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self delayShotCheckSeconds:seconds sinceDate:date counterHandler:counterHandler completionHandler:completionHandler];
    });
}

- (void)burstShotImageCompletionHandler:(BOOL (^)(UIImage *, NSDictionary *, NSError *))completionHandler {
    [self shotImageCompletionHandler:^(UIImage *image, NSDictionary *metaData, NSError *error) {
        NSUInteger burstCount = self.burstShotCount + 1, burstMaxCount = self.burstShotMaxCount;
        BOOL reachMax = (0 != burstMaxCount) && (burstCount >= burstMaxCount);
        self.burstShotCount = burstCount;
        if (!completionHandler(image, metaData, error) || reachMax) {
            self.burstShotCount = 0;
            return;
        }
        NSTimeInterval timeInterval = self.burstShotTimeInterval;
        if (timeInterval < 0.3f) {
            timeInterval = 0.3f;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self burstShotImageCompletionHandler:completionHandler];
        });
    }];
}

@end
