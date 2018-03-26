//
//  YYRDebugTouchView.m
//  MVVMArchitectureDemo
//
//  Created by 袁应荣 on 2018/3/26.
//  Copyright © 2018年 袁应荣. All rights reserved.
//

#import "YYRDebugTouchView.h"
#import "YYRConfigureManager.h"
#import "YYRControllerHelper.h"

/// 显示状态的key
static NSString * const YYRDebugTouchViewStatusKey = @"YYRDebugTouchViewStatusKey";


@interface YYRDebugTouchView ()

/// closeBtn
@property (nonatomic, readwrite, weak) UIButton *closeBtn;
/// 开始点
@property (nonatomic, readwrite, assign) CGPoint startPoint;

/// 是否在动画
@property (nonatomic, readwrite, assign , getter = isAnimated) BOOL animated;
@end
@implementation YYRDebugTouchView

YYRSingletonM(Instance)

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.image = YYRImageNamed(@"assistivetouch");
        self.userInteractionEnabled = YES;
        
        /// 添加tap手势
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tapAction:)]];
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        [window addSubview:self];
        self.yyr_x = [UIScreen mainScreen].bounds.size.width - self.yyr_width - 20;
        self.yyr_y = 84;
        
        self.hidden = [self isHide];
    }
    return self;
}



- (void)setHide:(BOOL)hide{
    
    if (self.isAnimated) return;
    
    [[NSUserDefaults standardUserDefaults] setBool:hide forKey:YYRDebugTouchViewStatusKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    hide?[self close]:[self open];
}


- (BOOL)isHide{
    BOOL temp = [[NSUserDefaults standardUserDefaults] boolForKey:YYRDebugTouchViewStatusKey];
    NSLog(@"++++ Touch View Is Hide %zd ++++" , temp);
    return temp;
}


- (void)open{
    /// 动画开始，禁止交互
    self.userInteractionEnabled = NO;
    self.animated = YES;
    
    self.hidden = NO;
    self.transform = CGAffineTransformIdentity;
    self.transform = CGAffineTransformMakeScale(.2, .2);
    [UIView animateWithDuration:.25f delay:0 usingSpringWithDamping:.3f initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.transform = CGAffineTransformMakeScale(1.0, 1.0);
    } completion:^(BOOL finished) {
        self.transform = CGAffineTransformIdentity;
        /// 动画结束，允许交互
        self.userInteractionEnabled = YES;
        
        self.animated = NO;
    }];
    
    
}

- (void)close{
    /// 动画开始，禁止交互
    self.animated = YES;
    self.userInteractionEnabled = NO;
    [UIView animateWithDuration:.25f animations:^{
        self.transform = CGAffineTransformMakeScale(.2, .2);
    } completion:^(BOOL finished) {
        self.transform = CGAffineTransformIdentity;
        self.hidden = YES;
        /// 动画结束，允许交互
        self.userInteractionEnabled = YES;
        self.animated = NO;
    }];
}


#pragma mark - Action
- (void)_tapAction:(UITapGestureRecognizer *)tapGr{
    LCActionSheet *actionSheet = [LCActionSheet sheetWithTitle:nil cancelButtonTitle:@"取消" didDismiss:^(LCActionSheet * _Nonnull actionSheet, NSInteger buttonIndex) {
        if (buttonIndex == 0) return ;
        
        if (buttonIndex == 1) {
            /// 环境的切换
            /// 主题
            NSString *title = nil;
            if ([YYRConfigureManager applicationFormalSetting]) {
                title = [YYRConfigureManager applicationAppStoreFormalSetting]? [NSString stringWithFormat:@"当前环境：%@", @"上线环境"]: [NSString stringWithFormat:@"当前环境：%@", @"预上线环境"];
            }else{
                title = [NSString stringWithFormat:@"当前环境：%@", @"测试环境"];
            }
            
            /// 预上线
            UIAlertAction *switchToPrePublish = [UIAlertAction actionWithTitle:@"预上线环境" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [YYRConfigureManager setApplicationFormalSetting:YES];
                [YYRConfigureManager setApplicationAppStoreFormalSetting:NO];
                [[YYRHTTPService sharedInstance] logoutUser];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    exit(0);
                });
            }];
            switchToPrePublish.textColor = YYRColorFromHexString(@"#0ECCCA");
            /// 上线
            UIAlertAction *switchToPublish = [UIAlertAction actionWithTitle:@"上线环境" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [YYRConfigureManager setApplicationFormalSetting:YES];
                [YYRConfigureManager setApplicationAppStoreFormalSetting:YES];
                [[YYRHTTPService sharedInstance] logoutUser];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    exit(0);
                });
                
            }];
            switchToPublish.textColor = YYRColorFromHexString(@"#0ECCCA");
            /// 测试
            UIAlertAction *switchToDevelop = [UIAlertAction actionWithTitle:@"测试环境" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [YYRConfigureManager setApplicationFormalSetting:NO];
                [YYRConfigureManager setApplicationAppStoreFormalSetting:NO];
                [[YYRHTTPService sharedInstance] logoutUser];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    exit(0);
                });
            }];
            switchToDevelop.textColor = YYRColorFromHexString(@"#0ECCCA");
            /// 取消
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            }];
            cancelAction.textColor = YYRColorFromHexString(@"#8E929D");
            /// alertController
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:@"您确定要切换环境,程序将会闪退哦\n⚡️⚡️⚡️" preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:cancelAction];
            alertController.titleColor = YYRColorFromHexString(@"#3C3E44");
            alertController.messageColor = YYRColorFromHexString(@"#9A9A9C");
            
            if ([YYRConfigureManager applicationFormalSetting]) {
                
                if ([YYRConfigureManager applicationAppStoreFormalSetting]) {
                    /// 当前 ————> 上线环境
                    [alertController addAction:switchToPrePublish];
                    [alertController addAction:switchToDevelop];
                }else{
                    /// 当前 ————> 预上线环境
                    [alertController addAction:switchToPublish];
                    [alertController addAction:switchToDevelop];
                }
            }else{
                /// 当前 ————> 测试环境
                [alertController addAction:switchToPrePublish];
                [alertController addAction:switchToPublish];
            }
            [[YYRControllerHelper currentViewController] presentViewController:alertController animated:YES completion:nil];
        }else if(buttonIndex == 2){
            /// Http/Https的切换
            NSString *title = [NSString stringWithFormat:@"当前方式：%@", [YYRConfigureManager applicationUseHttps]?@"https":@"http"];
            
            [NSObject yyr_showAlertViewWithTitle:title message:@"您确定要切换环境,程序将会闪退哦\n⚡️⚡️⚡️" confirmTitle:[YYRConfigureManager applicationUseHttps]?@"http":@"https" cancelTitle:@"取消" confirmAction:^{
                [YYRConfigureManager setApplicationUseHttps:![YYRConfigureManager applicationUseHttps]];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    exit(0);
                });
            } cancelAction:NULL];
        }
    } otherButtonTitleArray:@[@"切换正式/测试环境",@"切换http/https"]];
    
    [actionSheet show];
}


#pragma mark - Override
- (void)setFrame:(CGRect)frame{
    frame.size.width = 65;
    frame.size.height = 65;
    [super setFrame:frame];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    CGFloat closeBtnWH = 36;
    self.closeBtn.frame = CGRectMake(self.frame.size.width - closeBtnWH , 0, closeBtnWH, closeBtnWH);
}



#pragma mark - touch move
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    //保存触摸起始点位置
    CGPoint point = [[touches anyObject] locationInView:self];
    self.startPoint = point;
    
    //该view置于最前
    [[self superview] bringSubviewToFront:self];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    //计算位移=当前位置-起始位置
    CGPoint point = [[touches anyObject] locationInView:self];
    float dx = point.x - self.startPoint.x;
    float dy = point.y - self.startPoint.y;
    
    //计算移动后的view中心点
    CGPoint newcenter = CGPointMake(self.center.x + dx, self.center.y + dy);
    
    /* 限制用户不可将视图托出屏幕 */
    float halfx = CGRectGetMidX(self.bounds);
    //x坐标左边界
    newcenter.x = MAX(halfx, newcenter.x);
    //x坐标右边界
    newcenter.x = MIN(self.superview.bounds.size.width - halfx, newcenter.x);
    
    //y坐标同理
    float halfy = CGRectGetMidY(self.bounds);
    newcenter.y = MAX(halfy, newcenter.y);
    newcenter.y = MIN(self.superview.bounds.size.height - halfy, newcenter.y);
    
    /// 动画过度
    [UIView animateWithDuration:.25f delay:0 usingSpringWithDamping:.3f initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^{
        //移动view
        self.center = newcenter;
    } completion:^(BOOL finished) {
        
    }];
}


@end
