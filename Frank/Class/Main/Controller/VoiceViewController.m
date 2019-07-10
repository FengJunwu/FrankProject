//
//  VoiceViewController.m
//  Frank
//
//  Created by fengjunwu on 2019/6/21.
//  Copyright © 2019 819134700@qq.com. All rights reserved.
//

#import "VoiceViewController.h"
#import "VoiceAssistantModel.h"
#import "VoiceChatViewController.h"
#import "VoiceAssistantViewController.h"
#import "BaseNavigationViewController.h"
#import "DrawerViewController.h"
#import "TTSViewModel.h"

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

 //1012 -iphone  1152 ipad  1109 ipad

@interface VoiceViewController ()<VoiceChatViewDelegate>
{
    BabyBluetooth *baby;
}

@property (nonatomic,strong)NSArray *dataSource;
@property (nonatomic, strong) VoiceChatViewController *chatVc;
@property (nonatomic,strong)TTSViewModel *ttsViewModel;

//视频播放器
@property (nonatomic, weak) AVPlayer *player;
@property (nonatomic, weak) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) UIImageView *imageView;


@end

@implementation VoiceViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    
    

    if (self.characterId.length > 0 ) {
        
        self.ttsViewModel = [[TTSViewModel alloc] init];
        //    __weak __typeof(self) weakSelf = self;
        self.ttsViewModel.startSpeachBlock = ^{
            //weakSelf.voiceBut.enabled = NO;
        };
        self.ttsViewModel.stopSpeachBlock = ^{
            //        weakSelf.voiceBut.enabled = YES;
        };
        //本次选择的模特
        if (self.ver.length > 0) {
            NSString* where = [NSString stringWithFormat:@"where %@=%@ and %@=%@ ",bg_sqlKey(@"characterId"),bg_sqlValue(self.characterId),bg_sqlKey(@"ver"),bg_sqlValue(self.ver)];
            _dataSource = [VoiceAssistantModel bg_find:bg_tablename where:where];
        }else{
            NSString* where = [NSString stringWithFormat:@"where %@=%@",bg_sqlKey(@"characterId"),bg_sqlValue(self.characterId)];
            _dataSource = [VoiceAssistantModel bg_find:bg_tablename where:where];

        }
        
        if (_dataSource.count > 0) {
            VoiceAssistantModel *model = _dataSource[0];
            
            [self configUI:model];
            
            [[NSUserDefaults standardUserDefaults] setObject:self.characterId forKey:@"characterId"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [[NSUserDefaults standardUserDefaults] setObject:self.ver forKey:@"ver"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
    }else {
        self.characterId = [[NSUserDefaults standardUserDefaults] objectForKey:@"characterId"];
        self.ver = [[NSUserDefaults standardUserDefaults] objectForKey:@"ver"];
        if (self.characterId.length > 0 && self.ver.length > 0) {
            //读取上次选择的模特
            NSString* where = [NSString stringWithFormat:@"where %@=%@ and %@=%@ ",bg_sqlKey(@"characterId"),bg_sqlValue(self.characterId),bg_sqlKey(@"ver"),bg_sqlValue(self.ver)];
            _dataSource = [VoiceAssistantModel bg_find:bg_tablename where:where];
            if (_dataSource.count > 0) {
                VoiceAssistantModel *model = _dataSource[0];
                [self configUI:model];
                
            }
        }
    }
    
//    self.view.backgroundColor = [UIColor colorWithRed:arc4random_uniform(256)/255.0   green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:1.0];
    // 拖动手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGestureView:)];
    [self.view addGestureRecognizer:pan];
    
    [self addChildViewController:self.chatVc];
    [self.view addSubview:self.chatVc.view];
    self.chatVc.view.frame = self.view.bounds;
    
    ///监听是否停止播放视频
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(StopPlayingVideoAction) name:@"StopPlayingVideo" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(StopPlayingVideoAction) name:@"leftStopPlayingVideo" object:nil];
    
    //初始化BabyBluetooth 蓝牙库
    baby = [BabyBluetooth shareBabyBluetooth];
    //配置ble委托
    [self babyDelegate];
    //读取服务
    baby.channel(writeOnCharacteristicView).characteristicDetails(self.peripheral,self.writeCharacteristics);
//    baby.channel(readOnCharacteristicView).characteristicDetails(self.peripheral,self.readCharacteristics);
    
}


-(void)StopPlayingVideoAction{
    
    if (self.player) {
        [self.player pause];
    }
}
    


-(void)configUI:(VoiceAssistantModel *)model{
    
    [self.ttsViewModel startSpeach:model.desc language:@"en-US"];
    
    NSString *path = [NSString stringWithFormat:@"%@%@",[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject],model.bgImg];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kMainScreenWidth, kMainScreenHeight - Height_NavBar)];
    imageView.image = [UIImage imageWithContentsOfFile:path];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.layer.masksToBounds = YES;
    [self.view addSubview:imageView];
    _imageView = imageView;
    
    
}



//手势\清屏动画
- (void)panGestureView:(UIPanGestureRecognizer*)pan {

    CGPoint point = [pan translationInView:pan.view];
    switch (pan.state) {
            case UIGestureRecognizerStateBegan:
            break;
            case UIGestureRecognizerStateChanged:
        {
            self.chatVc.view.left = self.view.width + point.x;
            break;
        }
            case UIGestureRecognizerStateEnded:
        {
            if  (point.x > -kScreenWidth/4){ //临界点
                [UIView animateWithDuration:0.3 animations:^{
                    self.chatVc.view.left = self.view.width;
                    
                }completion:^(BOOL finished) {
                    
                }];
            }else{
                
                [UIView animateWithDuration:0.3 animations:^{
                    self.chatVc.view.left = 0;
                }completion:^(BOOL finished) {
                    
                }];
            }
        }
            break;
        default:
            break;
    }
}

- (VoiceChatViewController *)chatVc {
    if (_chatVc == nil) {
        _chatVc = [[VoiceChatViewController alloc]init];
        _chatVc.dataSource = _dataSource;
        _chatVc.delegate = self;
    }
    return _chatVc;
}


#pragma mark--VoiceChatViewDelegate

-(void)playDialogue:(NSString *)DialogueContent{
    
    if (!_ttsViewModel) {
        self.ttsViewModel = [[TTSViewModel alloc] init];
    }
    
    [self.ttsViewModel startSpeach:DialogueContent language:@"en-US"];
    
    ///调用蓝牙写入
    [self writeValue];
}

-(void)playMp3:(NSString *)mp3Url bgImg:(NSString *)bgImg{
    
    _imageView.image = [UIImage imageWithContentsOfFile:bgImg];
    
}

-(void)playVideo:(NSString *)videoUrl{
    NSLog(@"%@",videoUrl);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        AVPlayer *player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:videoUrl]];
        self.player = player;
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
        self.playerLayer = playerLayer;
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;///等比例填充，直到一个维度到达区域边界
        playerLayer.frame = CGRectMake(0, 0, kMainScreenWidth, kMainScreenHeight - Height_NavBar);
        [self.imageView.layer addSublayer:playerLayer];
        
        [self.player play];
    });
}


#pragma mark-------蓝牙委托
-(void)babyDelegate{
    
//    __weak typeof(self)weakSelf = self;
    //设置读取characteristics的委托
    [baby setBlockOnReadValueForCharacteristicAtChannel:writeOnCharacteristicView block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        
        NSLog(@"读取到的值======%@",characteristics.value);
        //        NSLog(@"CharacteristicViewController===characteristic name:%@ value is:%@",characteristics.UUID,characteristics.value);
//        [weakSelf insertReadValues:characteristics];
    }];
    //设置发现characteristics的descriptors的委托
    [baby setBlockOnDiscoverDescriptorsForCharacteristicAtChannel:writeOnCharacteristicView block:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        //        NSLog(@"CharacteristicViewController===characteristic name:%@",characteristic.service.UUID);
        for (CBDescriptor *d in characteristic.descriptors) {
            //            NSLog(@"CharacteristicViewController CBDescriptor name is :%@",d.UUID);
            NSLog(@"描述---%@",d.value);
        }
    }];
    //设置读取Descriptor的委托
    [baby setBlockOnReadValueForDescriptorsAtChannel:writeOnCharacteristicView block:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
    
        NSLog(@"CharacteristicViewController Descriptor name:%@ value is:%@",descriptor.characteristic.UUID, descriptor.value);
    }];
    
    //设置写数据成功的block
    [baby setBlockOnDidWriteValueForCharacteristicAtChannel:writeOnCharacteristicView block:^(CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"setBlockOnDidWriteValueForCharacteristicAtChannel characteristic:%@ and new value:%@",characteristic.UUID, characteristic.value);
    }];
    
    //设置通知状态改变的block
    [baby setBlockOnDidUpdateNotificationStateForCharacteristicAtChannel:writeOnCharacteristicView block:^(CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"uid:%@,isNotifying:%@",characteristic.UUID,characteristic.isNotifying?@"on":@"off");
    }];
    
}

//写一个值
-(void)writeValue{
    //    int i = 1;
    Byte b = 0X01;
    NSData *data = [NSData dataWithBytes:&b length:sizeof(b)];
    [self.peripheral writeValue:data forCharacteristic:self.writeCharacteristics type:CBCharacteristicWriteWithResponse];
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end