//
//  JournyCamViewController.m
//  JournyCam
//
//  Created by Sora Yang on 9/19/15.
//  Copyright © 2015 Sora Yang. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "JournyCamCore+Control.h"
#import "JournyCamViewController.h"

@interface JournyCamViewController () <JournyCamCoreDelegate>
{
    BOOL _continueCapture;
    BOOL _isCapturing;
}

@property (nonatomic, strong) UISlider *zoomSlider;
@property (nonatomic, strong) JournyCamCore *camCore;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) UIImageView *capturedImageView;

@end

@implementation JournyCamViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    [self setTestButton];
}

- (void)setTestButton
{
    CGSize viewSize = self.view.bounds.size;
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(10, 10, 54, 48);
        button.backgroundColor = [UIColor redColor];
        [button setTitle:@"Single" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(didClickCaptureStillImage:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    }
    
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(10, 60, 120, 48);
        button.backgroundColor = [UIColor redColor];
        [button setTitle:@"Delay 10 capture" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(didClickDelayCaptureStillImage:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    }
    
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(viewSize.width - 128, 10, 54, 48);
        button.backgroundColor = [UIColor redColor];
        [button setTitle:@"Switch" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(didClickSwitch:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    }
    
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(10, 160, 54, 48);
        button.backgroundColor = [UIColor redColor];
        [button setTitle:@"Burst" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(didBeginBurstShot:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self action:@selector(didEndBurstShot:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
        [self.view addSubview:button];
    }
    
    {
        UIImageView *imageView = [UIImageView new];
        imageView.backgroundColor = [UIColor darkGrayColor];
        imageView.frame = CGRectMake(viewSize.width - 168, viewSize.height - 210, 160, 160);
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.autoresizesSubviews = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        [self.view addSubview:imageView];
        _capturedImageView = imageView;
    }
    
    {
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(10, viewSize.height - 44, 200, 36)];
        slider.minimumValue = 0;
        slider.maximumValue = 1.0;
        [slider addTarget:self action:@selector(didChangeZoomFactor:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:slider];
        _zoomSlider = slider;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setNavigationBarHidden:YES animated:animated];
    
    [self setupPreviewLayer:^(BOOL isSuccess) {
        [self.camCore start:^{
            self.zoomSlider.minimumValue = 1.0;
            self.zoomSlider.maximumValue = MIN(4.0, self.camCore.videoMaxZoomFactor);
        }];
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self setNavigationBarHidden:NO animated:animated];
    [self.camCore stop:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.previewLayer.frame = self.view.bounds;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (UIInterfaceOrientationPortrait != toInterfaceOrientation);
}

//New autorotate
- (BOOL)shouldAutorotate
{
    return !(UIInterfaceOrientationIsPortrait(self.interfaceOrientation));
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupPreviewLayer:(void (^)(BOOL isSuccess))handler
{
    if ([JournyCamCore isCaptureDeviceAvailable:AVCaptureDevicePositionBack]) {
        [JournyCamCore requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            BOOL isSuccess = granted;
            if (isSuccess && (nil == self.camCore)) {
                _camCore = [JournyCamCore new];
                /** Config JournyCamCore Properties before ready for start **/
                self.camCore.delegate = self;
                self.camCore.volumeShot = YES;
                self.camCore.burstShotMaxCount = 5;
                self.camCore.burstShotTimeInterval = 0.5f;
                isSuccess = [self.camCore readyForStart];
                if (isSuccess) {
                    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.camCore.captureSession];
                    previewLayer.frame = self.view.bounds;
                    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                    [self.view.layer insertSublayer:previewLayer atIndex:0];
                    _previewLayer = previewLayer;

                }
            }
            else if (!isSuccess) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Can't access camera" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
                [alertView show];
            }
            handler(isSuccess);
        }];
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"There is no available camera device" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
        [alertView show];
        handler(NO);
    }
}

- (void)didChangeZoomFactor:(UISlider *)slider {
    if ([self.camCore deviceLockForConfig:nil]) {
        self.camCore.videoZoomFactor = slider.value;
        [self.camCore deviceUnlockForConfig];
    }
}

- (void)didClickCaptureStillImage:(UIButton *)button
{
    [self.camCore shotImageCompletionHandler:^(UIImage *image, NSDictionary *metaData, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.capturedImageView.image = image;
        });
    }];
}

- (void)didClickDelayCaptureStillImage:(UIButton *)button
{
    if (button.isSelected) {
        _continueCapture = NO;
        button.selected = NO;
        [button setTitle:@"Delay 10 capture" forState:UIControlStateNormal];
        return;
    }
    button.selected = YES;
    _continueCapture = YES;
    [self.camCore delayShotImage:10 counterHandler:^BOOL(NSTimeInterval counter) {
        [button setTitle:[NSString stringWithFormat:@"%ld", (long)counter] forState:UIControlStateSelected];
        return _continueCapture;
    } completionHandler:^(UIImage *image, NSDictionary *metaData, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.capturedImageView.image = image;
            _continueCapture = NO;
            button.selected = NO;
            [button setTitle:@"Delay 10 capture" forState:UIControlStateNormal];
        });
    }];
}

- (void)didBeginBurstShot:(UIButton *)button
{
    _continueCapture = YES;
    [self.camCore burstShotImageCompletionHandler:^BOOL(UIImage *image, NSDictionary *metaData, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.capturedImageView.image = image;
        });
        return _continueCapture;
    }];
}

- (void)didEndBurstShot:(UIButton *)button
{
    _continueCapture = NO;
}

- (void)didClickSwitch:(UIButton *)button
{
    [self.camCore switchCamera];
}

#pragma mark - JournyCamCoreDelegate
- (void)JournyCamCore:(JournyCamCore *)camCore didShotImage:(UIImage *)image withMetaData:(NSDictionary *)metaData {
    if (!camCore.volumeShot) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.capturedImageView.image = image;
    });
}

@end
