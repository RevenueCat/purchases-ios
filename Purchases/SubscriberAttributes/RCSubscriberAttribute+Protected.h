//
// Created by RevenueCat on 2/26/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCSubscriberAttribute.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCSubscriberAttribute (Protected)

- (instancetype)initWithKey:(NSString *)key
                      value:(NSString *)value
                  appUserID:(NSString *)appUserID
                   isSynced:(BOOL)isSynced
                    setTime:(NSDate *)setTime;

@end

NS_ASSUME_NONNULL_END