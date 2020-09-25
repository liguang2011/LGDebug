//
//  LGDebugCustomSettingViewController.m
//  LGDebug
//
//  Created by lg on 2019/7/11.
//

#import "LGDebugCustomSettingViewController.h"
#import "LGDebugConfig.h"

extern LGDebugConfig *LGDebugConfigObj;

@interface LGDebugCustomSettingViewController ()<IASKSettingsDelegate>

@end

@implementation LGDebugCustomSettingViewController

- (id)initWithFile:(NSString*)file specifier:(IASKSpecifier*)specifier{
    self = [self init];
    if (self) {
        self.neverShowPrivacySettings = NO;
        if (LGDebugConfigObj.configBundleFileName) {
            self.file = LGDebugConfigObj.configBundleFileName;
        } else {
            UILabel *label = [[UILabel alloc] init];
            label.text = @"项目中还没配有自定义设置项哦，请查看Demo工程中的配置例子。";
            label.font = [UIFont systemFontOfSize:26];
            label.numberOfLines = 0;
            label.frame = CGRectMake(20, 20, self.view.frame.size.width-40, 200);
            [self.view addSubview:label];
        }
    }
    return self;
}

- (NSString *)bundleName {
    return [NSString stringWithFormat:@"%@.bundle",LGDebugConfigObj.configBundleFileName];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"自定义设置";
}

@end
