//
//  RCEntitlement.m
//  Purchases
//
//  Created by Jacob Eiting on 6/2/18.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import "RCEntitlement.h"
#import "RCOffering+Protected.h"

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

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<Entitlement offerings: {\n"];
    for (NSString *offeringName in self.offerings)
    {
        RCOffering *offering = self.offerings[offeringName];
        NSString *offeringDesc = [NSMutableString stringWithFormat:@"\t%@ => {activeProduct: %@, loaded: %@}\n",
                                  offeringName, offering.activeProductIdentifier, (offering.activeProduct == nil) ? @"NO" : @"YES"];
        [description appendString:offeringDesc];
    }
    [description appendString:@"} >"];
    return description;
}

@end
