//
//  RCHTTPClient.h
//  Purchases
//
//  Created by Jacob Eiting on 9/28/17.
//  Copyright © 2017 RevenueCat, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCHTTPClient : NSObject


+ (NSString * _Nonnull)serverHostName;

- (void)performRequest:(NSString * _Nonnull)HTTPMethod
                   path:(NSString * _Nonnull)path
                  body:(NSDictionary * _Nullable)requestBody
               headers:(NSDictionary<NSString *, NSString *> * _Nullable)headers
     completionHandler:(void (^_Nullable)(BOOL success,
                                          NSDictionary * _Nullable response))completionHandler;

@end
