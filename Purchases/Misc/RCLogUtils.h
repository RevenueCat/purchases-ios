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

#define RCDebugLog(args, ...) [RCLogger logWithLevel:RCLogLevelDebug message: [NSString stringWithFormat: args, ##__VA_ARGS__]]
#define RCLog(args, ...) [RCLogger logWithLevel:RCLogLevelInfo message: [NSString stringWithFormat: args, ##__VA_ARGS__]]
#define RCWarnLog(args, ...) [RCLogger logWithLevel:RCLogLevelWarn message: [NSString stringWithFormat: args, ##__VA_ARGS__]]
#define RCErrorLog(args, ...) [RCLogger logWithLevel:RCLogLevelError message: [NSString stringWithFormat: args, ##__VA_ARGS__]]

NS_ASSUME_NONNULL_END
