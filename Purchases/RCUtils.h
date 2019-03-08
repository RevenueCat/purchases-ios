//
//  RCUtils.h
//  Purchases
//
//  Created by Jacob Eiting on 9/29/17.
//  Copyright © 2019 RevenueCat, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

void RCSetShowDebugLogs(BOOL showDebugLogs);
BOOL RCShowDebugLogs(void);
void RCDebugLog(NSString *format, ...);
void RCLog(NSString *format, ...);
BOOL RCIsSandbox(void);

NS_ASSUME_NONNULL_END
