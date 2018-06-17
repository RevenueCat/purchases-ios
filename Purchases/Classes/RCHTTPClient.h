//
//  RCHTTPClient.h
//  Purchases
//
//  Created by Jacob Eiting on 9/28/17.
//  Copyright © 2018 RevenueCat, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^RCHTTPClientResponseHandler)(NSInteger statusCode,
                                           NSDictionary * _Nullable response,
                                           NSError * _Nullable error);

@interface RCHTTPClient : NSObject


+ (NSString * _Nonnull)serverHostName;

- (void)performRequest:(NSString * _Nonnull)HTTPMethod
                  path:(NSString * _Nonnull)path
                  body:(NSDictionary * _Nullable)requestBody
               headers:(NSDictionary<NSString *, NSString *> * _Nullable)headers
     completionHandler:(RCHTTPClientResponseHandler _Nullable)completionHandler;

@end
