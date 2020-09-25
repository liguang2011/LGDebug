//
//  LGDebugSettingsBaseViewController.m
//  LGDebug
//
//  Created by lg on 2019/7/11.
//

#import <UIKit/UIKit.h>
#import "LGDebugSettingsBaseViewController.h"
#import "IASKSettingsReader.h"
#import "LGDebug.h"
#import "IASKTextField.h"
#import "LGDebugClearCacheTool.h"
#import "IASKSettingsStoreUserDefaults.h"
#import "FHHFPSIndicator.h"

#pragma mark - LGDebugSettingsReader

@interface LGDebugSettingsReader : IASKSettingsReader
@property(nonatomic,weak)LGDebugSettingsBaseViewController* vc;
@end

@implementation LGDebugSettingsReader

@synthesize settingsDictionary = _settingsDictionary;
@synthesize settingsBundle = _settingsBundle;

- (id)initWithFile:(NSString*)fileName
        settingsvc:(LGDebugSettingsBaseViewController*)settingsvc{
    self = [super init];
    if(self){
        self.vc = settingsvc;
        NSString *bundleFilePath;
        NSString *plistFilePath;
        //父类使用
        _settingsBundle = [NSBundle mainBundle];
        //如果自定义文件存在
        if (fileName.length) {
            plistFilePath = [[NSBundle bundleForClass:self.class] pathForResource:fileName ofType :@"plist"];
            //如果pod目录里没有 则走主工程目录
            if (!plistFilePath) {
                plistFilePath = [_settingsBundle pathForResource:fileName ofType:@"plist"];
            }
            //如果主目录里也没有 则走最原始的 LGDebug
            if (!plistFilePath) {
                bundleFilePath = [[NSBundle bundleForClass:self.class] pathForResource:@"LGDebug" ofType :@"bundle"];
                _settingsBundle = [NSBundle bundleWithPath:bundleFilePath];
                plistFilePath = [_settingsBundle pathForResource:fileName ofType:@"plist"];
            }
        }else {
            //不存在则走 LGDebug 配置
            bundleFilePath = [[NSBundle bundleForClass:self.class] pathForResource:@"LGDebug" ofType :@"bundle"];
            _settingsBundle = [NSBundle bundleWithPath:bundleFilePath];
            plistFilePath = [_settingsBundle pathForResource:fileName ofType:@"plist"];
        }
        _settingsDictionary = [NSDictionary dictionaryWithContentsOfFile:plistFilePath];
        
        self.showPrivacySettings = NO;
        if (self.settingsDictionary) {
            SEL sel = NSSelectorFromString(@"reinterpretBundle:");
            if([self respondsToSelector:sel]){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [self performSelector:sel withObject:self.settingsDictionary];
#pragma clang diagnostic pop
            }
        }
    }
    
    return self;
}

@end

#pragma mark - LGDebugSettingsBaseViewController

@interface LGDebugSettingsBaseViewController ()<IASKSettingsDelegate,LGDebugProtocol>{
    LGDebugSettingsReader *_MysettingsReader;
}

@end

@implementation LGDebugSettingsBaseViewController
//@synthesize settingsStore = _MySettingsStore;

#pragma mark - Life Cycle

- (id)initWithFile:(NSString*)file specifier:(IASKSpecifier*)specifier{
    self = [self init];
    if (self) {
        self.delegate = self;
        self.file = file;
        self.title = specifier.title.length?specifier.title:specifier.key;
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (id)init
{
    self = [super init];
    if (self) {
        [[LGDebugNotificationManager shareManager] addObserver:self selector:@selector(doAppSettingChanged:) name:kIASKAppSettingChanged];
        self.neverShowPrivacySettings = YES;
    }
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.showDoneButton = NO;
    self.showCreditsFooter = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
}

#pragma mark - IASKSettingsDelegate

- (void)settingsViewController:(IASKAppSettingsViewController*)sender buttonTappedForSpecifier:(IASKSpecifier*)specifier {
    //关闭
    if ([specifier.key isEqualToString:@"LGDebugCloseDebug"]) {
        [LGDebug close];
    }
    //2D 图像
    if ([specifier.key isEqualToString:@"LGDebugLookin2DTools"]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Lookin_2D" object:nil];
        });
        [LGDebug dismiss];
    }
    //3D 图像
    if ([specifier.key isEqualToString:@"LGDebugLookin3DTools"]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Lookin_3D" object:nil];
        });
        [LGDebug dismiss];
    }
    //导出lookin文档
    if ([specifier.key isEqualToString:@"LGDebugLookinExport"]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Lookin_Export" object:nil];
        });
        [LGDebug dismiss];
    }
    
    //跳转webView
    if ([specifier.key isEqualToString:@"LGDebugH5Jump"]) {
        
    }
//
    
   
    
    if ([LGDebugSettingsBaseViewController respondsToSelector:@selector(LGDebugButtonClickNotification:)]) {
        if ([specifier.key isEqualToString:@"LGDebugCleanCache"]) {
               UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"清空缓存" message:@"将会删除APP沙盒目录中的Documents、Library、tmp文件夹，清空后最好重启下APP，否则可能会造成部分功能异常，确认清空吗？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
               [alertView show];
        }else {
            [LGDebugSettingsBaseViewController LGDebugButtonClickNotification:specifier.key];
            [LGDebug dismiss];
        }
    }
}

- (void)LGDebugSettingsChangeNotification:(NSString *)key {
    //开启帧率监控
    if ([key isEqualToString:@"LGDebugFPSIndicator"]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self touchFPSIndicator];
        });
        [LGDebug dismiss];
    }
}

#pragma mark - NSNotification kIASKAppSettingChanged

- (void)doAppSettingChanged:(NSNotification *)notify {
    [self performSelectorOnMainThread:@selector(appSettingChanged:) withObject:notify waitUntilDone:[NSThread isMainThread]];
}

- (void)appSettingChanged:(NSNotification *)notify {
    [self synchronizeSettings];
    if ([LGDebugSettingsBaseViewController respondsToSelector:@selector(LGDebugSettingsChangeNotification:)]) {
        //传到外部 根据NSObject分类去实现
        [LGDebugSettingsBaseViewController LGDebugSettingsChangeNotification:[notify.userInfo allKeys][0]];
    }
    //传给自己
    [self LGDebugSettingsChangeNotification:[notify.userInfo allKeys][0]];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSString *documentsFile = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *libraryFile = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
        NSString *tmpFile = NSTemporaryDirectory();
        if (documentsFile) {
            [LGDebugClearCacheTool clearCacheWithFilePath:documentsFile];
        }
        if (libraryFile) {
            [LGDebugClearCacheTool clearCacheWithFilePath:libraryFile];
        }
        if (tmpFile) {
            [LGDebugClearCacheTool clearCacheWithFilePath:tmpFile];
        }
        [LGDebug dismiss];
    }
}

#pragma mark - Delegate
- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender {
    
}

#pragma mark - Setter and Getter

- (void)touchFPSIndicator {
    BOOL willShow = [[[NSUserDefaults standardUserDefaults] objectForKey:@"LGDebugFPSIndicator"] boolValue];
    if (willShow) {
        [[FHHFPSIndicator sharedFPSIndicator] show];
        [FHHFPSIndicator sharedFPSIndicator].fpsLabelPosition = FPSIndicatorPositionTopLeft;
    }else {
        [[FHHFPSIndicator sharedFPSIndicator] hide];
    }
}

- (BOOL)isChangeNotification {
    return NO;
}

- (NSString*)bundleName{
    return @"LGDebug.bundle";
}

/** InAppSettingsKit中关于UITextField的变更使用_settingsStore来设置值，
 但是代码跟踪发现_settingsStore是个nil，需要用.属性的方式来访问，不改变
 InAppSettingsKit的原码，这里直接重写该方法来修复这个问题。
 具体的请跟踪查看IASKAppSettingsViewController类的_textChanged方法代码。
 */
//- (void)_textChanged:(id)sender {
//    IASKTextField *text = sender;
//    [self.settingsStore setObject:[text text] forKey:[text key]];
//    [[NSNotificationCenter defaultCenter] postNotificationName:kIASKAppSettingChanged
//                                                        object:self
//                                                      userInfo:[NSDictionary dictionaryWithObject:[text text]                         forKey:[text key]]];
//}
//
//- (id<IASKSettingsStore>)settingsStore {
//    if (!_MySettingsStore) {
//        //[NSUserDefaults standardUserDefaults] 类似这种的 要写一个全局能访问到的 存贮值的地方
//        _MySettingsStore = [[IASKSettingsStoreUserDefaults alloc] initWithUserDefaults:[NSUserDefaults standardUserDefaults]];
//    }
//    return _MySettingsStore;
//}

- (IASKSettingsReader*)settingsReader {
    if (!_MysettingsReader) {
        _MysettingsReader = [[LGDebugSettingsReader alloc] initWithFile:self.file settingsvc:self];
        self.settingsReader = _MysettingsReader;
        if (self.neverShowPrivacySettings) {
            _MysettingsReader.showPrivacySettings = NO;
        }
        
    }
    return _MysettingsReader;
}

@end
