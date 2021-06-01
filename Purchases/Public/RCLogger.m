//
//  RCLogger.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2021 RevenueCat. All rights reserved.
//

#import "RCLogger.h"
#import "RCLogUtils.h"

@import PurchasesCoreSwift;

@implementation RCLogger

+ (void)setDebugLogsEnabled:(BOOL)enabled {
    RCSetShowDebugLogs(enabled);
}

+ (BOOL)debugLogsEnabled {
    return RCShowDebugLogs();
}

+ (void)setLogHandler:(void(^)(RCLogLevel, NSString * _Nonnull))handler {
    RCLog.logHandler = ^(NSInteger level, NSString *message) {
        handler((RCLogLevel)level, message);
    };
}

@end
