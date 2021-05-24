//
//  LGDebugNotificationManager.m
//  Pods-ZPMDebugger_Example
//
//  Created by lg on 2019/11/13.
//

#import "LGDebugNotificationManager.h"

@interface LGDebugNotificationManager()

{
    NSMutableArray *_notiTokenManager;
}

@end

@implementation LGDebugNotificationManager

+ (LGDebugNotificationManager *)shareManager {
    static LGDebugNotificationManager * manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       manager = [[LGDebugNotificationManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _notiTokenManager = [NSMutableArray array];
    }
    return self;
}



- (void)removeNotificationWithObject:(id)object {
    [_notiTokenManager removeAllObjects];
    [[NSNotificationCenter defaultCenter] removeObserver:object];
}

- (void)addObserver:(id)object selector:(SEL)sel name:(NSString *)name {
    if (![_notiTokenManager containsObject:name]) {
        [[NSNotificationCenter defaultCenter] addObserver:object selector:sel name:name object:nil];
        [_notiTokenManager addObject:name];
    }
}

@end
