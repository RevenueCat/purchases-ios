//
//  RCOfferingsFactory.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "RCOfferingsFactory.h"
#import "RCOffering.h"
#import "RCPackage.h"
#import "RCOfferings.h"
#import "RCOfferings+Protected.h"
#import "RCPackage+Protected.h"
#import "RCOffering+Protected.h"


@interface RCOfferingsFactory ()

@end

@implementation RCOfferingsFactory

+ (RCOfferings *)createOfferingsWithProducts:(NSDictionary<NSString *, SKProduct *> *)products data:(NSDictionary *)data;
{
    NSArray *offeringsData = data[@"offerings"];
    NSMutableDictionary *offerings = [NSMutableDictionary dictionary];
    for (NSDictionary *offeringData in offeringsData) {
        RCOffering *offering = [self createOfferingWithProducts:products offeringData:offeringData];
        if (offering) {
            offerings[offering.identifier] = offering;
        }
    }

    return [[RCOfferings alloc] initWithOfferings:[NSDictionary dictionaryWithDictionary:offerings] currentOfferingID:data[@"current_offering_id"]];
}

+ (RCOffering * _Nullable)createOfferingWithProducts:(NSDictionary<NSString *, SKProduct *> *)products offeringData:(NSDictionary *)offeringData
{
    NSMutableArray<RCPackage *> *availablePackages = [NSMutableArray array];
    for (NSDictionary *packageData in offeringData[@"packages"]) {
        RCPackage *package = [self createPackageWithData:packageData products:products];
        if (package) {
            [availablePackages addObject:package];
        }
    }

    if (availablePackages.count != 0) {
        return [[RCOffering alloc] initWithIdentifier:offeringData[@"identifier"] serverDescription:offeringData[@"description"] availablePackages:[NSArray arrayWithArray:availablePackages]];
    }
    return nil;
}

+ (RCPackage *_Nullable)createPackageWithData:(NSDictionary *)data products:(NSDictionary<NSString *, SKProduct *> *)products
{
    SKProduct *product = products[data[@"platform_product_identifier"]];
    if (product) {
        NSString *identifier = data[@"identifier"];
        enum RCPackageType packageType;
        if ([identifier isEqualToString:@"$rc_lifetime"]) {
            packageType = RCPackageTypeLifetime;
        } else if ([identifier isEqualToString:@"$rc_annual"]) {
            packageType = RCPackageTypeAnnual;
        } else if ([identifier isEqualToString:@"$rc_six_month"]) {
            packageType = RCPackageTypeSixMonth;
        } else if ([identifier isEqualToString:@"$rc_three_month"]) {
            packageType = RCPackageTypeThreeMonth;
        } else if ([identifier isEqualToString:@"$rc_two_month"]) {
            packageType = RCPackageTypeTwoMonth;
        } else if ([identifier isEqualToString:@"$rc_monthly"]) {
            packageType = RCPackageTypeMonthly;
        } else if ([identifier isEqualToString:@"$rc_weekly"]) {
            packageType = RCPackageTypeWeekly;
        } else {
            packageType = RCPackageTypeCustom;
        }
        return [[RCPackage alloc] initWithIdentifier:identifier packageType:packageType product:product];
    }
    return nil;
}

@end
