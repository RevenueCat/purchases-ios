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
 TODO
 */
NS_SWIFT_NAME(EntitlementInfos)
@interface RCEntitlementInfos : NSObject

/**
 Dictionary of containing EntitlementInfo objects of all (active and inactive) entitlements by Entitlement identifier. This dictionary can also be accessed by using an index subscript on EntitlementInfos
*/
@property (readonly) NSDictionary<NSString *, RCEntitlementInfo *> *all;
/**
 Dictionary of containing EntitlementInfo objects of the active entitlements by Entitlement identifier.
*/
@property (readonly) NSDictionary<NSString *, RCEntitlementInfo *> *active;

/// :nodoc:
- (nullable RCEntitlementInfo *)objectForKeyedSubscript:(id)key;

@end

NS_ASSUME_NONNULL_END
