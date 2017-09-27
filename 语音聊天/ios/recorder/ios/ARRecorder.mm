//
//  ARRecorder.m
//  AudioRecorder
//
//  Created by A. Emre Ünal on 07/07/14.
//  Copyright (c) 2014 A. Emre Ünal. All rights reserved.
//

#import "ARRecorder.h"
#import "FileNameHelper.h"


@interface ARRecorder ()

@property(nonatomic, strong) AVAudioRecorder *recorder;
@property(nonatomic, strong) AVAudioPlayer *player;
@property(strong, nonatomic) NSString *recordingPath;
@property(nonatomic) int userCallback;

@end

#include "cocos2d.h"
#include "CCLuaEngine.h"
#include "CCLuaBridge.h"

#include "../liblame/lame.h" //to mp3

#include "../AmrPcmConvert/amrwapper/amrFileCodec.h" //pcm & amr converter

using namespace cocos2d;



@implementation ARRecorder

static ARRecorder* s_instance = nil;

+ (ARRecorder*) getInstance
{
    if (!s_instance)
    {
        s_instance = [ARRecorder alloc];
        [s_instance init];
    }
    
    return s_instance;
}

+ (void) destroyInstance
{
    [s_instance release];
}


+ (void) startRecord:(NSDictionary *)dict
{
    
    [[ARRecorder getInstance] setScriptHandler:[[dict objectForKey:@"scriptHandler"] intValue]];
    
    //录制时必须带扩展名.wav, 否则录制出来的就变成caf编码 ，而不是wav编码了, 导致转换amr失败！！！！！！！！
    //self.recordingPath = [FileNameHelper getPathByFileName:_filename ofType:@"wav"];
    [ARRecorder getInstance].recordingPath = [[dict objectForKey:@"pathname"] stringByDeletingPathExtension];
    
    NSLog(@"====recordingPath=%@\n",[ARRecorder getInstance].recordingPath);
    
    
    if (![[ARRecorder getInstance] onStartRecording])
    {
        [[ARRecorder getInstance] onRecordResult:false];
    }
}

+ (void) stopRecord:(NSDictionary *)dict
{
    [[ARRecorder getInstance] onStopRecording];
    
    
    [[ARRecorder getInstance] setScriptHandler:[[dict objectForKey:@"scriptHandler"] intValue]];
    
    //转换编码
    //BOOL ret = [[ARRecorder getInstance] pcmToMp3];
    
    BOOL ret = [[ARRecorder getInstance] pcmToAmr];
    [[ARRecorder getInstance] onRecordResult:ret];
}

+ (void) cancelRecord
{
    [[ARRecorder getInstance] onCancelRecording];
}

+ (void) playSound:(NSDictionary *)dict
{
    [[ARRecorder getInstance] setScriptHandler:[[dict objectForKey:@"scriptHandler"] intValue]];
    
    NSString *path_wav;
    NSString *path =[dict objectForKey:@"pathname"];

    if([[path pathExtension] hasSuffix:@"amr"]) //将 amr 转换成 wav 播放
    {
        path_wav = [[path stringByDeletingPathExtension] stringByAppendingString: @".wav"];
        
        if (![[ARRecorder getInstance] amrToPcm:path wavSavePath:path_wav])
        {
            [[ARRecorder getInstance] onPlayResult:false];
            return;
        }
    }
    else
    {
        path_wav = path;
    }

    
    if (![[ARRecorder getInstance] onStartPlaying:path_wav])
    {
        [[ARRecorder getInstance] onPlayResult:false];
    }
}

+ (void)stopPlayingSound
{
    [[ARRecorder getInstance] onStopPlaying];
}


- (BOOL)onStartRecording
{
    NSLog(@"onStartRecording \n");
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (session == nil)
    {
        return false;
    }
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    
    [self stopPlayingAndRecording];
    
    NSString *path_wav = [self.recordingPath stringByAppendingString: @".wav"];//录制时必须带扩展名.wav
    NSURL *url = [NSURL fileURLWithPath:path_wav];
    

    self.recorder = [[[AVAudioRecorder alloc] initWithURL:url settings:[self getRecorderSettings] error:NULL] autorelease];
    [self.recorder prepareToRecord];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [self.recorder record];
    
    return true;
}

- (void)onStopRecording
{
    if (self.recorder && self.recorder.recording)
    {
        [self.recorder stop];

        [[AVAudioSession sharedInstance] setActive:NO error:nil];
    }
}



- (void)onCancelRecording
{
    if (self.recorder && self.recorder.recording)
    {
        [self.recorder stop];
        [self.recorder deleteRecording];
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
    }
}


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"audioPlayerDidFinish...\n");
    
    [self onStopPlaying];
    
    [self onPlayResult:true];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"audioPlayerDecodeError...\n");
    
    [self onStopPlaying];
    
    [self onPlayResult:false];
}

- (BOOL)onStartPlaying:(NSString *)filepath
{
    NSLog(@"startPlaying \n");
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (session == nil)
    {
        return false;
    }
    
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    [self stopPlayingAndRecording];
    
    NSURL *url = [NSURL fileURLWithPath:filepath];
    
    self.player = [[[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil] autorelease];
    self.player.delegate = self;
    [FileNameHelper setAudioOutputPort];
    
    [self.player prepareToPlay];
    [self.player play];
    
    return true;
}

- (void)onStopPlaying
{
    if (self.player && self.player.playing)
    {
        [self.player stop];
    }
}

- (void)stopPlayingAndRecording
{
    [self onStopRecording];
    [self onStopPlaying];
}


- (BOOL)recording
{
    if (self.recorder)
    {
        return self.recorder.recording;
    }
    else
    {
        return NO;
    }
}

- (BOOL)playing
{
    if (self.player)
    {
        return self.player.playing;
    }
    else
    {
        return NO;
    }
}



- (NSDictionary*)getRecorderSettings
{
    NSDictionary *recordSetting = [
                                   [NSDictionary alloc] initWithObjectsAndKeys:
                                   [NSNumber numberWithFloat: 8000.0],AVSampleRateKey, //采样率
                                   [NSNumber numberWithInt: kAudioFormatLinearPCM],AVFormatIDKey,//wav格式，录制时文件名必须带扩展名.wav
                                   [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,//采样位数 默认 16
                                   [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,//通道的数目
                                   nil];
    return recordSetting;
}



- (void) setScriptHandler:(int)scriptHandler
{
    if (self.userCallback)
    {
        LuaBridge::releaseLuaFunctionById(self.userCallback);
        self.userCallback = 0;
    }
    self.userCallback = scriptHandler;
}

- (int) getScriptHandler
{
    return self.userCallback;
}


- (void)onRecordResult:(BOOL)result
{
    if(self.userCallback)
    {
        LuaBridge::pushLuaFunctionById(self.userCallback);
        LuaStack *stack = LuaBridge::getStack();
        
        NSString *path = [self.recordingPath stringByAppendingString: @".amr"];
        NSString *str = @"";
        if (result)
        {
            str = @"success";
        }
        else
        {
            str = @"error";
        }
        
        stack->pushString([str cStringUsingEncoding:NSASCIIStringEncoding]);
        stack->pushString([path cStringUsingEncoding:NSASCIIStringEncoding]);
        stack->executeFunction(2);
    }
    
}

- (void)onPlayResult:(BOOL)result
{
    if(self.userCallback)
    {
        LuaBridge::pushLuaFunctionById(self.userCallback);
        LuaStack *stack = LuaBridge::getStack();
        NSString *str = @"";
        if (result)
        {
            str = @"finish";
        }
        else
        {
            str = @"error";
        }
        
        stack->pushString([str cStringUsingEncoding:NSASCIIStringEncoding]);
        stack->executeFunction(1);
    }
}


- (BOOL)pcmToMp3
{
    NSLog(@"pcmToMp3 \n");
    
    if (!self.recordingPath)
    {
        return false;
    }
    
    NSString *cafFilePath = [self.recordingPath stringByAppendingString: @".wav"];
    NSString *mp3FilePath = [self.recordingPath stringByAppendingString: @".mp3"];
    
    NSLog(@"cafFilePath %@\n", cafFilePath);
    BOOL _flag = true;
    
    @try {
        int read, write;
        
        FILE *pcm = fopen([cafFilePath cStringUsingEncoding:1], "rb");
        if (pcm)
        {
            fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
            FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");  //output
        
            const int PCM_SIZE = 8192;
            const int MP3_SIZE = 8192;
            short int pcm_buffer[PCM_SIZE*2];
            unsigned char mp3_buffer[MP3_SIZE];
        
            lame_t lame = lame_init();
            lame_set_num_channels (lame, 2); // 设置 1 为单通道，默认为 2 双通道
            lame_set_in_samplerate(lame, 8000.0);
            lame_set_VBR(lame, vbr_default);
            lame_init_params(lame);
        
            do {
                read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
                if (read == 0)
                    write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
                else
                    write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
                fwrite(mp3_buffer, write, 1, mp3);
            
            } while (read != 0);
        
            lame_close(lame);
            fclose(mp3);
            fclose(pcm);
        
            //删除文件
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtPath:cafFilePath error:nil];
        }
        else
        {
            NSLog(@"invalid filepath: ==> %@\n", cafFilePath);
            _flag = false;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception: %@ \n",[exception description]);
        _flag = false;
    }
    @finally {
        //[self performSelectorOnMainThread:@selector(convertMp3Finish)
        //                       withObject:nil
        //                    waitUntilDone:YES];
    }
    
    return _flag;
}


- (BOOL)pcmToAmr
{

    
    NSString *path_wav = [self.recordingPath stringByAppendingString: @".wav"];
    NSString *path_amr = [self.recordingPath stringByAppendingString: @".amr"];
    NSLog(@"pcmToAmr %@\n", path_wav);
    
    if (! EncodeWAVEFileToAMRFile([path_wav cStringUsingEncoding:NSASCIIStringEncoding], [path_amr cStringUsingEncoding:NSASCIIStringEncoding], 1, 16))
    {
        NSLog(@"pcmToAmr: fail !!!\n");
        return false;
    }
    
    //删除文件
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:path_wav error:nil];
    
    return true;
}

- (BOOL)amrToPcm:(NSString *)aAmrPath wavSavePath:(NSString *)aSavePath
{
    NSLog(@"amrToPcm \n");
    

    if (! DecodeAMRFileToWAVEFile([aAmrPath cStringUsingEncoding:NSASCIIStringEncoding], [aSavePath cStringUsingEncoding:NSASCIIStringEncoding]))
    {
        NSLog(@"amrToPcm: fail !!!\n");
        return false;
    }

    
    return true;
}



@end
