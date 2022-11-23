//
//  ViewController.m
//  LGH265
//
//  Created by welink on 2022/11/23.
//

#import "ViewController.h"

#import "XDXAVParseHandler.h"
#import "XDXFFmpegVideoDecoder.h"
#import "XDXPreviewView.h"

// FFmpeg Header File
#ifdef __cplusplus
extern "C" {
#endif
    
#include "libavformat/avformat.h"
#include "libavcodec/avcodec.h"
#include "libavutil/avutil.h"
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"
#include "libavutil/opt.h"
    
#ifdef __cplusplus
};
#endif

@interface ViewController ()<XDXFFmpegVideoDecoderDelegate>
@property (nonatomic, strong) AVSampleBufferDisplayLayer *displayLayer;
@property (strong, nonatomic) XDXPreviewView *previewView;
@property (nonatomic, strong) UIButton *startBtn;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)startBtnAction {
    [self startDecodeByFFmpegWithIsH265Data:YES];
}

- (void)startDecodeByFFmpegWithIsH265Data:(BOOL)isH265 {
    NSString *path = [[NSBundle mainBundle] pathForResource:isH265 ? @"testh265" : @"testh264" ofType:@"MOV"];
    path = [[NSBundle mainBundle] pathForResource:@"test"  ofType:@"h265"];
    XDXAVParseHandler *parseHandler = [[XDXAVParseHandler alloc] initWithPath:path];
    XDXFFmpegVideoDecoder *decoder = [[XDXFFmpegVideoDecoder alloc] initWithFormatContext:[parseHandler getFormatContext] videoStreamIndex:[parseHandler getVideoStreamIndex]];
    decoder.delegate = self;
    [parseHandler startParseGetAVPackeWithCompletionHandler:^(BOOL isVideoFrame, BOOL isFinish, AVPacket packet) {
        if (isFinish) {
            [decoder stopDecoder];
            return;
        }
        
        if (isVideoFrame) {
            [decoder startDecodeVideoDataWithAVPacket:packet];
        }
    }];
}

#pragma mark - XDXFFmpegVideoDecoderDelegate
-(void)getDecodeVideoDataByFFmpeg:(CMSampleBufferRef)sampleBuffer {
    CVPixelBufferRef pix = CMSampleBufferGetImageBuffer(sampleBuffer);
    [self.previewView displayPixelBuffer:pix];
//    [self.displayLayer enqueueSampleBuffer:sampleBuffer];
}

- (void)setupUI {
    self.previewView = [[XDXPreviewView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:self.previewView];
    [self.view addSubview:self.startBtn];
//    [self.view.layer addSublayer:self.displayLayer];
}

#pragma mark - lazy
- (UIButton *)startBtn {
    if (!_startBtn) {
        _startBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 40, 40)];
        [_startBtn setTitle:@"开始" forState:UIControlStateNormal];
        _startBtn.backgroundColor = UIColor.redColor;
        [_startBtn addTarget:self action:@selector(startBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _startBtn;
}

- (AVSampleBufferDisplayLayer *)displayLayer {
    if (!_displayLayer) {
        _displayLayer = [[AVSampleBufferDisplayLayer alloc] init];
        _displayLayer.frame = self.view.bounds;
    }
    
    return _displayLayer;
}
@end
