//
//  RCIntroEligibility.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCIntroEligibility.h"

@interface RCIntroEligibility ()

@property (nonatomic) RCIntroEligibilityStatus status;

@end

@implementation RCIntroEligibility

- (instancetype)initWithEligibilityStatus:(RCIntroEligibilityStatus)status {
    if (self = [super init]) {
        self.status = status;
    }
    return self;
}

- (instancetype)initWithEligibilityStatusCode:(int)statusCode {
    return [self initWithEligibilityStatus:(RCIntroEligibilityStatus)statusCode];
}

- (NSString *)description {
    switch (self.status) {
        case RCIntroEligibilityStatusEligible:
            return @"Eligible for trial or introductory price.";
        case RCIntroEligibilityStatusIneligible:
            return @"Not eligible for trial or introductory price.";
        case RCIntroEligibilityStatusUnknown:
        default:
            return @"Status indeterminate.";
    }
}

@end
