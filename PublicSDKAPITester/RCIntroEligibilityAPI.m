//
//  RCIntroEligibilityAPI.m
//  APITester
//
//  Created by Joshua Liebowitz on 7/6/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

@import PurchasesCoreSwift;
#import "RCIntroEligibilityAPI.h"

@implementation RCIntroEligibilityAPI

+ (void)checkAPI {
    RCIntroEligibility *ie = [[RCIntroEligibility alloc] init];
    RCIntroEligibilityStatus status = [ie status];
    NSLog(@"%zd", status);

}

+ (void)checkEnums {
    RCIntroEligibilityStatus s = RCIntroEligibilityStatusUnknown;
    s = RCIntroEligibilityStatusIneligible;
    s = RCIntroEligibilityStatusEligible;
}

@end
