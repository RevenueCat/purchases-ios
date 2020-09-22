//
// Created by Andrés Boedo on 9/4/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "RCHTTPClient.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCHTTPRequest : NSObject <NSCopying, NSCopying>

- (instancetype)initWithHTTPMethod:(NSString *)httpMethod
                              path:(NSString *)path
                              body:(nullable NSDictionary *)requestBody
                           headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                 completionHandler:(nullable RCHTTPClientResponseHandler)completionHandler;
- (id)copyWithZone:(nullable NSZone *)zone;
- (NSString *)description;

@property (readonly, copy, nonatomic) NSString *httpMethod;
@property (readonly, copy, nonatomic) NSString *path;
@property (readonly, copy, nonatomic, nullable) NSDictionary *requestBody;
@property (readonly, copy, nonatomic, nullable) NSDictionary<NSString *, NSString *> *headers;
@property (readonly, copy, nonatomic, nullable) RCHTTPClientResponseHandler completionHandler;

@end


NS_ASSUME_NONNULL_END
