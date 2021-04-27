//
// Created by Andrés Boedo on 3/4/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface NSDate (RCExtensions)

- (UInt64)rc_millisecondsSince1970AsUInt64;

@end


NS_ASSUME_NONNULL_END
