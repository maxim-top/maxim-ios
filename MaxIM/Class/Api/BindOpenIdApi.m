

//
//  BindOpenIdApi.m
//  MaxIM
//
//  Created by 韩雨桐 on 2019/5/1.
//  Copyright © 2019 hyt. All rights reserved.
//

#import "BindOpenIdApi.h"

@interface BindOpenIdApi ()

@property (nonatomic,copy) NSString *openId;


@end

@implementation BindOpenIdApi

- (instancetype)initWithopenId:(NSString *)openId {
    if (self = [super init]) {
        self.openId = openId;
    }
    return self;
}

- (nullable NSString *)apiPath  {
    return @"app/wechat/bind";
}

-  (NSDictionary *)requestParams {
    return @{@"open_id": self.openId,
             @"type" : @0};
}

- (HQRequestMethod)requestMethod {
    return HQRequestMethodPost;
}



@end
