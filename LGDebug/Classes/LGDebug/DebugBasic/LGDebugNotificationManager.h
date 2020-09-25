//
//  LGDebugNotificationManager.h
//  Pods-ZPMDebugger_Example
//
//  Created by lg on 2019/11/13.
//

#import <Foundation/Foundation.h>

@interface LGDebugNotificationManager : NSObject

+ (LGDebugNotificationManager *)shareManager;

- (void)removeNotificationWithObject:(id)object;

- (void)addObserver:(id)object selector:(SEL)sel name:(NSString *)name;


@end
