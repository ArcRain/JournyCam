//
//  JournyCamCore.m
//  JournyCam
//
//  Created by Sora Yang on 9/19/15.
//  Copyright © 2015 Sora Yang. All rights reserved.
//

#import <ImageIO/CGImageProperties.h>
#import <AVFoundation/AVFoundation.h>
#import "JournyCamCore+Control.h"
#import <objc/runtime.h>

@interface JournyCamCore () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, assign, readonly) NSUInteger kCVPixelFormatType;
@property (nonatomic, assign, readonly) AVCaptureVideoOrientation videoOrientation;
@property (nonatomic, strong) dispatch_queue_t processQueue;

@end

@implementation JournyCamCore

+ (BOOL)isCaptureDeviceAvailable:(AVCaptureDevicePosition)devicePosition {
    NSArray *devices = [AVCaptureDevice devices];
    BOOL isAvailable = NO;
    for (AVCaptureDevice *device in devices) {
        if (device.position == devicePosition) {
            isAvailable = YES;
            break;
        }
    }
    return isAvailable;
}

+ (void)requestAccessForMediaType:(NSString *)mediaType completionHandler:(void (^)(BOOL))handler {
    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(granted);
        });
    }];
}

- (void)dealloc {
    [self tearDown];
    objc_removeAssociatedObjects(self);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _devicePosition = AVCaptureDevicePositionBack;
        _sessionPreset = AVCaptureSessionPresetPhoto;
        _kCVPixelFormatType = kCVPixelFormatType_32BGRA;
        _videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        _processQueue = dispatch_queue_create("com.arcrain.journycamcore.process.queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)defaultSet {
    AVCaptureConnection *connection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    if (AVCaptureDevicePositionFront == self.devicePosition) {
        connection.automaticallyAdjustsVideoMirroring = NO;
        connection.videoMirrored = YES;
    }
    else {
        connection.automaticallyAdjustsVideoMirroring = YES;
    }
    connection.videoOrientation = self.videoOrientation;
}

- (BOOL)readyForStart {
    return [self buildGraph:self.devicePosition withPreset:self.sessionPreset];
}

- (void)tearDown {
    [self destroyGraph];
}

- (void)start:(void (^)(void))completion {
    dispatch_async(self.processQueue, ^{
        [self.captureSession startRunning];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (nil != completion) {
                completion();
            }
        });
    });
}

- (void)stop:(void (^)(void))completion {
    dispatch_async(self.processQueue, ^{
        [self.captureSession stopRunning];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (nil != completion) {
                completion();
            }
        });
    });
}

- (BOOL)switchCamera {
    AVCaptureDevicePosition devicePosition = AVCaptureDevicePositionUnspecified;
    if (AVCaptureDevicePositionBack == self.devicePosition) {
        devicePosition = AVCaptureDevicePositionFront;
    }
    else {
        devicePosition = AVCaptureDevicePositionBack;
    }
    return [self switchCameraToPosition:devicePosition];
}

- (BOOL)switchCameraToPosition:(AVCaptureDevicePosition)devicePosition {
    if (devicePosition == self.devicePosition) {
        return YES;
    }
    BOOL isSwitched = NO;
    AVCaptureDeviceInput *deviceInput = [self deviceInputWithType:AVMediaTypeVideo position:devicePosition];
    if (nil != deviceInput) {
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:self.deviceInput];
        if ([self.captureSession canAddInput:deviceInput]) {
            [self.captureSession addInput:deviceInput];
            _deviceInput = deviceInput;
            _devicePosition = devicePosition;
            isSwitched = YES;
        }
        else {
            [self.captureSession addInput:self.deviceInput];
        }
        [self.captureSession commitConfiguration];
    }
    return isSwitched;
}

- (void)setSessionPreset:(NSString *)sessionPreset {
    if (nil == self.captureSession) {
         _sessionPreset = sessionPreset;
    }
    else {
        [self.captureSession beginConfiguration];
        if ([self.captureSession canSetSessionPreset:sessionPreset]) {
            [self.captureSession setSessionPreset:sessionPreset];
            _sessionPreset = sessionPreset;
        }
        [self.captureSession commitConfiguration];
    }
}

#pragma mark - Internal Method
- (BOOL)buildGraph:(AVCaptureDevicePosition)position withPreset:(NSString *)sessionPreset {
    BOOL isBuilt = YES;
    //0.check current
    if (nil != self.captureSession) {
        return isBuilt;
    }
    
    //1.create session
    _captureSession = [AVCaptureSession new];
    isBuilt = (nil != self.captureSession);
    if (isBuilt) {
        [self.captureSession beginConfiguration];
        do {
            //2.add input
            isBuilt &= [self addDeviceInput:position];
            if (!isBuilt) {
                break;
            }
            //3.add videoOutput
            isBuilt &= [self addVideoOutput];
            if (!isBuilt) {
                break;
            }
            //4.add imageOutput
            isBuilt &= [self addImageOutput];
            if (!isBuilt) {
                break;
            }
        } while (false);
        [self.captureSession commitConfiguration];
    }
    if (isBuilt) {
        [self setSessionPreset:sessionPreset];
        [self defaultSet];
        
        _devicePosition = position;
        _sessionPreset = sessionPreset;
    }
    else {
        [self tearDown];
    }
    return isBuilt;
}

- (void)destroyGraph {
    [self.captureSession stopRunning];
    [self.captureSession removeInput:self.deviceInput];
    [self.captureSession removeOutput:self.videoOutput];
    [self.captureSession removeOutput:self.imageOutput];
    _deviceInput = nil;
    _videoOutput = nil;
    _imageOutput = nil;
    _captureSession = nil;
}

- (AVCaptureDeviceInput *)deviceInputWithType:(NSString *)deviceType position:(AVCaptureDevicePosition)position {
    AVCaptureDeviceInput *deviceInput = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:deviceType];
    for (AVCaptureDevice* device in devices) {
        if (device.position == position) {
            deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
            break;
        }
    }
    return deviceInput;
}

- (AVCaptureDevice *)captureDevice {
    return self.deviceInput.device;
}

- (BOOL)addDeviceInput:(AVCaptureDevicePosition)position {
    AVCaptureDeviceInput *input = [self deviceInputWithType:AVMediaTypeVideo position:position];
    if (nil == input) {
        return NO;
    }
    if (![self.captureSession canAddInput:input]) {
        return NO;
    }
    [self.captureSession addInput:input];
    _deviceInput = input;
    return YES;
}

- (BOOL)addVideoOutput {
    AVCaptureVideoDataOutput *videoOutput = [AVCaptureVideoDataOutput new];
    if (![self.captureSession canAddOutput:videoOutput]) {
        return NO;
    }
    [self.captureSession addOutput:videoOutput];
    _videoOutput = videoOutput;
    
    [self.videoOutput setSampleBufferDelegate:self queue:self.processQueue];
    self.videoOutput.alwaysDiscardsLateVideoFrames = YES;
    self.videoOutput.videoSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey : @(self.kCVPixelFormatType)};
    
    return YES;
}

- (BOOL)addImageOutput {
    AVCaptureStillImageOutput *imageOutput = [AVCaptureStillImageOutput new];
    if (![self.captureSession canAddOutput:imageOutput]) {
        return NO;
    }
    [self.captureSession addOutput:imageOutput];
    _imageOutput = imageOutput;
    
    self.imageOutput.outputSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey : @(self.kCVPixelFormatType)};
    
    return YES;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (self.delegate && [self.delegate respondsToSelector:@selector(JournyCamCore:didOutputSampleBuffer:)]) {
        [self.delegate JournyCamCore:self didOutputSampleBuffer:sampleBuffer];
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (self.delegate && [self.delegate respondsToSelector:@selector(JournyCamCore:didDropSampleBuffer:)]) {
        [self.delegate JournyCamCore:self didDropSampleBuffer:sampleBuffer];
    }
}

@end
