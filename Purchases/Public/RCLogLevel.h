//
//  RCLogLevel.h
//  Purchases
//
//  Created by Andrés Boedo on 6/3/21.
//  Copyright © 2021 Purchases. All rights reserved.
//
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// These must match the values in LogLevel.swift exactly
typedef NS_ENUM(NSInteger, RCLogLevel) {
    RCLogLevelDebug = 0,
    RCLogLevelInfo = 1,
    RCLogLevelWarn = 2,
    RCLogLevelError = 3,
} NS_SWIFT_NAME(Purchases.LogLevel);


NS_ASSUME_NONNULL_END
