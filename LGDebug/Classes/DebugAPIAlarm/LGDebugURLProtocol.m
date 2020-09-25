//
//  LGDebugURLProtocol.m
//  SuYun
//
//  Created by iBlock on 16/9/1.
//  Copyright © 2016年 58. All rights reserved.
//

#import "LGDebugURLProtocol.h"
#import <objc/runtime.h>
#import "NSObject+LGDebug.h"

//自定义唯一标示符
static NSString *const LGCustomURLProtocolHandledKey = @"LGCustomURLProtocolHandledKey";
static NSString *const kLGDebugAPIResponse = @"kLGDebugAPIResponse";
static NSString *const kLGDebugAPIResponseString = @"kLGDebugAPIResponseString";
static NSString *const kLGDebugAPIRequest = @"kLGDebugAPIRequest";
static NSString *const kLGDebugAPIResponseData = @"kLGDebugAPIResponseData";
static NSString *const kLGDebugAPIError = @"kLGDebugAPIError";
extern NSString *kLGDebugAPISwitchState;
extern NSString *kLGDebugImageSwitchState;
extern NSString *kLGDebugImageSize;

@interface LGDebugProtocolModel()

@property (nonatomic, strong, readwrite) NSMutableDictionary *errorApiList;
@property (nonatomic, strong, readwrite) NSMutableDictionary *errorImageList;

- (void)syncUserdefault;

@end

@interface LGDebugURLProtocol ()

@property (nonatomic, strong) NSURLConnection *connection;//网络连接对象
@property (nonatomic, strong) NSMutableDictionary *currentRequestInfo;
@property (nonatomic, strong) NSMutableData *apiData;

- (instancetype)initWithBaseURL:(NSURL *)url
           sessionConfiguration:(NSURLSessionConfiguration *)configuration;

@end

@implementation NSURLSessionConfiguration (LGDebug)

static BOOL isSwizzed = NO;
+ (void)swizzedSessionConfig:(BOOL)state {
    Method systemMethod = class_getClassMethod([NSURLSessionConfiguration class], @selector(defaultSessionConfiguration));
    Method zwMethod = class_getClassMethod([LGDebugURLProtocol class], @selector(zw_defaultSessionConfiguration));
    if (state == YES) {
        isSwizzed = YES;
        method_exchangeImplementations(systemMethod, zwMethod);
    } else {
        if (isSwizzed) {
            isSwizzed = NO;
            method_exchangeImplementations(systemMethod, zwMethod);
        }
    }
}

+ (NSURLSessionConfiguration *)zw_defaultSessionConfiguration{
    NSURLSessionConfiguration *configuration = [self zw_defaultSessionConfiguration];
    NSArray *protocolClasses = @[[LGDebugURLProtocol class]];
    configuration.protocolClasses = protocolClasses;
    
    return configuration;
}

@end

@implementation LGDebugURLProtocol

+ (void)updateURLProtocol {
    BOOL state = [[[NSUserDefaults standardUserDefaults] objectForKey:kLGDebugAPISwitchState] boolValue];
    if (state) {
        [NSURLProtocol registerClass:self];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.protocolClasses = @[NSClassFromString(@"LGDebugURLProtocol")];
    } else {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.protocolClasses = nil;
        [NSURLProtocol unregisterClass:self];
    }
    [NSURLSessionConfiguration swizzedSessionConfig:state];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    //如果是非http https就不让他通过
    if (![request.URL.scheme isEqualToString:@"http"] && ![request.URL.scheme isEqualToString:@"https"]) {
        return NO;
    }
    
    //看看是否已经处理过了，防止无限循环，如果已经处理过(即设置了允许通过，就不再初始化了)
    if ([NSURLProtocol propertyForKey:LGCustomURLProtocolHandledKey inRequest:request]) {
        return NO;
    }
    
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    //没有缓存 返回这个新的请求
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    //打标签，防止无限循环
    [NSURLProtocol setProperty:@YES forKey:LGCustomURLProtocolHandledKey inRequest:newRequest];
    self.apiData = nil;
    self.connection = [NSURLConnection connectionWithRequest:newRequest delegate:self];
}

- (void)stopLoading
{
    [self.connection cancel];
    self.connection = nil;
}

#pragma mark - DebugAPILog

- (NSString *)logDebugInfoWithResponse:(NSHTTPURLResponse *)response resposeString:(NSString *)responseString request:(NSURLRequest *)request error:(NSError *)error
{
    BOOL shouldLogError = error ? YES : NO;
    
    NSMutableString *logString = [NSMutableString stringWithString:@"\n\n============================================\n=                        LGDebug API Response                        =\n============================================\n\n"];
    
    [logString appendFormat:@"Status:\t%ld\t(%@)\n\n", (long)response.statusCode, [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode]];
    [logString appendFormat:@"Content:\n\t%@\n", responseString];
    [logString appendFormat:@"Respone Header:\n%@\n\n", response.allHeaderFields ? response.allHeaderFields : @"\t\t\t\t\tN/A"];
    if (shouldLogError) {
        [logString appendFormat:@"Error Domain:\t\t\t\t\t\t\t%@\n", error.domain];
        [logString appendFormat:@"Error Domain Code:\t\t\t\t\t\t%ld\n", (long)error.code];
        [logString appendFormat:@"Error Localized Description:\t\t\t%@\n", error.localizedDescription];
        [logString appendFormat:@"Error Localized Failure Reason:\t\t\t%@\n", error.localizedFailureReason];
        [logString appendFormat:@"Error Localized Recovery Suggestion:\t%@\n\n", error.localizedRecoverySuggestion];
    }
    
    [logString appendString:@"\n---------------  Related Request Content  --------------\n"];
    
    [self appendURLRequest:request logStr:logString];
    
    [logString appendFormat:@"\n\n============================================\n=                                Response End                                =\n============================================\n\n\n\n"];
    return logString;
}

- (void)appendURLRequest:(NSURLRequest *)request logStr:(NSMutableString *)logStr
{
    [logStr appendFormat:@"\n\nHTTP URL:\n\t%@", request.URL];
    [logStr appendFormat:@"\n\nHTTP Header:\n%@", request.allHTTPHeaderFields ? request.allHTTPHeaderFields : @"\t\t\t\t\tN/A"];
    [logStr appendFormat:@"\n\nHTTP Body:\n\t%@", [[[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding] LGDebug_defaultValue:@"\t\t\t\tN/A"]];
}

#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    self.currentRequestInfo[kLGDebugAPIResponse] = httpResponse;
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.apiData appendData:data];
    [self.client URLProtocol:self didLoadData:data];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.currentRequestInfo[kLGDebugAPIRequest] = connection.currentRequest;
    NSString *responeStr = [[NSString alloc] initWithData:self.apiData encoding:NSUTF8StringEncoding];
    self.currentRequestInfo[kLGDebugAPIResponseString] = responeStr;
    self.currentRequestInfo[kLGDebugAPIResponseData] = self.apiData;
    [self.client URLProtocolDidFinishLoading:self];
    NSDictionary *responDic;
    if (self.currentRequestInfo[kLGDebugAPIResponseData] != nil) {
        responDic = [NSJSONSerialization JSONObjectWithData:self.currentRequestInfo[kLGDebugAPIResponseData]
                                                    options:NSJSONReadingMutableContainers
                                                      error:NULL];
    }
    
    if ([responDic isKindOfClass:[NSDictionary class]]) {
        if ([responDic[@"code"] integerValue] != 0) {
            [self apiLog];
        }
    } else if (((NSHTTPURLResponse *)self.currentRequestInfo[kLGDebugAPIResponse]).statusCode != 200) {
        [self apiLog];
    }
    
    BOOL state = [[[NSUserDefaults standardUserDefaults] objectForKey:kLGDebugImageSwitchState] boolValue];
    if (state) {
        NSString *type = [self contentTypeForImageData:self.apiData];
        if ([type isEqualToString:@"jpeg"] ||
            [type isEqualToString:@"png"]) {
            NSString *imageSize = [[NSUserDefaults standardUserDefaults] objectForKey:kLGDebugImageSize];
            if (self.apiData.length/1024.0 > [imageSize intValue]) {
                NSString *urlPath = [[[[connection.currentRequest.URL.path
                                        componentsSeparatedByString:@"/"] lastObject]
                                      componentsSeparatedByString:@"@"] firstObject];
                NSMutableDictionary *imageApiList = [LGDebugProtocolModel shareInstance].errorImageList;
                NSMutableDictionary *imageDic = @{}.mutableCopy;
                imageDic[@"path"] = connection.currentRequest.URL.absoluteString;
                imageDic[@"data"] = self.apiData;
                imageDic[@"size"] = [self getBytesFromDataLength:self.apiData.length];
                imageApiList[urlPath] = imageDic;
                [[LGDebugProtocolModel shareInstance] syncUserdefault];
            }
        }
    }
}

//通过图片Data数据第一个字节 来获取图片扩展名
- (NSString *)contentTypeForImageData:(NSData *)data{
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return @"jpeg";
        case 0x89:
            return @"png";
        case 0x47:
            return @"gif";
        case 0x49:
        case 0x4D:
            return @"tiff";
        case 0x52:
            if ([data length] < 12) {
                return nil;
            }
            NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
            if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                return @"webp";
            }
            return nil;
    }
    return nil;
}

- (NSString *)getBytesFromDataLength:(NSInteger)dataLength {
    NSString *bytes;
    if (dataLength >= 0.1 * (1024 * 1024)) {
        bytes = [NSString stringWithFormat:@"%0.1fM",dataLength/1024/1024.0];
    } else if (dataLength >= 1024) {
        bytes = [NSString stringWithFormat:@"%0.0fK",dataLength/1024.0];
    } else {
        bytes = [NSString stringWithFormat:@"%zdB",dataLength];
    }
    return bytes;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.currentRequestInfo[kLGDebugAPIRequest] = connection.currentRequest;
    self.currentRequestInfo[kLGDebugAPIError] = error;
    [self.client URLProtocol:self didFailWithError:error];
    [self apiLog];
}

- (void)apiLog {
    NSURLRequest *urlRequest = self.currentRequestInfo[kLGDebugAPIRequest];
    NSString *urlPath = urlRequest.URL.path;
    if (urlPath == nil) {
        return ;
    }
    NSMutableArray *apiList = [LGDebugProtocolModel shareInstance].errorApiList[urlPath];
    if (!apiList) {
        apiList = @[].mutableCopy;
        [LGDebugProtocolModel shareInstance].errorApiList[urlPath] = apiList;
    }
    NSString *logStr = [self logDebugInfoWithResponse:self.currentRequestInfo[kLGDebugAPIResponse]
                                        resposeString:self.currentRequestInfo[kLGDebugAPIResponseString]
                                              request:self.currentRequestInfo[kLGDebugAPIRequest]
                                                error:self.currentRequestInfo[kLGDebugAPIError]];
    [apiList addObject:@{@"path":urlPath,@"log":logStr,@"time":[self getCurrentTime]}];
    [[LGDebugProtocolModel shareInstance] syncUserdefault];
}

- (NSString *)getCurrentTime {
    NSDateFormatter*formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyy-MM-dd HH:mm:ss"];
    NSString*dateTime = [formatter stringFromDate:[NSDate date]];
    return dateTime;
}

- (NSMutableDictionary *)currentRequestInfo {
    if (!_currentRequestInfo) {
        _currentRequestInfo = @{}.mutableCopy;
    }
    return _currentRequestInfo;
}

- (NSMutableData *)apiData {
    if (!_apiData) {
        _apiData = [[NSMutableData alloc] init];
    }
    return _apiData;
}

@end

@implementation LGDebugProtocolModel

+ (LGDebugProtocolModel *)shareInstance {
    static dispatch_once_t onceToken;
    static LGDebugProtocolModel *shareInstance;
    dispatch_once(&onceToken, ^{
        if (!shareInstance) {
            shareInstance = [[LGDebugProtocolModel alloc] init];
        }
    });
    return shareInstance;
}

- (void)syncUserdefault {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.errorApiList];
    NSData *imageData = [NSKeyedArchiver archivedDataWithRootObject:self.errorImageList];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"LGDebugProtocolModel"];
    [[NSUserDefaults standardUserDefaults] setObject:imageData forKey:@"LGDebugProtocolImageModel"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Setter and Getter

- (NSMutableDictionary *)errorApiList {
    if (!_errorApiList) {
        NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:@"LGDebugProtocolModel"];
        NSMutableDictionary *lastData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (lastData) {
            _errorApiList = lastData;
        } else {
            _errorApiList = @{}.mutableCopy;
        }
    }
    return _errorApiList;
}

- (NSMutableDictionary *)errorImageList {
    if (!_errorImageList) {
        NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:@"LGDebugProtocolImageModel"];
        NSMutableDictionary *lastData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (lastData) {
            _errorImageList = lastData;
        } else {
            _errorImageList = @{}.mutableCopy;
        }
    }
    return _errorImageList;
}

@end
