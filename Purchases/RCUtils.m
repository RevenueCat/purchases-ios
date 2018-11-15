//
//  RCUtils.m
//  Purchases
//
//  Created by Jacob Eiting on 9/29/17.
//  Copyright © 2018 RevenueCat, Inc. All rights reserved.
//

#import "RCUtils.h"

static BOOL RCShouldShowLogs = NO;

void RCSetShowDebugLogs(BOOL showDebugLogs)
{
    RCShouldShowLogs = showDebugLogs;
}

void RCDebugLog(NSString *format, ...)
{
    if (!RCShouldShowLogs)
        return;

    va_list args;
    va_start(args, format);

    format = [NSString stringWithFormat:@"[Debug] %@", format];

    NSLogv(format, args);
    va_end(args);
}

void RCLog(NSString *format, ...)
{
    va_list args;
    va_start(args, format);

    format = [NSString stringWithFormat:@"[Purchases] %@", format];
    NSLogv(format, args);
    va_end(args);
}
