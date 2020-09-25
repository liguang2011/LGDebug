//
//  NSObject+LGDebug.h
//  Pods
//
//  Created by iBlock on 16/9/5.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (LGDebug)

- (id)LGDebug_defaultValue:(id)defaultData;

//获取任意对象的属性字典
+ (NSDictionary *)LGDebug_dictionaryOfModel:(id)model;

@end
