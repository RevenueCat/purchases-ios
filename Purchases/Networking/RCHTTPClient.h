//
//  RCHTTPClient.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RCSystemInfo;

typedef void(^RCHTTPClientResponseHandler)(NSInteger statusCode,
                                           NSDictionary * _Nullable response,
                                           NSError * _Nullable error);

@interface RCHTTPClient : NSObject

- (instancetype)initWithSystemInfo:(RCSystemInfo *)systemInfo NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)performRequest:(NSString *)HTTPMethod
                  path:(NSString *)path
                  body:(nullable NSDictionary *)requestBody
               headers:(nullable NSDictionary<NSString *, NSString *> *)headers
     completionHandler:(nullable RCHTTPClientResponseHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
