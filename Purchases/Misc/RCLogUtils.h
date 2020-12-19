//
//  RCLogUtils.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

void RCSetShowDebugLogs(BOOL showDebugLogs);
BOOL RCShowDebugLogs(void);

#define RCDebugLog(args, ...) \
    [RCLogger debug: [NSString stringWithFormat: args, ##__VA_ARGS__]]

#define RCLog(args, ...) \
    [RCLogger info: [NSString stringWithFormat: args, ##__VA_ARGS__]]

#define RCWarnLog(args, ...) \
    [RCLogger warn: [NSString stringWithFormat: args, ##__VA_ARGS__]]

#define RCErrorLog(args, ...) \
    [RCLogger error: [NSString stringWithFormat: args, ##__VA_ARGS__]]

#define RCAppleErrorLog(args, ...) \
    [RCLogger appleError: [NSString stringWithFormat: args, ##__VA_ARGS__]]

#define RCAppleWarningLog(args, ...) \
    [RCLogger appleWarning: [NSString stringWithFormat: args, ##__VA_ARGS__]]

#define RCPurchaseLog(args, ...) \
    [RCLogger purchase: [NSString stringWithFormat: args, ##__VA_ARGS__]]

#define RCPurchaseSuccessLog(args, ...) \
    [RCLogger rcPurchaseSuccess: [NSString stringWithFormat: args, ##__VA_ARGS__]]

#define RCSuccessLog(args, ...) \
    [RCLogger rcSuccess: [NSString stringWithFormat: args, ##__VA_ARGS__]]

#define RCUserLog(args, ...) \
    [RCLogger user: [NSString stringWithFormat: args, ##__VA_ARGS__]]

NS_ASSUME_NONNULL_END
