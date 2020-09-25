//
//  NSObject+LGDebug.m
//  Pods
//
//  Created by iBlock on 16/9/5.
//
//

#import "NSObject+LGDebug.h"
#import <objc/runtime.h>
#import "NSObject+LGDebugModel.h"

@implementation NSObject (LGDebug)

- (id)LGDebug_defaultValue:(id)defaultData
{
    if (![defaultData isKindOfClass:[self class]]) {
        return defaultData;
    }
    
    if ([self LGDebug_isEmptyObject]) {
        return defaultData;
    }
    
    return self;
}

- (BOOL)LGDebug_isEmptyObject
{
    if ([self isEqual:[NSNull null]]) {
        return YES;
    }
    
    if ([self isKindOfClass:[NSString class]]) {
        if ([(NSString *)self length] == 0) {
            return YES;
        }
    }
    
    if ([self isKindOfClass:[NSArray class]]) {
        if ([(NSArray *)self count] == 0) {
            return YES;
        }
    }
    
    if ([self isKindOfClass:[NSDictionary class]]) {
        if ([(NSDictionary *)self count] == 0) {
            return YES;
        }
    }
    
    return NO;
}

+ (NSDictionary *)LGDebug_dictionaryOfModel:(id)model {
    Class class = [model class];
    NSDictionary *dic = [model traverseSuperClassIvarsOfClass:class ivars:[model allIvars:[model class]]];
    NSMutableDictionary *debugDic = @{}.mutableCopy;
    for (NSString *key in [dic allKeys]) {
        if ([key hasPrefix:@"_"]) {
            id value = dic[key];
            NSString *ivarKey = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
            debugDic[ivarKey] = value;
        }
    }
    return debugDic;
}

+ (SEL)LGDebug_creatGetterWithPropertyName: (NSString *) propertyName{
    //1.返回get方法: oc中的get方法就是属性的本身
    return NSSelectorFromString(propertyName);
}

/** 获取Invocation返回值 */
+ (id)LGDebug_returnPropertyValueWithSig:(NSMethodSignature *)signature
                              invocation:(NSInvocation *)invocation {
    //获取返回值类型
    const char * returnValueType = signature.methodReturnType;
    //如果没有返回值，也就是消息声明为void，那么returnValue ＝ nil
    if (!strcmp(returnValueType, @encode(void))) {
        id __unsafe_unretained returnValue = nil;
        returnValue = nil;
        return returnValue;
    }else if (!strcmp(returnValueType, @encode(id))){
        //如果返回值为对象，那么为变量赋值
        id __unsafe_unretained returnValue = nil;
        [invocation getReturnValue:&returnValue];
        return returnValue;
    }else {
        //如果返回值为普通类型，如NSInteger， NSUInteger ，BOOL等
        id returnValue = nil;
        //首先获取返回值长度
        NSUInteger returnValueLenth4 = signature.methodReturnLength;
        //根据长度申请内存
        void * retValue4 = (void *)malloc(returnValueLenth4);
        //为retValue赋值
        [invocation getReturnValue:retValue4];
        if (!strcmp(returnValueType, @encode(BOOL))) {
            returnValue = [NSNumber numberWithBool:*((BOOL *)retValue4)];
        }else if (!strcmp(returnValueType, @encode(NSInteger))){
            returnValue = [NSNumber numberWithInteger:*((NSInteger *) retValue4)];
        }else if (!strcmp(returnValueType, @encode(int)))
            returnValue = [NSNumber numberWithInt:*((int *) retValue4)];
        return returnValue;
    }
}


+ (NSSet *)LGDebug_propertyKeysWithModel:(id)model {
    NSMutableSet *keys = [NSMutableSet set];
    [self LGDebug_enumeratePropertiesUsingBlock:^(objc_property_t property, BOOL *stop) {
        NSString *key = @(property_getName(property));
        [keys addObject:key];
    } model:model];
    return keys;
}

+ (void)LGDebug_enumeratePropertiesUsingBlock:(void (^)(objc_property_t property, BOOL *stop))block
                                        model:(id)model {
    Class cls = [model class];
    BOOL stop = NO;
    unsigned count = 0;
    objc_property_t *properties = class_copyPropertyList(cls, &count);
    cls = cls.superclass;
    if (properties == NULL) return;
    for (unsigned i = 0; i < count; i++) {
        block(properties[i], &stop);
        if (stop) break;
    }
    free(properties);
}

/** 获取所有的ivar变量 */
- (NSDictionary *)allIvars:(Class)class {
    unsigned int count = 0;
    Ivar *ivar = class_copyIvarList(class, &count);
    NSMutableDictionary *resultDict = [@{} mutableCopy];
    for (NSUInteger i = 0 ;i < count;i++) {
        const char *ivarName = ivar_getName(ivar[i]);
        const char *ivarType = ivar_getTypeEncoding(ivar[i]);
        NSString *name = [NSString stringWithUTF8String:ivarName];
        NSString *type = [NSString stringWithUTF8String:ivarType];
        //如果是结构体、block、Delegate则跳过
        if ([type hasPrefix:@"{"] ||
            [type isEqualToString:@"@?"] ||
            [type hasPrefix:@"@\"<"]) {
            continue ;
        }
        
        @try {
            id valueName = [self valueForKey:name];
            if (valueName) {
                resultDict[name] = valueName;
            }
        } @catch (NSException *exception) {
            NSLog(@"转换%@出错了，错误：%@",name,exception);
        }
    }
    free(ivar);
    return resultDict;
}

- (NSDictionary *)traverseSuperClassIvarsOfClass:(Class)class
                                           ivars:(NSMutableDictionary *)superIvars {
    NSString *superClassName = NSStringFromClass(class.superclass);
    //如果父类是如下其中一个，则证明是根父类了，返回结果
    NSArray *classNameList = @[@"UITabBarController",@"UITableViewController",@"UICollectionViewController",
                               @"UINavigationController",@"UIViewController"];
    if ([classNameList containsObject:superClassName]) {
        return superIvars;
    } else {
        NSDictionary *ivars = [self allIvars:class.superclass];
        [superIvars addEntriesFromDictionary:ivars];
        [self traverseSuperClassIvarsOfClass:class.superclass ivars:superIvars];
    }
    
    return superIvars;
}

#pragma mark - 自动归档

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [self LGDebug_modelEncodeWithCoder:aCoder];
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    return [self LGDebug_modelInitWithCoder:aDecoder];
}

@end
