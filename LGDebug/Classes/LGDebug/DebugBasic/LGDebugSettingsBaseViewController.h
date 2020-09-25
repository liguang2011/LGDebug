//
//  LGDebugSettingsBaseViewController.h
//  LGDebug
//
//  Created by lg on 2019/7/11.
//

#import <UIKit/UIKit.h>
#import "IASKAppSettingsViewController.h"

@protocol LGDebugSettingsBaseFileSettings<NSObject>
//设置bundle的名称
@optional
- (NSString*)bundleName;

@end
@interface LGDebugSettingsBaseViewController : IASKAppSettingsViewController<LGDebugSettingsBaseFileSettings>

- (id)initWithFile:(NSString*)file specifier:(IASKSpecifier*)specifier;

@end



