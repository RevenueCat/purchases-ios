//
//  RCOfferings.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCOffering;

NS_ASSUME_NONNULL_BEGIN

/**
 This class contains all the offerings configured in RevenueCat dashboard. For more info see https://docs.revenuecat.com/docs/entitlements
*/
NS_SWIFT_NAME(Purchases.Offerings)
@interface RCOfferings : NSObject

/**
 Current offering configured in the RevenueCat dashboard.
*/
@property (readonly, nullable) RCOffering *current;

/**
 Dictionary of all Offerings (`RCOffering`) objects keyed by their identifier. This dictionary can also be accessed by using an index subscript on RCOfferings, e.g. `offerings[@"offering_id"]`. To access the current offering use `RCOfferings.current`.
*/
@property (readonly) NSDictionary<NSString *, RCOffering *> *all;

/**
 Retrieves a specific offering by its identifier, use this to access additional offerings configured in the RevenueCat dashboard, e.g. `[offerings offeringWithIdentifier:@"offering_id"]` or `offerings[@"offering_id"]`. To access the current offering use `RCOfferings.current`.
*/
- (nullable RCOffering *)offeringWithIdentifier:(nullable NSString *)identifier NS_SWIFT_NAME(offering(identifier:));

/// :nodoc:
- (nullable RCOffering *)objectForKeyedSubscript:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
