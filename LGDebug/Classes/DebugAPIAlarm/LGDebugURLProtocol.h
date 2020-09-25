//
//  LGDebugURLProtocol.h
//  SuYun
//
//  Created by iBlock on 16/9/1.
//  Copyright © 2016年 58. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LGDebugProtocolModel : NSObject

+ (LGDebugProtocolModel *)shareInstance;
- (void)syncUserdefault;
@property (nonatomic, strong, readonly) NSMutableDictionary *errorApiList;
@property (nonatomic, strong, readonly) NSMutableDictionary *errorImageList;

@end

@interface LGDebugURLProtocol : NSURLProtocol

+ (void)updateURLProtocol;

@end
