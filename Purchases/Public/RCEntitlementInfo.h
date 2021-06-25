//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The EntitlementInfo object gives you access to all of the information about the status of a user entitlement.
 */
NS_SWIFT_NAME(Purchases.EntitlementInfo)
@interface RCEntitlementInfo : NSObject

/**
 The entitlement identifier configured in the RevenueCat dashboard
 */
@property (readonly) NSString *identifier;

/**
 True if the user has access to this entitlement
 */
@property (readonly) BOOL isActive;

/**
 True if the underlying subscription is set to renew at the end of
 the billing period (expirationDate). Will always be True if entitlement
 is for lifetime access.
 */
@property (readonly) BOOL willRenew;

/**
 The last period type this entitlement was in
 Either: RCNormal, RCIntro, RCTrial
 */
@property (readonly) enum RCPeriodType periodType;

/**
 The latest purchase or renewal date for the entitlement.
 */
@property (readonly) NSDate *latestPurchaseDate;

/**
 The first date this entitlement was purchased
 */
@property (readonly) NSDate *originalPurchaseDate;

/**
 The expiration date for the entitlement, can be `nil` for lifetime access.
 If the `periodType` is `trial`, this is the trial expiration date.
 */
@property (readonly, nullable) NSDate *expirationDate;

/**
 The store where this entitlement was unlocked from
 Either: RCAppStore, RCMacAppStore, RCPlayStore, RCStripe, RCPromotional, RCUnknownStore
 */
@property (readonly) enum RCStore store;

/**
 The product identifier that unlocked this entitlement
 */
@property (readonly) NSString *productIdentifier;

/**
 False if this entitlement is unlocked via a production purchase
 */
@property (readonly) BOOL isSandbox;

/**
 The date an unsubscribe was detected. Can be `nil`.
 
 Note: Entitlement may still be active even if user has unsubscribed. Check the `isActive` property.
 */
@property (readonly, nullable) NSDate *unsubscribeDetectedAt;

/**
 The date a billing issue was detected. Can be `nil` if there is no
 billing issue or an issue has been resolved.
 
 Note: Entitlement may still be active even if there is a billing issue.
 Check the `isActive` property.
 */
@property (readonly, nullable) NSDate *billingIssueDetectedAt;

/**
 Use this property to determine whether a purchase was made by the current user
 or shared to them by a family member. This can be useful for onboarding users who have had
 an entitlement shared with them, but might not be entirely aware of the benefits they now have.
 */
@property (readonly) enum RCPurchaseOwnershipType ownershipType;

@end

NS_ASSUME_NONNULL_END



