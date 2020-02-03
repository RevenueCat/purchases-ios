//
// Created by RevenueCat on 2/3/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCDeviceCache.h"


@interface RCDeviceCache (Protected)

@property (nonatomic) NSDate *stubbedNow;

- (instancetype)initWith:(NSUserDefaults *)userDefaults
              stubbedNow:(NSDate *)stubbedNow;

@end

