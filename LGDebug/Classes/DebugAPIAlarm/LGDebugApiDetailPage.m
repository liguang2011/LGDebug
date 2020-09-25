//
//  LGDebugApiDetailPage.m
//  Pods
//
//  Created by iBlock on 16/9/6.
//
//

#import "LGDebugApiDetailPage.h"

@interface LGDebugApiDetailPage ()

@property (nonatomic, strong) UITextView *apiErrorInfoTextView;

@end

@implementation LGDebugApiDetailPage

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.apiErrorInfoTextView];
    [self prepareUI];
}

- (void)prepareUI {
    NSMutableString *logStr = @"".mutableCopy;
    int i = 0;
    for (NSDictionary *logInfo in self.apiErrorList) {
        i++;
        [logStr appendFormat:@"第 %d 个错误     时间:%@%@\n\n\n",i,logInfo[@"time"],logInfo[@"log"]];
    }
    self.apiErrorInfoTextView.text = logStr;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setter and Getter

- (UITextView *)apiErrorInfoTextView {
    if (!_apiErrorInfoTextView) {
        _apiErrorInfoTextView = [[UITextView alloc] init];
        _apiErrorInfoTextView.frame = self.view.bounds;
        _apiErrorInfoTextView.editable = NO;
    }
    return _apiErrorInfoTextView;
}

@end
