//
// Created by RevenueCat on 2/3/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCDeviceCache.h"
#import "RCInMemoryCachedObject.h"
#import "RCOfferings.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCDeviceCache (Protected)

- (void)setPurchaserInfoCacheTimestamp:(NSDate *)timestamp forAppUserID:(NSString *)appUserID;

- (nullable instancetype)initWith:(nullable NSUserDefaults *)userDefaults
            offeringsCachedObject:(nullable RCInMemoryCachedObject<RCOfferings *> *)offeringsCachedObject
               notificationCenter:(nullable NSNotificationCenter *)notificationCenter;

@end


NS_ASSUME_NONNULL_END
