//
//  RCHTTPClient.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCAttributionData;

NS_ASSUME_NONNULL_BEGIN

extern NSMutableArray<RCAttributionData *> * _Nullable postponedAttributionData;

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
