//
//  RCEntitlementInfos.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCEntitlementInfo;

NS_ASSUME_NONNULL_BEGIN

/**
 This class contains all the entitlements associated to the user.
 */
NS_SWIFT_NAME(Purchases.EntitlementInfos)
@interface RCEntitlementInfos : NSObject

/**
 Dictionary of all EntitlementInfo (`RCEntitlementInfo`) objects (active and inactive) keyed by entitlement identifier. This dictionary can also be accessed by using an index subscript on EntitlementInfos, e.g. `entitlementInfos[@"pro_entitlement_id"]`.
 */
@property (readonly) NSDictionary<NSString *, RCEntitlementInfo *> *all;

/**
 Dictionary of active EntitlementInfo (`RCEntitlementInfo`) objects keyed by entitlement identifier.
 */
@property (readonly) NSDictionary<NSString *, RCEntitlementInfo *> *active;

/// :nodoc:
- (nullable RCEntitlementInfo *)objectForKeyedSubscript:(id)key;

@end

NS_ASSUME_NONNULL_END
