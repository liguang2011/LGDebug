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
#import "LGDebugWebVC.h"

@interface LGDebugWebViewController ()<IASKSettingsDelegate,LGDebugProtocol>

@property (nonatomic, strong) LGDebugWebVC *webViewController;

@end


@implementation LGDebugWebViewController

- (id)initWithFile:(NSString*)file specifier:(IASKSpecifier*)specifier{
    self = [self init];
    if (self) {
        self.delegate = self;
        self.file = file;
    }
    return self;
}

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
        } else {
            self.webViewController = [[LGDebugWebVC alloc] initWithUrl:webUrl title:customTitle];
        }
        UINavigationController *customNavi = (UINavigationController *)[UIApplication sharedApplication].windows[0].rootViewController;
        if ([customNavi isKindOfClass:[UINavigationController class]]) {
            [customNavi pushViewController:self.webViewController animated:YES];
            [LGDebug dismiss];
        } else {
            [self.navigationController pushViewController:self.webViewController animated:YES];
        }
    }
}

#pragma mark - Setter and Getter

/** 必须这么设置这个 delegate，否则IASKSettingsDelegate回调不到该类 */
- (id)delegate {
    return self;
}

@end
