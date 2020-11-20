//
//  RCLogUtils.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCLogUtils.h"
@import PurchasesCoreSwift;

void RCSetShowDebugLogs(BOOL showDebugLogs) {
    RCLogger.shouldShowDebugLogs = showDebugLogs;
}

BOOL RCShowDebugLogs() {
    return RCLogger.shouldShowDebugLogs;
}
