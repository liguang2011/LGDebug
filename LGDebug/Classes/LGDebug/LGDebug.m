//
//  LGDebug.m
//  LGDebug
//
//  Created by lg on 2019/7/11.
//

#import "LGDebug.h"
#import "LGDebugWindow.h"
#import "IASKAppSettingsViewController.h"
#import "FHHFPSIndicator.h"
#import "LGDebugNotificationManager.h"
//用于接收整体事件

LGDebugConfig const *LGDebugConfigObj;
BOOL DebugKeyMotionIsRunning = NO;

NSString *const DebugIsRunningFlagKey = @"DebugIsRunningFlagKey";

extern NSString *kLGDebugAPISwitchState;

@interface LGDebug()<LGDebugProtocol>

@property (nonatomic, strong)LGDebugWindow *debugWindow;//按钮容器
@property (nonatomic, strong)LGDebugSettingsBaseViewController *configViewController;//主界面

@end

@implementation LGDebug
+ (BOOL)isDebugRunning {
    return DebugKeyMotionIsRunning;
}

+ (void)initService {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [LGDebug initWithConfig:[[LGDebugConfig alloc] init]];
    });
}

+ (void)initWithConfig:(LGDebugConfig *)config {
    
    if (config == nil) {
        [self initService];
        return;
    }else if (config.configBundleFileName.length == 0) {
        config.configBundleFileName = @"LGDebug";
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [LGDebug shareInstance];
        LGDebugConfigObj = config;
        
        BOOL isRunning = [[NSUserDefaults standardUserDefaults] boolForKey:DebugIsRunningFlagKey];
        if (!DebugKeyMotionIsRunning && isRunning) {
            DebugKeyMotionIsRunning = isRunning;
            [LGDebug start];
        }
        
        //不是第一次启动的话为 YES
        BOOL isNotFirstTimeSetup = [[NSUserDefaults standardUserDefaults] boolForKey:@"isFirstTimeSetupDebugger"];
        //如果是第一次启动 强制显示DEBUG工具
        if (!isNotFirstTimeSetup) {
            [LGDebug start];
            
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isFirstTimeSetupDebugger"];
        }
    });
}

+ (LGDebug *)shareInstance {
    static LGDebug *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LGDebug alloc] init];
    });
    
    return instance;
}

#pragma mark - Event and Respone

/// 开启debug功能
- (void)startDebugModel {
    DebugKeyMotionIsRunning = YES;
    LGDebug *debug = [LGDebug shareInstance];
    debug.debugWindow.hidden = NO;
    [[UIApplication sharedApplication].delegate.window addSubview:self.debugWindow];
    
    if ([LGDebug respondsToSelector:@selector(LGDebugStartNotification)]) {
        //外部接口  用于启动成功的回调
        [LGDebug LGDebugStartNotification];
    }

    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DebugIsRunningFlagKey];
}

- (void)stopDebugModel {
    DebugKeyMotionIsRunning = NO;
    LGDebug *debug = [LGDebug shareInstance];
    [debug.debugWindow resignKeyWindow];
    debug.debugWindow.hidden = YES;
    [self onClickDoneButtonItem];
    
    if ([LGDebug respondsToSelector:@selector(LGDebugStopNotification)]) {
        [LGDebug LGDebugStopNotification];
    }

    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:DebugIsRunningFlagKey];
}

/// 隐藏主界面
+ (void)dismiss {
    [[LGDebug shareInstance] onClickDoneButtonItem];
}

/// 隐藏debug按钮
+ (void)close {
    [[LGDebug shareInstance] stopDebugModel];
}

+ (void)start {
    [[LGDebug shareInstance] startDebugModel];
}

/// 打开主页控制器
- (void)pushDebugConfigViewController {
//    self.configViewController.modalPresentationStyle = UIModalPresentationFullScreen;
//    [[NavigationController currentNavigation] presentViewController:self.configViewController animated:YES completion:nil];
    
    UINavigationController *naviga = [[UINavigationController alloc] initWithRootViewController:self.configViewController];
    naviga.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [[[[UIApplication sharedApplication] delegate] window].rootViewController presentViewController:naviga animated:YES completion:nil];
}

- (void)onClickDoneButtonItem {
    [[LGDebugNotificationManager shareManager] removeNotificationWithObject:_configViewController];
    [_configViewController dismissViewControllerAnimated:NO completion:nil];
    _configViewController = nil;
}

#pragma mark - Setter and Getter

- (LGDebugWindow *)debugWindow {
    if (!_debugWindow) {
        CGRect frame = [UIScreen mainScreen].bounds;
        _debugWindow = [[LGDebugWindow alloc]
                        initWithFrame:CGRectMake(frame.size.width-100,
                                                 frame.size.height-120, 60, 60)];
        [_debugWindow.debugButton addTarget:self action:@selector(pushDebugConfigViewController) forControlEvents:UIControlEventTouchUpInside];
        
        //帧率显示
        BOOL isShowFPSIndicator = [[[NSUserDefaults standardUserDefaults] objectForKey:@"LGDebugFPSIndicator"] boolValue];
        if (isShowFPSIndicator) {
            [[FHHFPSIndicator sharedFPSIndicator] show];
            [FHHFPSIndicator sharedFPSIndicator].fpsLabelPosition = FPSIndicatorPositionTopLeft;
        }
    }
    
    return _debugWindow;
}

- (LGDebugSettingsBaseViewController *)configViewController {
    if (!_configViewController) {
        
        NSString *customFileName = LGDebugConfigObj.configBundleFileName;
        if (!customFileName.length) {
            customFileName = @"LGDebug";
        }
        _configViewController = [[LGDebugSettingsBaseViewController alloc] initWithFile:customFileName specifier:[[IASKSpecifier alloc] initWithSpecifier:@{@"Key":@"配置项"}]];
        _configViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onClickDoneButtonItem)];
    }
    return _configViewController;
}

- (LGDebugSettingsBaseViewController *)controller {
    return self.configViewController;
}

@end
