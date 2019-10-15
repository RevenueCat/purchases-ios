//
//  RCOffering.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SKProduct;
@class RCPackage, RCOffering;

/**
 An offering is a collection of Packages (`RCPackage`) available for the user to purchase. For more info see https://docs.revenuecat.com/docs/entitlements
 */
NS_SWIFT_NAME(Purchases.Offering)
@interface RCOffering : NSObject

/**
 Unique identifier defined in RevenueCat dashboard.
 */
@property (readonly) NSString *identifier;

/**
 Offering description defined in RevenueCat dashboard.
 */
@property (readonly) NSString *serverDescription;

/**
 Array of `RCPackage` objects available for purchase.
 */
@property (readonly) NSArray<RCPackage *> *availablePackages;

/**
 Lifetime package type configured in the RevenueCat dashboard, if available.
 */
@property (readonly, nullable) RCPackage *lifetime;

/**
 Annual package type configured in the RevenueCat dashboard, if available.
 */
@property (readonly, nullable) RCPackage *annual;

/**
 Six month package type configured in the RevenueCat dashboard, if available.
 */
@property (readonly, nullable) RCPackage *sixMonth;

/**
 Three month package type configured in the RevenueCat dashboard, if available.
 */
@property (readonly, nullable) RCPackage *threeMonth;

/**
 Two month package type configured in the RevenueCat dashboard, if available.
 */
@property (readonly, nullable) RCPackage *twoMonth;

/**
 Monthly package type configured in the RevenueCat dashboard, if available.
 */
@property (readonly, nullable) RCPackage *monthly;

/**
 Weekly package type configured in the RevenueCat dashboard, if available.
 */
@property (readonly, nullable) RCPackage *weekly;

/**
 Retrieves a specific package by identifier, use this to access custom package types configured in the RevenueCat dashboard, e.g. `[offering packageWithIdentifier:@"custom_package_id"]` or `offering[@"custom_package_id"]`.
 */
- (nullable RCPackage *)packageWithIdentifier:(nullable NSString *)identifier NS_SWIFT_NAME(package(identifier:));

/// :nodoc:
- (nullable RCPackage *)objectForKeyedSubscript:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
