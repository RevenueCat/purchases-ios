//
//  RCLogUtils.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define RCDebugLog(args, ...) \
    [RCLog debug: [NSString stringWithFormat: args, ##__VA_ARGS__]]

#define RCLog(args, ...) \
    [RCLog info: [NSString stringWithFormat: args, ##__VA_ARGS__]]

#define RCWarnLog(args, ...) \
    [RCLog warn: [NSString stringWithFormat: args, ##__VA_ARGS__]]

#define RCErrorLog(args, ...) \
    [RCLog error: [NSString stringWithFormat: args, ##__VA_ARGS__]]

#define RCAppleErrorLog(args, ...) \
    [RCLog appleError: [NSString stringWithFormat: args, ##__VA_ARGS__]]

#define RCAppleWarningLog(args, ...) \
    [RCLog appleWarning: [NSString stringWithFormat: args, ##__VA_ARGS__]]

#define RCPurchaseLog(args, ...) \
    [RCLog purchase: [NSString stringWithFormat: args, ##__VA_ARGS__]]

#define RCPurchaseSuccessLog(args, ...) \
    [RCLog rcPurchaseSuccess: [NSString stringWithFormat: args, ##__VA_ARGS__]]

#define RCSuccessLog(args, ...) \
    [RCLog rcSuccess: [NSString stringWithFormat: args, ##__VA_ARGS__]]

#define RCUserLog(args, ...) \
    [RCLog user: [NSString stringWithFormat: args, ##__VA_ARGS__]]

NS_ASSUME_NONNULL_END
