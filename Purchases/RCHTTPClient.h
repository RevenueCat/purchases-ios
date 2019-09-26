//
//  RCHTTPClient.h
//  Purchases
//
//  Created by Jacob Eiting on 9/28/17.
//  Copyright © 2019 RevenueCat, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^RCHTTPClientResponseHandler)(NSInteger statusCode,
                                           NSDictionary * _Nullable response,
                                           NSError * _Nullable error);

@interface RCHTTPClient : NSObject


+ (NSString *)serverHostName;

- (void)performRequest:(NSString *)HTTPMethod
                  path:(NSString *)path
                  body:(nullable NSDictionary *)requestBody
               headers:(nullable NSDictionary<NSString *, NSString *> *)headers
     completionHandler:(nullable RCHTTPClientResponseHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END