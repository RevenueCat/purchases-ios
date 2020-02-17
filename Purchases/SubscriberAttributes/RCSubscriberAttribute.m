//
// Created by Andrés Boedo on 2/17/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCSubscriberAttribute.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCSubscriberAttribute ()

@property(nonatomic, copy) NSString *key;
@property(nonatomic, copy) NSString *value;
@property(nonatomic, copy) NSString *appUserID;
@property(nonatomic) NSDate *syncStartedTime;
@property(nonatomic, assign) BOOL isSynced;

@end


NS_ASSUME_NONNULL_END


@implementation RCSubscriberAttribute

@end
