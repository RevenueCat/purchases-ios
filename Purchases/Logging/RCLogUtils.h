//
//  RCLogUtils.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define RCLog(args, ...) \
    [RCLog info: [NSString stringWithFormat: args, ##__VA_ARGS__]]

#define RCWarnLog(args, ...) \
    [RCLog warn: [NSString stringWithFormat: args, ##__VA_ARGS__]]

NS_ASSUME_NONNULL_END
