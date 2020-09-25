//
//  LGDebugConfig.h
//  LGDebug
//
//  Created by lg on 2019/7/11.
//

#import <Foundation/Foundation.h>


@interface LGDebugConfig : NSObject

/** 自定义配置文件bundle名称 */
@property (nonatomic, strong) NSString *configBundleFileName;
/** 触发Debug模式的晃动次数设置,默认1次 */
@property (nonatomic) int wobbleCount;

@end

