//
//  UIWindow+LGDebug.m
//  LGDebug
//
//  Created by lg on 2019/7/11.
//

#import "UIWindow+LGDebug.h"
#import "LGDebugConfig.h"
#import <AudioToolbox/AudioToolbox.h>

static int motionCount;    //摇动次数

extern NSString *LGDebugNotificationMessage;
extern NSString *DebugNotificationMessageType;
extern NSString *DebugNotificationMotionStart;
extern BOOL *DebugKeyMotionIsRunning;
extern LGDebugConfig *LGDebugConfigObj;

@implementation UIWindow (LGDebug)

#if DEBUG

//默认是NO，所以得重写此方法，设成YES
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (DebugKeyMotionIsRunning) {
        return ;
    }
    NSLog(@"结束摇动");
    motionCount++;
    if (motionCount == LGDebugConfigObj.wobbleCount) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);//振动效果
        NSLog(@"开启调试模式");
        motionCount = 0;
        [[NSNotificationCenter defaultCenter]
         postNotificationName:LGDebugNotificationMessage object:self userInfo:@{DebugNotificationMessageType:DebugNotificationMotionStart}];
    }
}

#endif

@end
