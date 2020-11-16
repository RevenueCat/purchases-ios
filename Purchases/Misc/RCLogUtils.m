//
//  RCLogUtils.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCLogUtils.h"
@import PurchasesCoreSwift;

static BOOL RCShouldShowLogs = NO;

void RCSetShowDebugLogs(BOOL showDebugLogs) {
    RCLogger.shouldShowDebugLogs = showDebugLogs;
}

BOOL RCShowDebugLogs() {
    return RCLogger.shouldShowDebugLogs;
}

void RCErrorLog(NSString *format, ...)
{
    if (!RCShouldShowLogs)
        return;

    va_list args;
    va_start(args, format);

    format = [NSString stringWithFormat:@"[Purchases] - ERROR: %@", format];

    NSLogv(format, args);
    va_end(args);
}

void RCLog(NSString *format, ...)
{
    va_list args;
    va_start(args, format);

    format = [NSString stringWithFormat:@"[Purchases] - INFO: %@", format];
    NSLogv(format, args);
    va_end(args);
}
