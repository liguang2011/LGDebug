//
//  LGDebugSettingsBaseViewController.m
//  LGDebug
//
//  Created by lg on 2019/7/11.
//

#import <UIKit/UIKit.h>
#import "LGDebugSettingsBaseViewController.h"
#import "IASKSettingsReader.h"
#import "FLEXManager.h"
#import "LGDebug.h"
#import "IASKTextField.h"
#import "LGDebugClearCacheTool.h"
#import "IASKSettingsStoreUserDefaults.h"

#pragma mark - LGDebugSettingsReader

@interface LGDebugSettingsReader : IASKSettingsReader
@property(nonatomic,weak)LGDebugSettingsBaseViewController* vc;
@end

@implementation LGDebugSettingsReader
@synthesize applicationBundle = _applicationBundle;
@synthesize settingsDictionary = _settingsDictionary;
@synthesize settingsBundle = _settingsBundle;

- (id)initWithFile:(NSString*)fileName
        settingsvc:(LGDebugSettingsBaseViewController*)settingsvc{
    self = [super init];
    if(self){
        self.vc = settingsvc;
        _applicationBundle = [NSBundle mainBundle];
        NSString* plistFilePath = [self locateSettingsFile: fileName];
        _settingsDictionary = [NSDictionary dictionaryWithContentsOfFile:plistFilePath];
        NSString* settingsBundlePath = [plistFilePath stringByDeletingLastPathComponent];
        _settingsBundle = [NSBundle bundleWithPath:settingsBundlePath];
        self.localizationTable = [_settingsDictionary objectForKey:@"StringsTable"];
        if (!self.localizationTable)
        {
            self.localizationTable = [[[[plistFilePath stringByDeletingPathExtension] // removes '.plist'
                                        stringByDeletingPathExtension] // removes potential '.inApp'
                                       lastPathComponent] // strip absolute path
                                      stringByReplacingOccurrencesOfString:[self platformSuffixForInterfaceIdiom:UI_USER_INTERFACE_IDIOM()] withString:@""]; // removes potential '~device' (~ipad, ~iphone)
            if([self.settingsBundle pathForResource:self.localizationTable ofType:@"strings"] == nil){
                // Could not find the specified localization: use default
                self.localizationTable = @"Root";
            }
        }
        self.showPrivacySettings = NO;
        IASK_IF_IOS8_OR_GREATER
        (
         NSArray *privacyRelatedInfoPlistKeys = @[@"NSBluetoothPeripheralUsageDescription", @"NSCalendarsUsageDescription", @"NSCameraUsageDescription", @"NSContactsUsageDescription", @"NSLocationAlwaysUsageDescription", @"NSLocationUsageDescription", @"NSLocationWhenInUseUsageDescription", @"NSMicrophoneUsageDescription", @"NSMotionUsageDescription", @"NSPhotoLibraryUsageDescription", @"NSRemindersUsageDescription", @"NSHealthShareUsageDescription", @"NSHealthUpdateUsageDescription"];
         NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
         if ([fileName isEqualToString:@"Root"]) {
             for (NSString* key in privacyRelatedInfoPlistKeys) {
                 if (infoDictionary[key]) {
                     self.showPrivacySettings = YES;
                     break;
                 }
             }
         }
         );
        if (self.settingsDictionary) {
            SEL sel = NSSelectorFromString(@"_reinterpretBundle:");
            if([self respondsToSelector:sel]){
                [self performSelector:sel withObject:self.settingsDictionary];
            }
        }
    }
    
    return self;
}

- (NSString *)locateSettingsFile: (NSString *)file {
    static NSString* const kIASKBundleFolder = @"Settings.bundle";
    static NSString* const kIASKBundleFolderAlt = @"InAppSettings.bundle";
    static NSString* const kIASKBundleLocaleFolderExtension = @".lproj";
    NSArray *settingsBundleNames = @[kIASKBundleFolderAlt, kIASKBundleFolder];
    NSArray *extensions = @[@".inApp.plist", @".plist"];
    if([self.vc respondsToSelector:@selector(bundleName)]){
        NSString* name = [self.vc bundleName];
        if(name!=nil){
            settingsBundleNames = @[name];
        }
    }
    
    NSArray *plattformSuffixes = @[[self platformSuffixForInterfaceIdiom:UI_USER_INTERFACE_IDIOM()],
                                   @""];
    
    NSArray *preferredLanguages = [NSLocale preferredLanguages];
    NSArray *languageFolders = @[[ (preferredLanguages.count ? [preferredLanguages objectAtIndex:0] : @"en") stringByAppendingString:kIASKBundleLocaleFolderExtension],
                                 @""];
    
    
    NSString *path = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    for (NSString *settingsBundleName in settingsBundleNames) {
        for (NSString *extension in extensions) {
            for (NSString *platformSuffix in plattformSuffixes) {
                for (NSString *languageFolder in languageFolders) {
                    path = [self file:file
                           withBundle:[settingsBundleName stringByAppendingPathComponent:languageFolder]
                               suffix:platformSuffix
                            extension:extension];
                    if ([fileManager fileExistsAtPath:path]) {
                        goto exitFromNestedLoop;
                    }
                }
            }
        }
    }
    
exitFromNestedLoop:
    return path;
}

@end

#pragma mark - LGDebugSettingsBaseViewController

extern NSString *DebugNotificationMessageType;
extern NSString *DebugNotificationMotionStop;
extern NSString *LGDebugNotificationMessage;
extern NSString *DebugNotificationCloseConfigWindow;

@interface LGDebugSettingsBaseViewController ()<IASKSettingsDelegate,LGDebugProtocol>{
    LGDebugSettingsReader *_MysettingsReader;
}

@end

@implementation LGDebugSettingsBaseViewController
@synthesize settingsStore = _MySettingsStore;

#pragma mark - Life Cycle

- (id)initWithFile:(NSString*)file specifier:(IASKSpecifier*)specifier{
    self = [self init];
    if (self) {
        self.delegate = self;
        self.file = file;
        self.title = specifier.key;
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
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doAppSettingChanged:) name:kIASKAppSettingChanged object:nil];
            self.neverShowPrivacySettings = YES;
        });
    }
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.showDoneButton = NO;
    self.showCreditsFooter = NO;
    
}

#pragma mark - IASKSettingsDelegate

- (void)settingsViewController:(IASKAppSettingsViewController*)sender buttonTappedForSpecifier:(IASKSpecifier*)specifier {
    if ([specifier.key isEqualToString:@"LGDebugCloseDebug"]) {
        [[FLEXManager sharedManager] hideExplorer];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:LGDebugNotificationMessage object:self userInfo:@{DebugNotificationMessageType:DebugNotificationMotionStop}];
    } else if ([specifier.key isEqualToString:@"LGDebugFlexTools"]) {
        [[FLEXManager sharedManager] showExplorer];
        [[NSNotificationCenter defaultCenter] postNotificationName:LGDebugNotificationMessage object:self userInfo:@{DebugNotificationMessageType:DebugNotificationCloseConfigWindow}];
    } else if ([specifier.key isEqualToString:@"LGDebugMemoryWarning"]) {
        SEL memoryWarningSel = @selector(_performMemoryWarning);
        if ([[UIApplication sharedApplication] respondsToSelector:memoryWarningSel]) {
            [[UIApplication sharedApplication] performSelector:memoryWarningSel];
        }else {
            NSLog(@"%@",@"Whoops UIApplication no loger responds to -_performMemoryWarning");
        }
    } else if ([specifier.key isEqualToString:@"LGDebugCleanCache"]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"清空缓存" message:@"将会删除APP沙盒目录中的Documents、Library、tmp文件夹，清空后最好重启下APP，否则可能会造成部分功能异常，确认清空吗？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
        [alertView show];
        [[NSNotificationCenter defaultCenter] postNotificationName:LGDebugNotificationMessage object:self userInfo:@{DebugNotificationMessageType:DebugNotificationCloseConfigWindow}];
    }
    
    if ([LGDebugSettingsBaseViewController respondsToSelector:@selector(LGDebugButtonClickNotification:)]) {
        [LGDebugSettingsBaseViewController LGDebugButtonClickNotification:specifier.key];
    }
}

#pragma mark - Override UIViewController Method

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - NSNotification kIASKAppSettingChanged

- (void)doAppSettingChanged:(NSNotification *)notify {
    [self performSelectorOnMainThread:@selector(appSettingChanged:) withObject:notify waitUntilDone:[NSThread isMainThread]];
}

- (void)appSettingChanged:(NSNotification *)notify {
    [self synchronizeSettings];
    [self baseSettingChanged:[notify.userInfo allKeys][0]];
    if ([LGDebugSettingsBaseViewController respondsToSelector:@selector(LGDebugSettingsChangeNotification:)]) {
        [LGDebugSettingsBaseViewController LGDebugSettingsChangeNotification:[notify.userInfo allKeys][0]];
    }
}

- (void)baseSettingChanged:(NSString *)key {
//    if ([key isEqualToString:@"SYDebugTrustSSLSwitch"]) {
//        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
//        BOOL isTrustSSL = [[userDefault objectForKey:@"SYDebugTrustSSLSwitch"] boolValue];
//        if (isTrustSSL) {
//            [NSURLRequest openTrustSSL];
//        } else {
//            [NSURLRequest closeTrustSSL];
//        }
//    }
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
    }
}

#pragma mark - Setter and Getter

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
- (void)_textChanged:(id)sender {
    IASKTextField *text = sender;
    [self.settingsStore setObject:[text text] forKey:[text key]];
    [[NSNotificationCenter defaultCenter] postNotificationName:kIASKAppSettingChanged
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:[text text]                         forKey:[text key]]];
}

- (id<IASKSettingsStore>)settingsStore {
    if (!_MySettingsStore) {
        //[NSUserDefaults standardUserDefaults] 类似这种的 要写一个全局能访问到的 存贮值的地方
        _MySettingsStore = [[IASKSettingsStoreUserDefaults alloc] initWithUserDefaults:[NSUserDefaults standardUserDefaults]];
    }
    return _MySettingsStore;
}

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
