//
//  RCIntroEligibility.m
//  Purchases
//
//  Created by Jacob Eiting on 2/11/18.
//  Copyright © 2018 Purchases. All rights reserved.
//

#import "RCIntroEligibility.h"

@interface RCIntroEligibility ()

@property (nonatomic) RCIntroEligibityStatus status;

@end

@implementation RCIntroEligibility

- (instancetype)initWithEligibilityStatus:(RCIntroEligibityStatus)status
{
    if (self = [super init]) {
        self.status = status;
    }
    return self;
}

@end
