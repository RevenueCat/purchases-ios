//
// Created by Andrés Boedo on 5/6/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, RCHTTPStatusCodes) {
    RC_REDIRECT = 300,
    RC_INTERNAL_SERVER_ERROR = 500,
    RC_NOT_FOUND_ERROR = 404,
    RC_NETWORK_CONNECT_TIMEOUT_ERROR = 599
};

NS_ASSUME_NONNULL_END
