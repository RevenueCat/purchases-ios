//
//  RCOffering.m
//  Purchases
//
//  Created by Jacob Eiting on 6/2/18.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import "RCOffering.h"
#import "RCPackage.h"

@interface RCOffering ()

@property (readwrite, nonatomic) NSString *activeProductIdentifier;
@property (readwrite, nonatomic) SKProduct *activeProduct;
@property (readwrite) NSString *identifier;
@property (readwrite) NSString *serverDescription;
@property (readwrite) NSArray<RCPackage *> *availablePackages;
@property (readwrite) RCPackage * _Nullable lifetime;
@property (readwrite) RCPackage * _Nullable annual;
@property (readwrite) RCPackage * _Nullable sixMonth;
@property (readwrite) RCPackage * _Nullable threeMonth;
@property (readwrite) RCPackage * _Nullable twoMonth;
@property (readwrite) RCPackage * _Nullable monthly;
@property (readwrite) RCPackage * _Nullable weekly;

@end

@implementation RCOffering

- (instancetype)initWithIdentifier:(NSString *)identifier serverDescription:(NSString *)serverDescription availablePackages:(NSArray<RCPackage *> *)availablePackages
{
    self = [super init];
    if (self) {
        self.identifier = identifier;
        self.serverDescription = serverDescription;
        self.availablePackages = availablePackages;
        for(RCPackage *package in availablePackages) {
            switch (package.packageType) {
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

- (RCPackage * _Nullable)packageWithIdentifier:(NSString * _Nullable)identifier
{
    for(RCPackage *package in self.availablePackages) {
        if ([package.identifier isEqualToString:identifier]) {
            return package;
        }
    }
    return nil;
}

- (RCPackage *_Nullable)objectForKeyedSubscript:(NSString *)key
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
