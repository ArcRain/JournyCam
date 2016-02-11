//
//  JournyCamCore.h
//  JournyCam
//
//  Created by Sora Yang on 9/19/15.
//  Copyright © 2015 Sora Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol JournyCamCoreDelegate;
@interface JournyCamCore : NSObject

@property (nonatomic, copy) NSString *sessionPreset;
@property (nonatomic, assign) AVCaptureDevicePosition devicePosition;
@property (nonatomic, weak) id<JournyCamCoreDelegate> delegate;

//Internal Property
@property (nonatomic, strong, readonly) AVCaptureSession *captureSession;
@property (nonatomic, strong, readonly) AVCaptureDevice *captureDevice;
@property (nonatomic, strong, readonly) AVCaptureDeviceInput *deviceInput;
@property (nonatomic, strong, readonly) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong, readonly) AVCaptureStillImageOutput *imageOutput;

+ (BOOL)isCaptureDeviceAvailable:(AVCaptureDevicePosition)devicePosition;
+ (void)requestAccessForMediaType:(NSString *)mediaType completionHandler:(void(^)(BOOL granted))handler;

- (BOOL)readyForStart;
- (void)tearDown;

- (void)start:(void(^)(void))completion;
- (void)stop:(void(^)(void))completion;

- (BOOL)switchCamera;
- (BOOL)switchCameraToPosition:(AVCaptureDevicePosition)devicePosition;

@end

@protocol JournyCamCoreDelegate <NSObject>

@optional

- (void)JournyCamCore:(JournyCamCore *)camCore didShotImage:(UIImage *)image withMetaData:(NSDictionary *)metaData;
- (void)JournyCamCore:(JournyCamCore *)camCore didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)JournyCamCore:(JournyCamCore *)camCore didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end
