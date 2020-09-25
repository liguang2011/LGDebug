//
//  LGDebugWebVC.m
//  ZPMDebugger
//
//  Created by lg on 2019/10/15.
//

#import "LGDebugWebVC.h"
#import <WebKit/WebKit.h>

@interface LGDebugWebVC ()

@property (nonatomic, strong) WKWebView *wkWebView;

@property (nonatomic, copy) NSString *url;

//@property (nonatomic, copy) NSString *webTitle;

@end

@implementation LGDebugWebVC

- (instancetype)initWithUrl:(NSString *)url title:(NSString *)title {
    if (self = [super init]) {
        self.url = url;
        self.title = title;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.wkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.url]]];
}

- (WKWebView *)wkWebView {
    if (!_wkWebView) {
        _wkWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        [self.view addSubview:_wkWebView];
    }
    return _wkWebView;
}
@end
