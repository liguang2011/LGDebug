//
//  LGDebugAPIAlarmInfoPage.m
//  Pods
//
//  Created by iBlock on 16/9/1.
//
//

#import "LGDebugAPIAlarmInfoPage.h"
#import "IASKSpecifier.h"
#import "LGDebugApiDetailPage.h"

NSString *const kLGDebugAPISwitchState = @"kLGDebugAPISwitchState";

@interface LGDebugAPIAlarmInfoPage ()<UITableViewDelegate,UITableViewDataSource>

@end

@implementation LGDebugAPIAlarmInfoPage

#pragma mark - Life Cycle

- (instancetype)initWithFile:(NSString*)file key:(IASKSpecifier*)specifier
{
    self = [super init];
    if (self) {
        self.title = specifier.title;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.apiInfoTableVeiw];
    [self.apiInfoTableVeiw reloadData];
    UIBarButtonItem *rightBarItem =
    [[UIBarButtonItem alloc] initWithTitle:@"清空" style:UIBarButtonItemStylePlain
                                    target:self action:@selector(onClickedCleanbtn)];
    self.navigationItem.rightBarButtonItem = rightBarItem;
}

- (void)viewWillAppear:(BOOL)animated {
    BOOL switchState = [[[NSUserDefaults standardUserDefaults] objectForKey:kLGDebugAPISwitchState] boolValue];
    [self.switchView setOn:switchState animated:YES];
    [self switchValueChange:self.switchView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDelegate

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return self.tableHeaderView;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.errorApiAllKeys count] == 0) {
        NSString *title = [self getDefaultCellTitle];
        cell.textLabel.text = title;
        cell.detailTextLabel.text = @"";
    } else {
        [self configCell:cell atindex:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.errorApiAllKeys.count > 0) {
        NSString *apiKey = self.errorApiAllKeys[indexPath.row];
        LGDebugApiDetailPage *apiDetailPage = [[LGDebugApiDetailPage alloc] init];
        apiDetailPage.apiErrorList = self.debugProtocol.errorApiList[apiKey];
        [self.navigationController pushViewController:apiDetailPage animated:YES];
    }
}

#pragma mark - UITableViewDataSource

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.errorApiAllKeys.count < 1) {
        return UITableViewCellEditingStyleNone;
    }
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSString *apiKey = self.errorApiAllKeys[indexPath.row];
        [self.debugProtocol.errorApiList removeObjectForKey:apiKey];
        [self.debugProtocol syncUserdefault];
        [tableView reloadData];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"删除";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = self.errorApiAllKeys.count == 0 ? 1 : self.errorApiAllKeys.count;
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

#pragma mark - Event and Respone

- (void)switchValueChange:(UISwitch *)switchView {
    [[NSUserDefaults standardUserDefaults] setValue:@(switchView.on) forKey:kLGDebugAPISwitchState];
    [LGDebugURLProtocol updateURLProtocol];
}

- (void)onClickedCleanbtn {
    [self.debugProtocol.errorApiList removeAllObjects];
    [self.debugProtocol syncUserdefault];
    [self.apiInfoTableVeiw reloadData];
}

#pragma mark - Setter and Getter

- (UITableView *)apiInfoTableVeiw {
    if (!_apiInfoTableVeiw) {
        _apiInfoTableVeiw = [[UITableView alloc] init];
        _apiInfoTableVeiw.frame = self.view.bounds;
        _apiInfoTableVeiw.delegate = self;
        _apiInfoTableVeiw.dataSource = self;
        _apiInfoTableVeiw.sectionHeaderHeight = [self getTableHeaderHeight];
        UIView *headView = [[UIView alloc] initWithFrame:CGRectZero];
        [_apiInfoTableVeiw setTableFooterView:headView];
    }
    return _apiInfoTableVeiw;
}

- (UILabel *)switchInfoLabel {
    if (!_switchInfoLabel) {
        _switchInfoLabel = [[UILabel alloc] init];
        _switchInfoLabel.numberOfLines = 0;
        _switchInfoLabel.font = [UIFont systemFontOfSize:16];
        _switchInfoLabel.frame = CGRectMake(CGRectGetMaxX(self.switchView.frame)+5, 5, CGRectGetWidth(self.view.frame)-CGRectGetWidth(self.switchView.frame)-20, 44);
        _switchInfoLabel.text = @"开启API错误报警后，所有失败的请求都会在下面列表中显示。";
    }
    return _switchInfoLabel;
}

- (UISwitch *)switchView {
    if (!_switchView) {
        _switchView = [[UISwitch alloc] init];
        _switchView.frame = CGRectMake(10, 10, 100, 20);
        [_switchView addTarget:self action:@selector(switchValueChange:) forControlEvents:UIControlEventValueChanged];
    }
    return _switchView;
}

- (UIView *)tableHeaderView {
    if (!_tableHeaderView) {
        _tableHeaderView = [[UIView alloc] init];
        _tableHeaderView.backgroundColor = [UIColor whiteColor];
        [_tableHeaderView addSubview:self.switchView];
        [_tableHeaderView addSubview:self.switchInfoLabel];
        /*
         UILabel *noticeLabel = [[UILabel alloc] init];
         noticeLabel.font = [UIFont systemFontOfSize:12];
         noticeLabel.text = @"注意：每次开关变更后需要重新打开APP才会生效";
         noticeLabel.textColor = [UIColor redColor];
         noticeLabel.frame = CGRectMake(15, CGRectGetMaxY(self.switchView.frame)+5, CGRectGetWidth(self.view.frame)-15, 15);
         [_tableHeaderView addSubview:noticeLabel];
         */
        UIView *lineView = [[UIView alloc] init];
        lineView.backgroundColor = [UIColor lightGrayColor];
        lineView.frame = CGRectMake(15, [self getTableHeaderHeight]-0.5, CGRectGetWidth(self.view.frame)-15, 0.5);
        [_tableHeaderView addSubview:lineView];
    }
    return _tableHeaderView;
}

- (LGDebugProtocolModel *)debugProtocol {
    if (!_debugProtocol) {
        _debugProtocol = [LGDebugProtocolModel shareInstance];
    }
    return _debugProtocol;
}

- (CGFloat)getTableHeaderHeight {
    return 55;
}

- (void)configCell:(UITableViewCell *)cell atindex:(NSIndexPath *)indexPath {
    NSString *apiKey = self.errorApiAllKeys[indexPath.row];
    NSDictionary *apiInfo = [self.debugProtocol.errorApiList[apiKey] firstObject];
    cell.textLabel.text = apiInfo[@"path"];
    cell.detailTextLabel.textColor = [UIColor redColor];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld",
                                 [self.debugProtocol.errorApiList[apiKey] count]];
}

- (NSString *)getDefaultCellTitle {
    return @"暂时还没有错误的API请求记录。";
}

- (NSArray *)errorApiAllKeys {
    return self.debugProtocol.errorApiList.allKeys;
}

@end
