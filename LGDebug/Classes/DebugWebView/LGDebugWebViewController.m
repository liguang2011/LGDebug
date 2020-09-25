//
//  LGDebugWebViewController.m
//  Pods
//
//  Created by iBlock on 16/7/30.
//
//

#import "LGDebugWebViewController.h"
#import "IASKAppSettingsWebViewController.h"
#import "LGDebug.h"

@interface LGDebugWebViewController ()<IASKSettingsDelegate,LGDebugProtocol>

@property (nonatomic, strong) UIViewController *webViewController;

@end

extern NSString *LGDebugNotificationMessage;
extern NSString *DebugNotificationMessageType;
extern NSString *DebugNotificationCloseConfigWindow;

@implementation LGDebugWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"H5页面跳转";
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IASKSettingsDelegate

- (void)settingsViewController:(IASKAppSettingsViewController*)sender buttonTappedForSpecifier:(IASKSpecifier*)specifier {
    NSString *customTitle = [self.settingsStore objectForKey:@"LGDebugWebViewTitle"];
    if ([customTitle length] == 0) {
        customTitle = nil;
    }
    NSString *webUrl = [self.settingsStore objectForKey:@"LGDebugWebViewURL"];
    if ([specifier.key isEqualToString:@"LGDebugSystemWebView"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:webUrl]];
    } else if ([specifier.key isEqualToString:@"LGDebugCustomWebView"]) {
        if ([LGDebugWebViewController respondsToSelector:@selector(LGDebugWebViewController:url:)]) {
            self.webViewController = [LGDebugWebViewController LGDebugWebViewController:customTitle url:webUrl];
            UINavigationController *customNavi = [UIApplication sharedApplication].windows[0].rootViewController;
            if ([customNavi isKindOfClass:[UINavigationController class]]) {
                [customNavi pushViewController:self.webViewController animated:YES];
                [[NSNotificationCenter defaultCenter] postNotificationName:LGDebugNotificationMessage object:self userInfo:@{DebugNotificationMessageType:DebugNotificationCloseConfigWindow}];
            } else {
                [self.navigationController pushViewController:self.webViewController animated:YES];
            }
            
        } else {
            UIViewController *tempViewController = [[UIViewController alloc] init];
            UILabel *label = [[UILabel alloc] init];
            label.text = @"项目中还没配有自定义WebViewController哦，请查看Demo工程中的配置例子。";
            label.font = [UIFont systemFontOfSize:26];
            label.numberOfLines = 0;
            label.frame = CGRectMake(20, 20, self.view.frame.size.width-40, 200);
            [tempViewController.view addSubview:label];
            label.center = tempViewController.view.center;
            tempViewController.view.backgroundColor = [UIColor whiteColor];
            [self.navigationController pushViewController:tempViewController animated:YES];
        }
    }
}

#pragma mark - Setter and Getter

/** 必须这么设置这个 delegate，否则IASKSettingsDelegate回调不到该类 */
- (id)delegate {
    return self;
}

@end
