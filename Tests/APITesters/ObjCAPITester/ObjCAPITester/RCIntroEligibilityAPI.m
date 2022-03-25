//
//  RCIntroEligibilityAPI.m
//  APITester
//
//  Created by Joshua Liebowitz on 7/6/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

@import RevenueCat;
#import "RCIntroEligibilityAPI.h"

@implementation RCIntroEligibilityAPI

+ (void)checkAPI {
    RCIntroEligibility *ie;
    RCIntroEligibilityStatus status = [ie status];
    NSLog(@"%zd", status);

}

+ (void)checkEnums {
    RCIntroEligibilityStatus s = RCIntroEligibilityStatusUnknown;
    switch(s) {
        case RCIntroEligibilityStatusUnknown:
        case RCIntroEligibilityStatusNoIntroOfferExists:
        case RCIntroEligibilityStatusIneligible:
        case RCIntroEligibilityStatusEligible:
            NSLog(@"%ld", (long)s);
    }
}

@end
