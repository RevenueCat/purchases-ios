//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RCDangerousSettingsAPI.m
//  ObjCAPITester
//
//  Created by Antonio Pallares on 17/5/26.
//

#import "RCDangerousSettingsAPI.h"

@import RevenueCat;

@implementation RCDangerousSettingsAPI

+ (void)checkAPI {
    RCDangerousSettings *defaultSettings __unused = [[RCDangerousSettings alloc] init];
    RCDangerousSettings *settings = [[RCDangerousSettings alloc] initWithAutoSyncPurchases:true];

    BOOL autoSyncPurchases __unused = settings.autoSyncPurchases;
    BOOL customEntitlementComputation __unused = settings.customEntitlementComputation;
}

@end
