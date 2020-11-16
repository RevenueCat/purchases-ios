//
// Created by Andrés Boedo on 11/12/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RCReceiptRefreshPolicy) {
    RCReceiptRefreshPolicyAlways = 0,
    RCReceiptRefreshPolicyOnlyIfEmpty,
    RCReceiptRefreshPolicyNever
};

NS_ASSUME_NONNULL_END
