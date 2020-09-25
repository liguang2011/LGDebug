//
//  UINavigationController+LGDebug.m
//  Pods
//
//  Created by iBlock on 16/9/7.
//
//

#ifdef DEBUG

#import "UINavigationController+LGDebug.h"
#import <objc/runtime.h>
#import "NSObject+LGDebug.h"

extern NSString *const kLGDebugPageJumpRecord;
extern NSString *const kLGDebugPageJumpMark;
extern NSString *const kLGDebugPageTitle;
extern NSString *const kLGDebugJumpRecordInfoSwitchState;

static NSMutableDictionary *LGDebugJumpPageInfoDic;

@implementation UINavigationController (LGDebug)

+ (NSMutableDictionary *)infoDicForLGDebugJumpPage {
    return LGDebugJumpPageInfoDic;
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        id switchState = [[NSUserDefaults standardUserDefaults] objectForKey:kLGDebugJumpRecordInfoSwitchState];
        BOOL flag = NO;
        if (switchState) {
            flag = [switchState boolValue];
        } else {
            flag = NO;
            [[NSUserDefaults standardUserDefaults] setObject:@(flag) forKey:kLGDebugJumpRecordInfoSwitchState];
        }
        
        if (flag) {
            Class vcClass = [self class];
            SEL originalSelector = @selector(pushViewController:animated:);
            SEL swizzledSelector = @selector(LGDebug_pushViewController:animated:);
            Method originalMethod = class_getInstanceMethod(vcClass, originalSelector);
            Method swizzledMethod = class_getInstanceMethod(vcClass, swizzledSelector);
            method_exchangeImplementations(originalMethod, swizzledMethod);
            NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:kLGDebugPageJumpRecord];
            LGDebugJumpPageInfoDic = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            if (!LGDebugJumpPageInfoDic) {
                LGDebugJumpPageInfoDic = @{}.mutableCopy;
            }
        }
    });
}

- (void)LGDebug_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self LGDebug_pushViewController:viewController animated:animated];
        if (![viewController.title isEqualToString:kLGDebugPageJumpMark] &&
            ![NSStringFromClass([viewController class]) hasPrefix:@"LGDebug"]) {
            NSMutableDictionary *dic = [UINavigationController LGDebug_dictionaryOfModel:viewController].mutableCopy;
            dic[kLGDebugPageTitle] = viewController.title?:@"没有标题";
            LGDebugJumpPageInfoDic[NSStringFromClass([viewController class])] = dic;
            [self LGDebugJumpPageInfoStore:dic vc:viewController];
        }
}

- (void)LGDebugJumpPageInfoStore:(NSMutableDictionary *)currentPageInfo vc:(UIViewController *)viewController {
    @synchronized (self) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            currentPageInfo[kLGDebugPageTitle] = viewController.title?:@"没有标题";
            LGDebugJumpPageInfoDic[NSStringFromClass([viewController class])] = currentPageInfo;
            NSData *jumpRecordData = [NSKeyedArchiver archivedDataWithRootObject:LGDebugJumpPageInfoDic];
            [[NSUserDefaults standardUserDefaults] setObject:jumpRecordData forKey:kLGDebugPageJumpRecord];
        });
    }
}

@end

#endif
