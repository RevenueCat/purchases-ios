//
//  RCPackage+Protected.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright (c) 2019 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCPackage.h"

#define PACKAGE_TYPE_STRINGS (@[@"$rc_lifetime", @"$rc_annual", @"$rc_six_month", @"$rc_three_month", @"$rc_two_month", @"$rc_monthly", @"$rc_weekly"])

NS_ASSUME_NONNULL_BEGIN

@interface RCPackage (Protected)

@property (readonly) NSString *offeringIdentifier;

+ (nullable NSString *)stringFromPackageType:(RCPackageType)packageType;

+ (RCPackageType)packageTypeFromString:(NSString *)string;

- (instancetype)initWithIdentifier:(NSString *)identifier packageType:(RCPackageType)packageType product:(SKProduct *)product offeringIdentifier:(NSString *)offeringIdentifier;

@end

NS_ASSUME_NONNULL_END
