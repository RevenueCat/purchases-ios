//
//  RCIntroEligibility.h
//  Purchases
//
//  Created by Jacob Eiting on 2/11/18.
//  Copyright © 2018 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 @typedef RCIntroEligibityStatus
 @brief Enum of different possible states for intro price eligibility status.
 @constant RCIntroEligibityStatusUnknown RevenueCat doesn't have enough information to determine eligibility.
 @constant RCIntroEligibityStatusIneligible The user is not eligible for a free trial or intro pricing for this product.
 @constant RCIntroEligibityStatusEligible The user is eligible for a free trial or intro pricing for this product.
 */
typedef NS_ENUM(NSInteger, RCIntroEligibityStatus) {
    RCIntroEligibityStatusUnknown = 0,
    RCIntroEligibityStatusIneligible,
    RCIntroEligibityStatusEligible
};

@interface RCIntroEligibility : NSObject

- (instancetype)initWithEligibilityStatus:(RCIntroEligibityStatus)status;

@property (readonly) RCIntroEligibityStatus status;

@end
