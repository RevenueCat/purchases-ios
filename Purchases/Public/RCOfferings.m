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
@property (readwrite, nullable) NSString *currentOfferingID;
@property (readwrite) NSDictionary<NSString *, RCOffering *> *all;
@end

@implementation RCOfferings
- (instancetype)initWithOfferings:(NSDictionary<NSString *, RCOffering *> *)offerings currentOfferingID:(NSString *)currentOfferingID
{
    self = [super init];
    if (self) {
        self.all = offerings;
        self.currentOfferingID = currentOfferingID;
    }

    return self;
}

- (nullable RCOffering *)offeringWithIdentifier:(nullable NSString *)identifier
{
    return self.all[identifier];
}

- (nullable RCOffering *)objectForKeyedSubscript:(NSString *)key
{
    return [self offeringWithIdentifier:key];
}

- (nullable RCOffering *)current
{
    if (self.currentOfferingID) {
        return self.all[self.currentOfferingID];
    }
    return nil;
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<Offerings {\n"];
    for (NSString *offeringName in self.all) {
        RCOffering *offering = self.all[offeringName];
        NSString *offeringDesc = [NSMutableString stringWithFormat:@"\t%@\n", offering];
        [description appendString:offeringDesc];
    }
    [description appendFormat:@"\tcurrentOffering=%@", self.current];
    [description appendString:@">"];
    return description;
}

@end
