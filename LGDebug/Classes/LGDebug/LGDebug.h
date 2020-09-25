//
//  LGDebug.h
//  LGDebug
//
//  Created by lg on 2019/7/11.
//

#import <Foundation/Foundation.h>
#import "LGDebugConfig.h"
#import "LGDebugSettingsBaseViewController.h"



@protocol LGDebugProtocol <NSObject>
@optional

/**
 该方法用于Native页面跳转
 如果跳转的ViewController需要自定义构造函数或者自定义参数，则在该VC中实现以下方法
 例如：
 - (id)LGDebugViewController {
 UIViewController *vc = [[UIViewController alloc] init];
 vc.title = @"自定义标题";
 vc.xxx = xxx;
 vc.backColor = [UIColor redColor];
 return vc;
 }
 */
- (id)LGDebugViewController;

/**
 如需使用自定义webView进行H5页面跳转，可通过以下几个步骤实现：
 1、新建NSObject的 Category 类别，实现下面的LGDebugWebViewController方法
 2、在LGDebugWebViewController方法中返回自定义的 WebView 即可
 */
+ (id)LGDebugWebViewController:(NSString *)customTitle url:(NSString *)url;

/** 当 plist 自定义设置项中的设置发生变更时会回调该方法,
 目前只抛回了 key，可通过该 key 获取最新的值，没有将旧值返回
 */
+ (void)LGDebugSettingsChangeNotification:(NSString *)key;

/**
 下面方法用于plist自定义设置项中的按钮点击事件回调
 该监听事件方法也可以在 NSObject 的 Category 类别中实现
 通过 key 值可从 NSUserDefault 中取出相应的值
 例如：
 if ([key isEqualToString:@"SYServiceIpRadioGroup"]) {
 NSString *service = [[NSUserDefaults standardUserDefaults] objectForKey:key];
 }
 */
+ (void)LGDebugButtonClickNotification:(NSString *)key;

/** Debug 模式启动时回调 */
+ (void)LGDebugStartNotification;

/** Debug 模式关闭时回调 */
+ (void)LGDebugStopNotification;

@end
@interface LGDebug : NSObject

+ (LGDebug *)shareInstance;

/**
 *  Debug 组件初始化，使用默认的 LGDebugConfig 配置
 */
+ (void)initService;

/**
 *  Debug 组件初始化，使用指定的配置文件
 *
 *  @param config 配置信息
 */
+ (void)initWithConfig:(LGDebugConfig *)config;

/**
 *  Debug模式是否在运行
 *
 *  @return 返回 YES 表示组件正在运行
 */
+ (BOOL)isDebugRunning;

/// 隐藏主界面
+ (void)dismiss;

/// 隐藏debug按钮
+ (void)close;

/// 显示debug按钮
+ (void)start;

@end
