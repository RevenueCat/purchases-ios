//
//  RCIntroEligibility.h
//  Purchases
//
//  Created by Jacob Eiting on 2/11/18.
//  Copyright © 2018 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, RCIntroEligibityStatus) {
    RCIntroEligibityStatusUnknown = 0,
    RCIntroEligibityStatusIneligible,
    RCIntroEligibityStatusEligible
};

@interface RCIntroEligibility : NSObject

- (instancetype)initWithEligibilityStatus:(RCIntroEligibityStatus)status;

@property (readonly) RCIntroEligibityStatus status;

@end
