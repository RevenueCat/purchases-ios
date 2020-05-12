//
// Created by Andrés Boedo on 3/4/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import "NSDate+RCExtensions.h"

NS_ASSUME_NONNULL_BEGIN


@implementation NSDate (RCExtensions)

- (UInt64)millisecondsSince1970 {
    return (UInt64)([self timeIntervalSince1970] * 1000.0);
}

@end


NS_ASSUME_NONNULL_END
