//
//  RCEntitlement.h
//  Purchases
//
//  Created by Jacob Eiting on 6/2/18.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCOffering;
@class RCEntitlement;

/**
 An alias for a NSDictionary of Entitlements
 */
typedef NSDictionary<NSString *, RCEntitlement *> RCEntitlements NS_SWIFT_NAME(Entitlements);


/**
 An entitlement represents features or content that a user is "entitled" to. Entitlements are unlocked by having an active subscription or making a one-time purchase. Many different products can unlock. Most subscription apps only have one entitlement, unlocking all premium features. However, if you had two tiers of content such as premium and premium_plus, you would have 2 entitlements. A common and simple setup example is one entitlement with identifier pro, one offering monthly, with one product. See [this link](https://docs.revenuecat.com/docs/entitlements) for more info
*/
NS_SWIFT_NAME(Entitlement)
@interface RCEntitlement : NSObject

/**
 Dictionary of offering objects by name
*/
@property (readonly) NSDictionary<NSString *, RCOffering *> *offerings;

@end
