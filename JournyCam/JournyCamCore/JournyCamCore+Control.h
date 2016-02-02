//
//  JournyCamCore+Control.h
//  JournyCam
//
//  Created by Sora Yang on 10/1/15.
//  Copyright © 2015 Sora Yang. All rights reserved.
//

#import "JournyCamCore.h"

#pragma mark - JournyCamCore (Control)

typedef struct {
    float minValue;
    float maxValue;
} JCFloatRange;

typedef struct {
    CMTime minValue;
    CMTime maxValue;
} JCTimeRange;

@interface JournyCamCore (Control)

/**
 Before setting property, you should call deviceLockForConfig.
 After setting property, you shuold call deviceUnlockForConfig.
 */
@property (nonatomic, assign) AVCaptureTorchMode torchMode;
@property (nonatomic, assign) AVCaptureFlashMode flashMode;
@property (nonatomic, assign) AVCaptureWhiteBalanceMode whiteBalanceMode;

@property (nonatomic, assign) AVCaptureFocusMode focusMode;
@property (nonatomic, assign) CGPoint focusPointOfInterest;

@property (nonatomic, assign) AVCaptureExposureMode exposureMode;
@property (nonatomic, assign) CGPoint exposurePointOfInterest;

@property (nonatomic, assign, readonly) CGFloat videoMaxZoomFactor;
@property (nonatomic, assign) CGFloat videoZoomFactor;

@property (nonatomic, assign, readonly) JCTimeRange rangeOfVideoFrameDuration;
@property (nonatomic, assign, readonly) JCFloatRange rangeOfExposureTargetBias NS_AVAILABLE_IOS(8_0);
@property (nonatomic, assign, readonly) JCTimeRange rangeOfExposureDuration NS_AVAILABLE_IOS(8_0);
@property (nonatomic, assign, readonly) JCFloatRange rangeOfISO NS_AVAILABLE_IOS(8_0);

- (BOOL)deviceLockForConfig:(NSError **)error;
- (void)deviceUnlockForConfig;

- (void)setExposureModeCustomWithDuration:(CMTime)duration ISO:(float)ISO completionHandler:(void (^)(CMTime syncTime))handler NS_AVAILABLE_IOS(8_0);
- (void)setExposureTargetBias:(float)bias completionHandler:(void (^)(CMTime syncTime))handler NS_AVAILABLE_IOS(8_0);
- (void)setFocusModeLockedWithLensPosition:(float)lensPosition completionHandler:(void (^)(CMTime syncTime))handler NS_AVAILABLE_IOS(8_0);
- (void)setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:(AVCaptureWhiteBalanceGains)whiteBalanceGains completionHandler:(void (^)(CMTime syncTime))handler NS_AVAILABLE_IOS(8_0);

@end

#pragma mark - JournyCamCore (Shot)

@interface JournyCamCore (Shot)

@property (nonatomic, assign, getter=isSquareShot) BOOL squareShot;

/**
 Config burst shot time interval. Unit by sencond
 */
@property (nonatomic, assign) NSTimeInterval burstShotTimeInterval;

/**
 Burst shot image count
 */
@property (nonatomic, assign, readonly) NSUInteger burstShotCount;

/**
 Config burst shot max image count.
 burstShotMaxCount: 0-No limit, default-5
 */
@property (nonatomic, assign) NSUInteger burstShotMaxCount;

/**
 Shot one image.
 */
- (void)shotImageCompletionHandler:(void(^)(UIImage *image, NSDictionary *metaData, NSError *error))completion;

/*
 Shot one image after specified time out.
 counterHandler: YES-Continue NO-Cancel
 */
- (void)delayShotImage:(NSTimeInterval)timeout counterHandler:(BOOL(^)(NSTimeInterval counter))counterHandler completionHandler:(void (^)(UIImage *image, NSDictionary *metaData, NSError *error))completionHandler;

/*
 Burst shoting images until completionHandler return NO or reach busrtShotMaxCount.
 completionHandler: YES-Continue NO-Abort
 */
- (void)burstShotImageCompletionHandler:(BOOL(^)(UIImage *image, NSDictionary *metaData, NSError *error))completionHandler;

@end
