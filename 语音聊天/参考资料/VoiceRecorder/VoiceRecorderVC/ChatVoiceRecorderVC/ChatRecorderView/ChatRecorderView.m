//
//  ChatRecorderView.m
//  Jeans
//
//  Created by Jeans on 3/24/13.
//  Copyright (c) 2013 Jeans. All rights reserved.
//

#import "ChatRecorderView.h"

#define kTrashImage1         [UIImage imageNamed:@"recorder_trash_can0.png"]
#define kTrashImage2         [UIImage imageNamed:@"recorder_trash_can1.png"]
#define kTrashImage3         [UIImage imageNamed:@"recorder_trash_can2.png"]

@interface ChatRecorderView(){
    NSArray         *peakImageAry;
    NSArray         *trashImageAry;
    BOOL            isPrepareDelete;
    BOOL            isTrashCanRocking;
}

@end

@implementation ChatRecorderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initilization];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initilization];
    }
    return self;
}

- (void)initilization{
    peakMeterIV=[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 160, 160)];
    peakMeterIV.image=[UIImage imageNamed:@"speaker_0.png"];
    [self addSubview:peakMeterIV];
    trashCanIV=[[UIImageView alloc] initWithFrame:CGRectMake(122, 111, 31, 40)];
    trashCanIV.image=[UIImage imageNamed:@"recorder_trash_can0.png"];
    [self addSubview:trashCanIV];
    countDownLabel=[[UILabel alloc] initWithFrame:CGRectMake(8, 15, 145, 21)];
    countDownLabel.backgroundColor=[UIColor clearColor];
    [self addSubview:countDownLabel];
    self.backgroundColor=[UIColor colorWithRed:0.0/255 green:0.0/255 blue:0.0/255 alpha:0.6];
    
    //初始化音量peak峰值图片数组
    peakImageAry = [[NSArray alloc]initWithObjects:
                    [UIImage imageNamed:@"speaker_0.png"],
                    [UIImage imageNamed:@"speaker_1.png"],
                    [UIImage imageNamed:@"speaker_2.png"],
                    [UIImage imageNamed:@"speaker_3.png"], nil];
    trashImageAry = [[NSArray alloc]initWithObjects:kTrashImage1,kTrashImage2,kTrashImage3,kTrashImage2, nil];
}

- (void)dealloc {
    [peakImageAry release];
    [trashImageAry release];
    [_peakMeterIV release];
    [_trashCanIV release];
    [_countDownLabel release];
    [super dealloc];
}

#pragma mark -还原显示界面
- (void)restoreDisplay{
    //还原录音图
    _peakMeterIV.image = [peakImageAry objectAtIndex:0];
    //停止震动
    [self rockTrashCan:NO];
    //还原倒计时文本
    _countDownLabel.text = @"";
}

#pragma mark - 是否准备删除
- (void)prepareToDelete:(BOOL)_preareDelete{
    if (_preareDelete != isPrepareDelete) {
        isPrepareDelete = _preareDelete;
        [self rockTrashCan:isPrepareDelete];
    }
}
#pragma mark - 是否摇晃垃圾桶
- (void)rockTrashCan:(BOOL)_isTure{
    if (_isTure != isTrashCanRocking) {
        isTrashCanRocking = _isTure;
        if (isTrashCanRocking) {
            //摇晃
            _trashCanIV.animationImages = trashImageAry;
            _trashCanIV.animationRepeatCount = 0;
            _trashCanIV.animationDuration = 1;
            [_trashCanIV startAnimating];
        }else{
            //停止
            if (_trashCanIV.isAnimating)
                [_trashCanIV stopAnimating];
            _trashCanIV.animationImages = nil;
            _trashCanIV.image = kTrashImage1;
        }
    }
}


#pragma mark - 更新音频峰值
- (void)updateMetersByAvgPower:(float)_avgPower{
    //-160表示完全安静，0表示最大输入值
    //
    NSInteger imageIndex = 0;
    if (_avgPower >= -40 && _avgPower < -30)
        imageIndex = 1;
    else if (_avgPower >= -30 && _avgPower < -25)
        imageIndex = 2;
    else if (_avgPower >= -25)
        imageIndex = 3;
    
    _peakMeterIV.image = [peakImageAry objectAtIndex:imageIndex];
}

@end
