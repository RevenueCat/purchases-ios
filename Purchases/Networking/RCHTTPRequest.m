//
// Created by Andrés Boedo on 9/4/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import "RCHTTPRequest.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCHTTPRequest ()

@property(copy, nonatomic) NSString *httpMethod;
@property(copy, nonatomic) NSString *path;
@property(copy, nonatomic, nullable)  NSDictionary *requestBody;
@property(copy, nonatomic, nullable)  NSDictionary<NSString *, NSString *> *headers;
@property(copy, nonatomic, nullable)  RCHTTPClientResponseHandler completionHandler;

@end


@implementation RCHTTPRequest

- (instancetype)initWithHTTPMethod:(NSString *)httpMethod
                              path:(NSString *)path
                              body:(nullable NSDictionary *)requestBody
                           headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                 completionHandler:(nullable RCHTTPClientResponseHandler)completionHandler {
    if (self = [super init]) {
        self.httpMethod = httpMethod;
        self.path = path;
        self.requestBody = requestBody;
        self.headers = headers;
        self.completionHandler = completionHandler;
    }
    return self;
}

@end


NS_ASSUME_NONNULL_END