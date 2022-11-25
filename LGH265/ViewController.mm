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
        
//        AVProbeData probe_data;
//        probe_data.buf_size = packet.size;
//        probe_data.filename = "";
//        probe_data.buf = packet.data;
//        AVInputFormat *pAVInputFormat = av_probe_input_format(&probe_data, 1);

//        open_input_buffer(packet.data, packet.size);
        
        if (isFinish) {
            [decoder stopDecoder];
            return;
        }
        
        if (isVideoFrame) {
            [decoder startDecodeVideoDataWithAVPacket:packet];
        }
    }];
}

/*正确方式*/
struct buffer_data
{
    uint8_t *ptr; /* 文件中对应位置指针 */
    size_t size;  ///< size left in the buffer /* 文件当前指针到末尾 */
};

// 重点，自定的buffer数据要在外面这里定义
struct buffer_data bd = {0};

//用来将内存buffer的数据拷贝到buf
int read_packet(void *opaque, uint8_t *buf, int buf_size)
{

    buf_size = FFMIN(buf_size, bd.size);

    if (!buf_size)
        return AVERROR_EOF;
    printf("ptr:%p size:%zu bz%zu\n", bd.ptr, bd.size, buf_size);

    /* copy internal buffer data to buf */
    memcpy(buf, bd.ptr, buf_size);
    bd.ptr += buf_size;
    bd.size -= buf_size;

    return buf_size;
}

/* 打开前端传来的视频buffer */
int open_input_buffer(uint8_t *buf, int len)
{
    unsigned char *avio_ctx_buffer = NULL;
    size_t avio_ctx_buffer_size = len;

    AVInputFormat* in_fmt = av_find_input_format("h265");

    bd.ptr = buf;  /* will be grown as needed by the realloc above */
    bd.size = len; /* no data at this point */

    AVFormatContext *fmt_ctx = avformat_alloc_context();

    avio_ctx_buffer = (unsigned char *)av_malloc(avio_ctx_buffer_size);

    /* 读内存数据 */
    AVIOContext *avio_ctx = avio_alloc_context(avio_ctx_buffer, avio_ctx_buffer_size, 0, NULL, read_packet, NULL, NULL);

    fmt_ctx->pb = avio_ctx;
    fmt_ctx->flags = AVFMT_FLAG_CUSTOM_IO;

    /* 打开内存缓存文件, and allocate format context */
    if (avformat_open_input(&fmt_ctx, "", in_fmt, NULL) < 0)
    {
        fprintf(stderr, "Could not open input\n");
        return -1;
    }
    return 0;
}

#pragma mark - XDXFFmpegVideoDecoderDelegate
-(void)getDecodeVideoDataByFFmpeg:(CMSampleBufferRef)sampleBuffer {
    CVPixelBufferRef pix = CMSampleBufferGetImageBuffer(sampleBuffer);
//    [self.previewView displayPixelBuffer:pix];
    [self.displayLayer enqueueSampleBuffer:sampleBuffer];
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
