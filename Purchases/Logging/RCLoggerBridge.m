//
//  RCLogger.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2021 RevenueCat. All rights reserved.
//

#import "RCLoggerBridge.h"
#import "RCLogUtils.h"

@import PurchasesCoreSwift;

@implementation RCLoggerBridge

+ (void)setLogLevel:(RCLogLevel)logLevel {
    switch (logLevel) {
        case RCLogLevelDebug:
            RCLog.logLevel = RCInternalLogLevelDebug;
            break;
        case RCLogLevelInfo:
            RCLog.logLevel = RCInternalLogLevelInfo;
            break;
        case RCLogLevelWarn:
            RCLog.logLevel = RCInternalLogLevelWarn;
            break;
        case RCLogLevelError:
            RCLog.logLevel = RCInternalLogLevelError;
            break;
    }
}

+ (RCLogLevel)logLevel {
    switch (RCLog.logLevel) {
        case RCInternalLogLevelDebug:
            return RCLogLevelDebug;
        case RCInternalLogLevelInfo:
            return RCLogLevelInfo;
        case RCInternalLogLevelWarn:
            return RCLogLevelWarn;
        case RCInternalLogLevelError:
            return RCLogLevelError;
    }
}
+ (void)setLogHandler:(void(^)(RCLogLevel, NSString * _Nonnull))handler {
    RCLog.logHandler = ^(NSInteger level, NSString *message) {
        handler((RCLogLevel)level, message);
    };
}

@end
