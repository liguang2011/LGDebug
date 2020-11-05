## 前言
提供与app的debug相关功能，如性能监控体系，模拟页面跳转，各项开关，日志监听等

## 框架
包含自定义UI库和逻辑处理结构
> 通过plist搭建界面树，以协议的形式映射为界面，可自定义添加按钮

## 调用方式

```
    LGDebugConfig *config = [[LGDebugConfig alloc] init];
    config.configBundleFileName = @"LGDebug";
    [LGDebug initWithConfig:config];
```

## 引入方式

LGDebug is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'LGDebug'
```

## 作者

liguang, alan0609@qq.com

## License

LGDebug is available under the MIT license. See the LICENSE file for more info.
