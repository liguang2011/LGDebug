//
//  LGDebugImageApiDetailPage.m
//  Pods
//
//  Created by iBlock on 2017/2/28.
//
//

#import "LGDebugImageApiDetailPage.h"

@interface LGDebugImageApiDetailPage ()

@property (nonatomic, strong) UILabel *urlTitle;
@property (nonatomic, strong) UIImageView *image;

@end

@implementation LGDebugImageApiDetailPage

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareUI];
    self.urlTitle.text = _imgDic[@"path"];
    self.image.image = [UIImage imageWithData:_imgDic[@"data"]];
}

- (void)prepareUI {
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.urlTitle];
    [self.view addSubview:self.image];
}

- (UILabel *)urlTitle {
    if (!_urlTitle) {
        _urlTitle = [[UILabel alloc] init];
        _urlTitle.textColor = [UIColor grayColor];
        _urlTitle.numberOfLines = 0;
        _urlTitle.frame = CGRectMake(0, 64, CGRectGetWidth(self.view.frame), 100);
    }
    return _urlTitle;
}

- (UIImageView *)image {
    if (!_image) {
        _image = [[UIImageView alloc] init];
        CGFloat y = CGRectGetMaxY(self.urlTitle.frame)+10;
        _image.frame = CGRectMake(0, y, CGRectGetWidth(self.view.frame), self.view.frame.size.height-y);
    }
    return _image;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
