//
//  LGDebugImageAlarmInfoPage.m
//  Pods
//
//  Created by iBlock on 2017/2/27.
//
//

#import "LGDebugImageAlarmInfoPage.h"
#import "IASKSpecifier.h"
#import "LGDebugURLProtocol.h"
#import "LGDebugImageApiDetailPage.h"

@interface LGDebugImageAlarmInfoPage ()

@property (nonatomic, strong) UITextField *imageSizeField;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UIButton *confirmButton;

@end

extern NSString *const kLGDebugAPISwitchState;
NSString *const kLGDebugImageSwitchState = @"kLGDebugImageSwitchState";
NSString *const kLGDebugImageSize = @"kLGDebugImageSize";

@implementation LGDebugImageAlarmInfoPage

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self prepareUI];
}

- (void)viewWillAppear:(BOOL)animated {
    BOOL switchState = [[[NSUserDefaults standardUserDefaults] objectForKey:kLGDebugImageSwitchState] boolValue];
    [self.switchView setOn:switchState animated:YES];
    [self switchValueChange:self.switchView];
    
    NSString *imageSizeStr = [[NSUserDefaults standardUserDefaults] objectForKey:kLGDebugImageSize];
    if (imageSizeStr) {
        self.infoLabel.text = [NSString stringWithFormat:@"%@kb",imageSizeStr];
    } else {
        self.infoLabel.text = @"10kb";
        [[NSUserDefaults standardUserDefaults] setValue:@"10" forKey:kLGDebugImageSize];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.imageSizeField resignFirstResponder];
}

- (void)prepareUI {
    self.switchInfoLabel.text = @"开启图片报警后，所有大于指定阀值的图片都会在下面列表中显示。";
    [self.tableHeaderView addSubview:self.infoLabel];
    [self.tableHeaderView addSubview:self.imageSizeField];
    [self.tableHeaderView addSubview:self.confirmButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Event and Respone

- (void)switchValueChange:(UISwitch *)switchView {
    [[NSUserDefaults standardUserDefaults] setValue:@(switchView.on) forKey:kLGDebugImageSwitchState];
    if (switchView.on) {
        [[NSUserDefaults standardUserDefaults] setValue:@(YES) forKey:kLGDebugAPISwitchState];
        [LGDebugURLProtocol updateURLProtocol];
    }
}

- (void)syncUserfault {
    if (self.imageSizeField.text.length > 0) {
        [[NSUserDefaults standardUserDefaults] setValue:self.imageSizeField.text forKey:kLGDebugImageSize];
        self.infoLabel.text = self.infoLabel.text = [NSString stringWithFormat:@"%@kb",self.imageSizeField.text];
    }
    [self.imageSizeField resignFirstResponder];
}

#pragma mark - UITableViewDelegate

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return self.tableHeaderView;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSString *apiKey = self.errorApiAllKeys[indexPath.row];
        [self.debugProtocol.errorImageList removeObjectForKey:apiKey];
        [self.debugProtocol syncUserdefault];
        [tableView reloadData];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.errorApiAllKeys.count > 0) {
        NSString *apiKey = self.errorApiAllKeys[indexPath.row];
        NSDictionary *dic = self.debugProtocol.errorImageList[apiKey];
        LGDebugImageApiDetailPage *detailPage = [[LGDebugImageApiDetailPage alloc] init];
        detailPage.imgDic = dic;
        [self.navigationController pushViewController:detailPage animated:YES];
    }
}

- (UITextField *)imageSizeField  {
    if (!_imageSizeField) {
        _imageSizeField = [[UITextField alloc] init];
        _imageSizeField.placeholder = @"设置图片大小上限阀值";
        _imageSizeField.layer.borderWidth = 0.5;
        _imageSizeField.layer.borderColor = [UIColor grayColor].CGColor;
        _imageSizeField.layer.cornerRadius = 10;
        _imageSizeField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
        _imageSizeField.leftViewMode = UITextFieldViewModeAlways;
        _imageSizeField.keyboardType = UIKeyboardTypeNumberPad;
        _imageSizeField.returnKeyType = UIReturnKeyDone;
        _imageSizeField.font = [UIFont systemFontOfSize:12];
        CGFloat x = CGRectGetMaxX(self.switchView.frame)+5;
        CGFloat y = CGRectGetMaxY(self.switchInfoLabel.frame)+5;
        _imageSizeField.frame = CGRectMake(x, y, 200, 30);
    }
    return  _imageSizeField;
}

- (UILabel *)infoLabel {
    if (!_infoLabel) {
        _infoLabel = [[UILabel alloc] init];
        _infoLabel.textColor = [UIColor grayColor];
        _infoLabel.font = [UIFont systemFontOfSize:12];
        _infoLabel.adjustsFontSizeToFitWidth = YES;
        _infoLabel.textAlignment = NSTextAlignmentLeft;
        _infoLabel.frame = CGRectMake(10, CGRectGetMaxY(self.switchInfoLabel.frame)+5, 100, 30);
    }
    return _infoLabel;
}

- (UIButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_confirmButton setTitle:@"确认" forState:UIControlStateNormal];
        [_confirmButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_confirmButton addTarget:self action:@selector(syncUserfault) forControlEvents:UIControlEventTouchUpInside];
        _confirmButton.frame = CGRectMake(CGRectGetMaxX(self.imageSizeField.frame)+5, CGRectGetMaxY(self.switchInfoLabel.frame)+5, 100, 30);
    }
    return _confirmButton;
}

- (void)onClickedCleanbtn {
    [self.debugProtocol.errorImageList removeAllObjects];
    [self.debugProtocol syncUserdefault];
    [self.apiInfoTableVeiw reloadData];
}

- (NSArray *)errorApiAllKeys {
    NSArray *allKeys = [self.debugProtocol.errorImageList keysSortedByValueUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        NSInteger length1 = [obj1[@"data"] length];
        NSInteger length2 = [obj2[@"data"] length];
        if (length1 < length2 ) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        if (length1 > length2) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        return (NSComparisonResult)NSOrderedSame;
    }];
    return allKeys;
}

- (void)configCell:(UITableViewCell *)cell atindex:(NSIndexPath *)indexPath {
    NSString *apiKey = self.errorApiAllKeys[indexPath.row];
    NSDictionary *apiInfo = self.debugProtocol.errorImageList[apiKey];
    cell.textLabel.text = apiKey;
    cell.detailTextLabel.textColor = [UIColor redColor];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",apiInfo[@"size"]];
}

- (NSString *)getDefaultCellTitle {
    return @"暂时还没有发现超过阀值大小的图片。";
}

- (CGFloat)getTableHeaderHeight {
    return 100;
}

@end
