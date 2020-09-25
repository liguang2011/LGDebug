//
//  LGDebug.m
//  LGDebug
//
//  Created by lg on 2019/7/11.
//

#import "LGDebug.h"
#import "FLEXManager.h"
#import "LGDebugWindow.h"
#import "LGDebugURLProtocol.h"
#import "LGDebugSettingsBaseViewController.h"
#import "IASKAppSettingsViewController.h"

NSString *const LGDebugNotificationMessage = @"LGDebugNotificationMessage";
NSString *const DebugNotificationMessageType = @"DebugNotificationMessageType";
NSString *const DebugNotificationMotionStart = @"DebugNotificationMotionStart";
NSString *const DebugNotificationMotionStop = @"DebugNotificationMotionStop";
NSString *const DebugNotificationCloseConfigWindow = @"DebugNotificationCloseConfigWindow";

LGDebugConfig const *LGDebugConfigObj;
BOOL const *DebugKeyMotionIsRunning = NO;

NSString *const DebugIsRunningFlagKey = @"DebugIsRunningFlagKey";

extern NSString *kLGDebugAPISwitchState;

@interface LGDebug()<LGDebugProtocol>

@property (nonatomic, strong)LGDebugWindow *debugWindow;
@property (nonatomic, strong)UIWindow *configWindow;
@property (nonatomic, strong)LGDebugSettingsBaseViewController *configViewController;

@end

@implementation LGDebug
+ (BOOL)isDebugRunning {
    return DebugKeyMotionIsRunning;
}

+ (void)initService {
    [LGDebug initWithConfig:[[LGDebugConfig alloc] init]];
}

+ (void)initWithConfig:(LGDebugConfig *)config {
    LGDebug *debug = [LGDebug shareInstance];
    LGDebugConfigObj = config;
    
    BOOL isRunning = [[NSUserDefaults standardUserDefaults] boolForKey:DebugIsRunningFlagKey];
    if (!DebugKeyMotionIsRunning && isRunning) {
        DebugKeyMotionIsRunning = isRunning;
        NSNotification *notification = [NSNotification notificationWithName:LGDebugNotificationMessage object:nil userInfo:@{DebugNotificationMessageType:DebugNotificationMotionStart}];
        if([NSThread isMainThread]){
            [[LGDebug shareInstance] notificationEvent:notification];
            
        }else{
            dispatch_sync(dispatch_get_main_queue(), ^{
                [[LGDebug shareInstance] notificationEvent:notification];
            });
        }
    }
}

+ (id)shareInstance {
    static LGDebug *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LGDebug alloc] init];
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:instance selector:@selector(notificationEvent:) name:LGDebugNotificationMessage object:nil];
    });
    
    return instance;
}

#pragma mark - Event and Respone

- (void)startDebugModel {
    DebugKeyMotionIsRunning = YES;
    LGDebug *debug = [LGDebug shareInstance];
    [debug.debugWindow makeKeyAndVisible];
    [[UIApplication sharedApplication].windows[0] makeKeyAndVisible];
    debug.debugWindow.hidden = NO;
    
    if ([LGDebug respondsToSelector:@selector(LGDebugStartNotification)]) {
        [LGDebug LGDebugStartNotification];
    }
    [LGDebugURLProtocol updateURLProtocol];
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
    [LGDebugURLProtocol updateURLProtocol];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:DebugIsRunningFlagKey];
}

- (void)pushDebugConfigViewController {
    __block CGRect configWindowFrame = self.configWindow.frame;
    configWindowFrame.origin.y = configWindowFrame.size.height;
    self.configWindow.frame = configWindowFrame;
    [self.configWindow makeKeyAndVisible];
    [UIView animateWithDuration:0.3 animations:^{
        configWindowFrame.origin.y = 0;
        self.configWindow.frame = configWindowFrame;
    }];
}

- (void)onClickDoneButtonItem {
    [self.configWindow resignKeyWindow];
    self.configWindow.hidden = YES;
    [[UIApplication sharedApplication].windows[0] makeKeyAndVisible];
    self.configWindow = nil;
}

#pragma mark - NSNotification

- (void)notificationEvent:(NSNotification *)notification {
    NSString *messageType = [notification userInfo][DebugNotificationMessageType];
    if ([messageType isEqualToString:DebugNotificationMotionStart]) {
        [self startDebugModel];
    } else if ([messageType isEqualToString:DebugNotificationMotionStop]) {
        [self stopDebugModel];
    } else if ([messageType isEqualToString:DebugNotificationCloseConfigWindow]) {
        [self onClickDoneButtonItem];
    }
}

#pragma mark - Setter and Getter

- (LGDebugWindow *)debugWindow {
    if (!_debugWindow) {
        CGRect frame = [UIScreen mainScreen].bounds;
        _debugWindow = [[LGDebugWindow alloc]
                        initWithFrame:CGRectMake(frame.size.width-100,
                                                 frame.size.height-120, 60, 60)];
        [_debugWindow.debugButton addTarget:self action:@selector(pushDebugConfigViewController) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _debugWindow;
}

- (UIWindow *)configWindow {
    if (!_configWindow) {
        _configWindow = [[UIWindow alloc] init];
        _configWindow.windowLevel = UIWindowLevelAlert + 1.0f;
        _configWindow.frame = [UIScreen mainScreen].bounds;
        _configWindow.rootViewController = [[UINavigationController alloc] initWithRootViewController:self.configViewController];
    }
    return _configWindow;
}

- (LGDebugSettingsBaseViewController *)configViewController {
    if (!_configViewController) {
        _configViewController = [[LGDebugSettingsBaseViewController alloc] initWithFile:@"LGDebug" specifier:[[IASKSpecifier alloc] initWithSpecifier:@{@"Key":@"配置项"}]];
        _configViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onClickDoneButtonItem)];
    }
    return _configViewController;
}
@end
