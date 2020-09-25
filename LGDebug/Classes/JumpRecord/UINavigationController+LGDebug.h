//
//  UINavigationController+LGDebug.h
//  Pods
//
//  Created by iBlock on 16/9/7.
//
//

#import <UIKit/UIKit.h>

#ifdef DEBUG

@interface UINavigationController (LGDebug)

+ (NSMutableDictionary *)infoDicForLGDebugJumpPage;

@end

#endif
