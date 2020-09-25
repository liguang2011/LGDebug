//
//  LGDebugViewControllers.m
//  LGDebug
//
//  Created by lg on 2019/7/11.
//

#import "LGDebugViewControllers.h"
#import "LGDebug.h"
#import <objc/runtime.h>

@interface LGDebugViewControllers ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *controllersTableView;
@property (nonatomic, strong)  NSArray *dataArray;

@end

@implementation LGDebugViewControllers

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Native页面跳转";
    [self.view addSubview:self.controllersTableView];
    [self.controllersTableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *title = self.dataArray[indexPath.section][indexPath.row];
    cell.textLabel.text = title;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *vcName = self.dataArray[indexPath.section][indexPath.row];
    id obj = [[NSClassFromString(vcName) alloc] init];
    UIViewController *viewController = obj;
    if ([obj respondsToSelector:@selector(LGDebugViewController)]) {
        viewController = [obj LGDebugViewController];
    }
    [self.navigationController pushViewController:viewController animated:YES];
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.frame = self.view.frame;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    if (section == 0) {
        titleLabel.text = @"已自定义初始化方法";
    } else {
        titleLabel.text = @"未自定义初始化方法";
    }
    return titleLabel;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.dataArray objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - Setter and Getter

- (UITableView *)controllersTableView {
    if (!_controllersTableView) {
        _controllersTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _controllersTableView.delegate = self;
        _controllersTableView.dataSource = self;
        _controllersTableView.sectionHeaderHeight = 44;
        _controllersTableView.backgroundColor =
        [UIColor colorWithRed:((0xf0f0f0 & 0xFF0000) >> 16) /
         255.0 green:((0xf0f0f0 & 0xFF00) >> 8) /
         255.0 blue:(0xf0f0f0 & 0xFF) /
         255.0 alpha:1.0];
        UIView *headView = [[UIView alloc] initWithFrame:CGRectZero];
        [_controllersTableView setTableFooterView:headView];
    }
    return _controllersTableView;
}

- (NSArray *)dataArray {
    if (!_dataArray) {
        unsigned int classNamesCount = 0;
        const char **classNames = objc_copyClassNamesForImage([[[NSBundle mainBundle] executablePath] UTF8String], &classNamesCount);
        if (classNames) {
            NSMutableArray *respondList = [NSMutableArray array];
            NSMutableArray *unRespondList = [NSMutableArray array];
            for (unsigned int i = 0; i < classNamesCount; i++) {
                const char *className = classNames[i];
                NSString *classNameString = [NSString stringWithUTF8String:className];
                if ([classNameString hasPrefix:@"FLEX"] ||
                    [classNameString hasPrefix:@"IASK"] ||
                    [classNameString hasPrefix:@"LGDebug"]) {
                    continue ;
                }
                Class class = NSClassFromString(classNameString);
                if ([class isSubclassOfClass:[UIViewController class]]) {
                    if ([class instancesRespondToSelector:@selector(LGDebugViewController)]) {
                        [respondList addObject:classNameString];
                    } else {
                        [unRespondList addObject:classNameString];
                    }
                }
            }
            _dataArray = @[respondList, unRespondList];
        }
    }
    return _dataArray;
}

@end
