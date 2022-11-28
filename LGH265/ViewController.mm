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
    int m_videoStreamIndex;
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
    path = [[NSBundle mainBundle] pathForResource:@"test"  ofType:@"h265"];
    //    XDXAVParseHandler *parseHandler = [[XDXAVParseHandler alloc] initWithPath:path];
    //    XDXFFmpegVideoDecoder *decoder = [[XDXFFmpegVideoDecoder alloc] initWithFormatContext:[parseHandler getFormatContext] videoStreamIndex:[parseHandler getVideoStreamIndex]];
    //    decoder.delegate = self;
    //    [parseHandler startParseGetAVPackeWithCompletionHandler:^(BOOL isVideoFrame, BOOL isFinish, AVPacket packet) {
    //
    ////        AVProbeData probe_data;
    ////        probe_data.buf_size = packet.size;
    ////        probe_data.filename = "";
    ////        probe_data.buf = packet.data;
    ////        AVInputFormat *pAVInputFormat = av_probe_input_format(&probe_data, 1);
    //
    ////        open_input_buffer(packet.data, packet.size);
    //
    //        if (isFinish) {
    //            [decoder stopDecoder];
    //            return;
    //        }
    //
    //        if (isVideoFrame) {
    //            [decoder startDecodeVideoDataWithAVPacket:packet];
    //        }
    //    }];
    
    path = [[NSBundle mainBundle] pathForResource:@"test"  ofType:@"h265"];
    
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    
    //    fp_open = fopen("test1.h264","rb+");
    //    AVFormatContext *ic = NULL;
    //    ic = avformat_alloc_context();
    //    int bufferSize = 32768;
    //    unsigned char * iobuffer = (unsigned char *)av_malloc(bufferSize);
    //    AVIOContext *avio = avio_alloc_context(iobuffer, bufferSize, 0, NULL, fill_iobuffer, NULL, NULL);
    //    ic->pb = avio;
    //    int ret = avformat_open_input(&ic, "nothing", NULL, NULL);
    //    XDXFFmpegVideoDecoder *decoder = [[XDXFFmpegVideoDecoder alloc] initWithFormatContext:ic videoStreamIndex:0];
    //    decoder.delegate = self;
    //
    //    AVPacket packet;
    //    av_init_packet(&packet);
    //    int size = av_read_frame(ic, &packet);
    //    if (size < 0 || packet.size < 0) {
    //
    //        int a = 3;
    //    }
    
    
    
    //    open_input_buffer((uint8_t *)[data bytes], data.length);
    
    //    unsigned char *avio_ctx_buffer = NULL;
    //    size_t avio_ctx_buffer_size = len;
    //
    //    AVInputFormat* in_fmt = av_find_input_format("h265");
    //
    //    bd.ptr = buf;  /* will be grown as needed by the realloc above */
    //    bd.size = len; /* no data at this point */
    //
    //    AVFormatContext *fmt_ctx = avformat_alloc_context();
    //
    //    avio_ctx_buffer = (unsigned char *)av_malloc(avio_ctx_buffer_size);
    //
    //    /* 读内存数据 */
    //    AVIOContext *avio_ctx = avio_alloc_context(avio_ctx_buffer, avio_ctx_buffer_size, 0, NULL, read_packet, NULL, NULL);
    //
    //    fmt_ctx->pb = avio_ctx;
    //    fmt_ctx->flags = AVFMT_FLAG_CUSTOM_IO;
    //
    //    /* 打开内存缓存文件, and allocate format context */
    //    if (avformat_open_input(&fmt_ctx, "", in_fmt, NULL) < 0) {
    //        fprintf(stderr, "Could not open input\n");
    //        return ;
    //    }
    
    
    __weak typeof(self)weakSelf = self;
    XDXAVParseHandler *parseHandler = [[XDXAVParseHandler alloc] initWithPath:path];
    [parseHandler startParseGetAVPackeWithCompletionHandler:^(BOOL isVideoFrame, BOOL isFinish, AVPacket packet1) {
        //
        [weakSelf handleData:packet1.data length:packet1.size];
    }];
}

- (void)handleData:(uint8_t *)data length:(int)length {
    uint8_t *buf = data;
    int len = length;
    
    static int a = 0;
    // AVFormatContext 格式
    if (!m_formatContext) {
        m_formatContext = avformat_alloc_context();
        
        unsigned char *avio_ctx_buffer = NULL;
        AVInputFormat *in_fmt = av_find_input_format("h265");
        
        bd.ptr = buf;  /* will be grown as needed by the realloc above */
        bd.size = len; /* no data at this point */
        
        avio_ctx_buffer = (unsigned char *)av_malloc(len);
        
        /* 读内存数据 */
        AVIOContext *avio_ctx = avio_alloc_context(avio_ctx_buffer, len, 0, NULL, read_packet, NULL, NULL);
        m_formatContext->pb = avio_ctx;
        m_formatContext->flags = AVFMT_FLAG_CUSTOM_IO;
        
        /* 打开内存缓存文件, and allocate format context */
        int ret = avformat_open_input(&m_formatContext, "", in_fmt, NULL);
        if (ret < 0) {
            fprintf(stderr, "avformat_open_input fail");
            return;
        }
        ret = avformat_find_stream_info(m_formatContext, NULL);
        if (ret < 0) {
            fprintf(stderr, "avformat_find_stream_info fail");
            return;
        }
    } else {
        bd.ptr = buf;  /* will be grown as needed by the realloc above */
        bd.size = len; /* no data at this point */
    }
    
    
    // 封装成 AVPacket
    AVPacket packet;
    av_init_packet(&packet);
    int size = av_read_frame(m_formatContext, &packet);
    if (size < 0 || packet.size < 0) {
        return;
    }
    if (!decoder) {
        m_videoStreamIndex = [self getAVStreamIndexWithFormatContext:m_formatContext isVideoStream:YES];
        decoder = [[XDXFFmpegVideoDecoder alloc] initWithFormatContext:m_formatContext videoStreamIndex:m_videoStreamIndex];
        decoder.delegate = self;
    }
    [decoder startDecodeVideoDataWithAVPacket:packet];
    av_packet_unref(&packet);
    //    avformat_close_input(&fmt_ctx);
}

- (int)getAVStreamIndexWithFormatContext:(AVFormatContext *)formatContext isVideoStream:(BOOL)isVideoStream {
    int avStreamIndex = -1;
    for (int i = 0; i < formatContext->nb_streams; i++) {
        if ((isVideoStream ? AVMEDIA_TYPE_VIDEO : AVMEDIA_TYPE_AUDIO) == formatContext->streams[i]->codecpar->codec_type) {
            avStreamIndex = i;
        }
    }
    
    if (avStreamIndex == -1) {
        log4cplus_error("getAVStreamIndexWithFormatContext", "%s: Not find video stream",__func__);
        return NULL;
    }else {
        return avStreamIndex;
    }
}


int fill_iobuffer(void * opaque,uint8_t *buf, int bufsize) {
    if(!feof(fp_open)){
        int true_size=fread(buf,1,bufsize,fp_open);
        return true_size;
    }else{
        return -1;
    }
}

/*正确方式*/
struct buffer_data
{
    uint8_t *ptr; /* 文件中对应位置指针 */
    int size;  ///< size left in the buffer /* 文件当前指针到末尾 */
};

// 重点，自定的buffer数据要在外面这里定义
struct buffer_data bd = {0};

//用来将内存buffer的数据拷贝到buf
int read_packet(void *opaque, uint8_t *buf, int buf_size)
{
    
    buf_size = FFMIN(buf_size, bd.size);
    
    if (!buf_size)
        return AVERROR_EOF;
    printf("ptr:%p size: = %d bz = %d\n", bd.ptr, bd.size, buf_size);
    
    /* copy internal buffer data to buf */
    memcpy(buf, bd.ptr, buf_size);
    bd.ptr += buf_size;
    bd.size -= buf_size;
    
    return buf_size;
}

/* 打开前端传来的视频buffer */
int open_input_buffer(AVFormatContext **fmt_ctx, uint8_t *buf, int len)
{
    unsigned char *avio_ctx_buffer = NULL;
    size_t avio_ctx_buffer_size = len;
    
    AVInputFormat* in_fmt = av_find_input_format("h265");
    
    bd.ptr = buf;  /* will be grown as needed by the realloc above */
    bd.size = len; /* no data at this point */
    
    AVFormatContext *fmt_ctx1 = *fmt_ctx;
    
    avio_ctx_buffer = (unsigned char *)av_malloc(avio_ctx_buffer_size);
    
    /* 读内存数据 */
    AVIOContext *avio_ctx = avio_alloc_context(avio_ctx_buffer, avio_ctx_buffer_size, 0, NULL, read_packet, NULL, NULL);
    
    fmt_ctx1->pb = avio_ctx;
    fmt_ctx1->flags = AVFMT_FLAG_CUSTOM_IO;
    
    /* 打开内存缓存文件, and allocate format context */
    if (avformat_open_input(&fmt_ctx1, "", in_fmt, NULL) < 0)
    {
        fprintf(stderr, "Could not open input\n");
        return -1;
    }
    
    return 0;
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
