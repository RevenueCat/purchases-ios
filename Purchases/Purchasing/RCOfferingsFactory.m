//
//  RCOfferingsFactory.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "RCOfferingsFactory.h"
@import PurchasesCoreSwift;

@interface RCOfferingsFactory ()

@end

@implementation RCOfferingsFactory

- (RCOfferings *)createOfferingsWithProducts:(NSDictionary<NSString *, SKProduct *> *)products data:(NSDictionary *)data
{
    NSArray *offeringsData = data[@"offerings"];
    NSString *currentOfferingID = data[@"current_offering_id"];
    if (offeringsData && currentOfferingID) {
        NSMutableDictionary *offerings = [NSMutableDictionary dictionary];
        for (NSDictionary *offeringData in offeringsData) {
            RCOffering *offering = [self createOfferingWithProducts:products offeringData:offeringData];
            if (offering) {
                offerings[offering.identifier] = offering;
            }
        }

        // TODO (during migration of this file): remove this NSNull handling. We have a test that was failing since
        // nil was getting bridged to NSNull and that was passed in to the Offerings.init which only expects String?.
        if (currentOfferingID == (NSString *)NSNull.null) {
            currentOfferingID = nil;
        }
        // End NSNull handling

        return [[RCOfferings alloc] initWithOfferings:[NSDictionary dictionaryWithDictionary:offerings] currentOfferingID:currentOfferingID];
    }
    return nil;
}

- (nullable RCOffering *)createOfferingWithProducts:(NSDictionary<NSString *, SKProduct *> *)products offeringData:(NSDictionary *)offeringData
{
    NSMutableArray<RCPackage *> *availablePackages = [NSMutableArray array];
    NSString *offeringIdentifier = offeringData[@"identifier"];
    for (NSDictionary *packageData in offeringData[@"packages"]) {
        RCPackage *package = [self createPackageWithData:packageData products:products offeringIdentifier:offeringIdentifier];
        if (package) {
            [availablePackages addObject:package];
        }
    }

    if (availablePackages.count != 0) {
        return [[RCOffering alloc] initWithIdentifier:offeringIdentifier serverDescription:offeringData[@"description"] availablePackages:[NSArray arrayWithArray:availablePackages]];
    }
    return nil;
}

- (nullable RCPackage *)createPackageWithData:(NSDictionary *)data products:(NSDictionary<NSString *, SKProduct *> *)products offeringIdentifier:(NSString *)offeringIdentifier
{
    SKProduct *product = products[data[@"platform_product_identifier"]];
    if (product) {
        NSString *identifier = data[@"identifier"];
        RCPackageType packageType = [RCPackage packageTypeFrom:identifier];
        
        return [[RCPackage alloc] initWithIdentifier:identifier packageType:packageType product:product offeringIdentifier:offeringIdentifier];
    }
    return nil;
}

@end
