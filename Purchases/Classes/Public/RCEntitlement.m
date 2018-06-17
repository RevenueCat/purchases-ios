//
//  RCEntitlement.m
//  Purchases
//
//  Created by Jacob Eiting on 6/2/18.
//  Copyright © 2018 Purchases. All rights reserved.
//

#import "RCEntitlement.h"

@interface RCEntitlement ()

@property (readwrite, nonatomic) NSDictionary<NSString *, RCOffering *> *offerings;

@end

@implementation RCEntitlement

- (instancetype)initWithOfferings:(NSDictionary<NSString *, RCOffering *> *)offerings
{
    if (self = [super init])
    {
        self.offerings = offerings;
    }
    return self;
}

@end
