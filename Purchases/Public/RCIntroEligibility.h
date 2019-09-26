//
//  RCIntroEligibility.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 @typedef RCIntroEligibilityStatus
 @brief Enum of different possible states for intro price eligibility status.
 @constant RCIntroEligibilityStatusUnknown RevenueCat doesn't have enough information to determine eligibility.
 @constant RCIntroEligibilityStatusIneligible The user is not eligible for a free trial or intro pricing for this product.
 @constant RCIntroEligibilityStatusEligible The user is eligible for a free trial or intro pricing for this product.
 */
typedef NS_ENUM(NSInteger, RCIntroEligibilityStatus) {
    /**
     RevenueCat doesn't have enough information to determine eligibility.
     */
    RCIntroEligibilityStatusUnknown = 0,
    /**
     The user is not eligible for a free trial or intro pricing for this product.
     */
    RCIntroEligibilityStatusIneligible,
    /**
     The user is eligible for a free trial or intro pricing for this product.
     */
    RCIntroEligibilityStatusEligible
};

/**
 Class that holds the introductory price status
 */
@interface RCIntroEligibility : NSObject

/**
 The introductory price eligibility status
 */
@property (readonly) RCIntroEligibilityStatus status;

@end
