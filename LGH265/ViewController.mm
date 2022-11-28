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
#include "log4cplus.h"

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

@interface ViewController ()<XDXFFmpegVideoDecoderDelegate> {
    AVFormatContext *m_formatContext;
    XDXFFmpegVideoDecoder *decoder;
}
@property (nonatomic, strong) AVSampleBufferDisplayLayer *displayLayer;
@property (strong, nonatomic) XDXPreviewView *previewView;
@property (nonatomic, strong) UIButton *startBtn;
@end

@implementation ViewController

FILE *fp_open;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)startBtnAction {
    [self startDecodeByFFmpegWithIsH265Data:YES];
}

- (void)startDecodeByFFmpegWithIsH265Data:(BOOL)isH265 {
    NSString *path = [[NSBundle mainBundle] pathForResource:isH265 ? @"testh265" : @"testh264" ofType:@"MOV"];
    path = [[NSBundle mainBundle] pathForResource:@"unset_test"  ofType:@"h265"];

    __weak typeof(self)weakSelf = self;
    XDXAVParseHandler *parseHandler = [[XDXAVParseHandler alloc] initWithPath:path];
    [parseHandler startParseGetAVPackeWithCompletionHandler:^(BOOL isVideoFrame, BOOL isFinish, AVPacket packet1) {
        [weakSelf handleData:packet1.data length:packet1.size];
    }];
}

- (void)handleData:(uint8_t *)data length:(int)length {
    uint8_t *buf = data;
    int len = length;
    
    if (!m_formatContext) {
        m_formatContext = avformat_alloc_context();

        // 输入数据
        [self inputBuffer:buf len:len];
        
        // 打开数据
        int ret = [self openInput];
        if (ret < 0) {
            [self freeFormatContext];
            return;
        }
        
        // 创建解码器
        decoder = [[XDXFFmpegVideoDecoder alloc] initWithFormatContext:m_formatContext
                                                      videoStreamIndex:[self getAVStreamIndexWithFormatContext:m_formatContext]];
        decoder.delegate = self;
    } else {
        [self inputBuffer:buf len:len];
    }
    
    // 封装成 AVPacket
    AVPacket packet;
    av_init_packet(&packet);
    int size = av_read_frame(m_formatContext, &packet);
    if (size < 0 || packet.size < 0) {
        [self freeFormatContext];
        [decoder stopDecoder];
        return;
    }
    [decoder startDecodeVideoDataWithAVPacket:packet];
    av_packet_unref(&packet);
}

- (void)inputBuffer:(uint8_t *)buf len:(int)len {
    unsigned char *avio_ctx_buffer = NULL;
    bd.ptr = buf;
    bd.size = len;
    avio_ctx_buffer = (unsigned char *)av_malloc(len);
    AVIOContext *avio_ctx = avio_alloc_context(avio_ctx_buffer, len, 0, NULL, read_packet, NULL, NULL);
    m_formatContext->pb = avio_ctx;
    m_formatContext->flags = AVFMT_FLAG_CUSTOM_IO;
}

- (int)openInput {
    AVInputFormat *in_fmt = av_find_input_format("h265");
    int ret = avformat_open_input(&m_formatContext, "", in_fmt, NULL);
    if (ret < 0) {
        fprintf(stderr, "avformat_open_input fail");
        return ret;
    }
    ret = avformat_find_stream_info(m_formatContext, NULL);
    if (ret < 0) {
        fprintf(stderr, "avformat_find_stream_info fail");
        return ret;
    }
    
    return ret;
}

- (void)freeFormatContext {
    avformat_close_input(&m_formatContext);
    m_formatContext = NULL;
}

- (int)getAVStreamIndexWithFormatContext:(AVFormatContext *)formatContext {
    int avStreamIndex = -1;
    for (int i = 0; i < formatContext->nb_streams; i++) {
        if (AVMEDIA_TYPE_VIDEO == formatContext->streams[i]->codecpar->codec_type) {
            avStreamIndex = i;
        }
    }
    
    if (avStreamIndex == -1) {
        NSLog(@"getAVStreamIndexWithFormatContext %s: Not find video stream", __func__);
        return NULL;
    } else {
        return avStreamIndex;
    }
}

struct buffer_data {
    uint8_t *ptr;
    int size;
};

struct buffer_data bd = {0};

int read_packet(void *opaque, uint8_t *buf, int buf_size) {
    buf_size = FFMIN(buf_size, bd.size);
    
    if (!buf_size)
        return AVERROR_EOF;
    printf("ptr = %p size = %d bz = %d\n", bd.ptr, bd.size, buf_size);
    
    /* copy internal buffer data to buf */
    memcpy(buf, bd.ptr, buf_size);
    bd.ptr += buf_size;
    bd.size -= buf_size;
    
    return buf_size;
}

#pragma mark - XDXFFmpegVideoDecoderDelegate
-(void)getDecodeVideoDataByFFmpeg:(CMSampleBufferRef)sampleBuffer {
    CVPixelBufferRef pix = CMSampleBufferGetImageBuffer(sampleBuffer);
    [self.previewView displayPixelBuffer:pix];
//        [self.displayLayer enqueueSampleBuffer:sampleBuffer];
}

- (void)setupUI {
    self.previewView = [[XDXPreviewView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:self.previewView];
    [self.view addSubview:self.startBtn];
    [self.view.layer addSublayer:self.displayLayer];
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
