//
//  RCOffering.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import "RCOffering.h"
#import "RCPackage.h"

@interface RCOffering ()

@property (readwrite) NSString *identifier;
@property (readwrite) NSString *serverDescription;
@property (readwrite) NSArray<RCPackage *> *availablePackages;
@property (readwrite, nullable) RCPackage *lifetime;
@property (readwrite, nullable) RCPackage *annual;
@property (readwrite, nullable) RCPackage *sixMonth;
@property (readwrite, nullable) RCPackage *threeMonth;
@property (readwrite, nullable) RCPackage *twoMonth;
@property (readwrite, nullable) RCPackage *monthly;
@property (readwrite, nullable) RCPackage *weekly;

@end

@implementation RCOffering

- (instancetype)initWithIdentifier:(NSString *)identifier serverDescription:(NSString *)serverDescription availablePackages:(NSArray<RCPackage *> *)availablePackages
{
    self = [super init];
    if (self) {
        self.identifier = identifier;
        self.serverDescription = serverDescription;
        self.availablePackages = availablePackages;
        for (RCPackage *package in availablePackages) {
            switch (package.packageType) {
                case RCPackageTypeUnknown:
                case RCPackageTypeCustom:
                    break;
                case RCPackageTypeLifetime:
                    self.lifetime = package;
                    break;
                case RCPackageTypeAnnual:
                    self.annual = package;
                    break;
                case RCPackageTypeSixMonth:
                    self.sixMonth = package;
                    break;
                case RCPackageTypeThreeMonth:
                    self.threeMonth = package;
                    break;
                case RCPackageTypeTwoMonth:
                    self.twoMonth = package;
                    break;
                case RCPackageTypeMonthly:
                    self.monthly = package;
                    break;
                case RCPackageTypeWeekly:
                    self.weekly = package;
                    break;
            }
        }
    }

    return self;
}

- (nullable RCPackage *)packageWithIdentifier:(nullable NSString *)identifier
{
    for (RCPackage *package in self.availablePackages) {
        if ([package.identifier isEqualToString:identifier]) {
            return package;
        }
    }
    return nil;
}

- (nullable RCPackage *)objectForKeyedSubscript:(NSString *)key
{
    return [self packageWithIdentifier:key];
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<Offering {\n"];
    [description appendFormat:@"\tidentifier=%@\n", self.identifier];
    [description appendFormat:@"\tserverDescription=%@\n", self.serverDescription];
    [description appendFormat:@"\tavailablePackages=%@\n", self.availablePackages];
    [description appendFormat:@"\tlifetime=%@\n", self.lifetime];
    [description appendFormat:@"\tannual=%@\n", self.annual];
    [description appendFormat:@"\tsixMonth=%@\n", self.sixMonth];
    [description appendFormat:@"\tthreeMonth=%@\n", self.threeMonth];
    [description appendFormat:@"\ttwoMonth=%@\n", self.twoMonth];
    [description appendFormat:@"\tmonthly=%@\n", self.monthly];
    [description appendFormat:@"\tweekly=%@\n", self.weekly];
    [description appendString:@"}>"];
    return description;
}


@end
