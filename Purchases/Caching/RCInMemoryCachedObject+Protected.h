//
// Created by RevenueCat on 2/3/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCInMemoryCachedObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCInMemoryCachedObject (Protected)

@property (nonatomic, nullable) NSDate *stubbedNow;

- (instancetype)initWithCacheDurationInSeconds:(int)cacheDurationInSeconds
                                 lastUpdatedAt:(nullable NSDate *)lastUpdatedAt
                                    stubbedNow:(nullable NSDate *)stubbedNow;

@end

NS_ASSUME_NONNULL_END
