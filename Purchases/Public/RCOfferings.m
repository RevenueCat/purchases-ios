//
//  RCOfferings.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import "RCOfferings+Protected.h"
#import "RCOffering+Protected.h"

@interface RCOfferings ()
@property (readwrite) NSString *currentOfferingID;
@property (readwrite) NSDictionary<NSString *, RCOffering *> *offerings;
@end

@implementation RCOfferings
- (instancetype)initWithOfferings:(NSDictionary<NSString *, RCOffering *> *)offerings currentOfferingID:(NSString *)currentOfferingID
{
    self = [super init];
    if (self) {
        self.offerings = offerings;
        self.currentOfferingID = currentOfferingID;
    }

    return self;
}

- (nullable RCOffering *)offeringWithIdentifier:(nullable NSString *)identifier
{
    return self.offerings[identifier];
}

- (nullable RCOffering *)objectForKeyedSubscript:(NSString *)key
{
    return [self offeringWithIdentifier:key];
}

- (RCOffering *)currentOffering
{
    return self.offerings[self.currentOfferingID];
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<Offerings {\n"];
    for (NSString *offeringName in self.offerings) {
        RCOffering *offering = self.offerings[offeringName];
        NSString *offeringDesc = [NSMutableString stringWithFormat:@"\t%@\n", offering];
        [description appendString:offeringDesc];
    }
    [description appendFormat:@"\tcurrentOffering=%@", self.currentOffering];
    [description appendString:@">"];
    return description;
}

@end
