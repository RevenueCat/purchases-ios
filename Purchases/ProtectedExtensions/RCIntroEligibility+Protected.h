//
//  RCIntroEligibility+Protected.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCIntroEligibility.h"

@interface RCIntroEligibility (Protected)

- (instancetype)initWithEligibilityStatus:(RCIntroEligibilityStatus)status;
- (instancetype)initWithEligibilityStatusCode:(NSNumber *)statusCode;

@end

