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
void RCDebugLog(NSString *format, ...);
void RCErrorLog(NSString *format, ...);
void RCLog(NSString *format, ...);

NS_ASSUME_NONNULL_END
