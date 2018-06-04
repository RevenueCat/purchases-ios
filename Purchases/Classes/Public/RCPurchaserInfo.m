//
//  RCPurchaserInfo.m
//  Purchases
//
//  Created by Jacob Eiting on 9/30/17.
//  Copyright © 2017 RevenueCat, Inc. All rights reserved.
//

#import "RCPurchaserInfo.h"

@interface RCPurchaserInfo ()

@property (nonatomic) NSDictionary<NSString *, NSDate *> *expirationDatesByProduct;
@property (nonatomic) NSDictionary<NSString *, NSDate *> *expirationDateByEntitlement;
@property (nonatomic) NSSet<NSString *> *nonConsumablePurchases;
@property (nonatomic) NSString *originalApplicationVersion;

@property (nonatomic) NSDictionary *originalData;

@end

static NSDateFormatter *dateFormatter;
static dispatch_once_t onceToken;

@implementation RCPurchaserInfo

- (instancetype _Nullable)initWithData:(NSDictionary *)data
{
    if (self == [super init]) {
        if (data[@"subscriber"] == nil) {
            return nil;
        }

        self.originalData = data;

        NSDictionary *subscriberData = data[@"subscriber"];

        dispatch_once(&onceToken, ^{
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
            dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
        });
        
        NSMutableDictionary<NSString *, NSDate *> *dates = [NSMutableDictionary new];

        NSDictionary *subscriptions = subscriberData[@"subscriptions"];
        if (subscriptions == nil) {
            return nil;
        }

        for (NSString *productID in subscriptions) {
            NSString *dateString = subscriptions[productID][@"expires_date"];
            NSDate *date = [dateFormatter dateFromString:dateString];

            if (date == nil) {
                return nil;
            }

            dates[productID] = date;
        }

        self.expirationDatesByProduct = [NSDictionary dictionaryWithDictionary:dates];

        dates = [NSMutableDictionary new];
        NSDictionary *entitlements = subscriberData[@"entitlements"];
        for (NSString *entitlementID in entitlements) {
            NSString *dateString = entitlements[entitlementID][@"expires_date"];
            NSDate *date = [dateFormatter dateFromString:dateString];

            if (date == nil) {
                return nil;
            }

            dates[entitlementID] = date;
        }

        self.expirationDateByEntitlement = [NSDictionary dictionaryWithDictionary:dates];

        NSDictionary<NSString *, id> *otherPurchases = subscriberData[@"other_purchases"];
        self.nonConsumablePurchases = [NSSet setWithArray:[otherPurchases allKeys]];

        NSString *originalApplicationVersion = subscriberData[@"original_application_version"];
        self.originalApplicationVersion = [originalApplicationVersion isKindOfClass:[NSNull class]] ? nil : originalApplicationVersion;

    }
    return self;
}

- (NSSet<NSString *> *)allPurchasedProductIdentifiers
{
    return [self.nonConsumablePurchases setByAddingObjectsFromArray:self.expirationDatesByProduct.allKeys];
}

- (NSSet<NSString *> *)activeKeys:(NSDictionary<NSString *, NSDate *> *)dates
{
    NSMutableSet *activeSubscriptions = [NSMutableSet setWithCapacity:dates.count];

    for (NSString *productIdentifier in dates) {
        if (dates[productIdentifier].timeIntervalSinceNow > 0) {
            [activeSubscriptions addObject:productIdentifier];
        }
    }

    return [NSSet setWithSet:activeSubscriptions];
}

- (NSSet<NSString *> *)activeSubscriptions
{
    return [self activeKeys:self.expirationDatesByProduct];
}

- (NSDate * _Nullable)latestExpirationDate
{
    NSDate *maxDate = nil;

    for (NSDate *date in self.expirationDatesByProduct.allValues) {
        if (date.timeIntervalSince1970 > maxDate.timeIntervalSince1970) {
            maxDate = date;
        }
    }

    return maxDate;
}

- (NSDate *)expirationDateForProductIdentifier:(NSString *)productIdentifier
{
    return self.expirationDatesByProduct[productIdentifier];
}

- (NSSet<NSString *> *)activeEntitlements
{
    return [self activeKeys:self.expirationDateByEntitlement];
}

- (NSDate *)expirationDateForEntitlement:(NSString *)entitlementId
{
    return self.expirationDateByEntitlement[entitlementId];
}


- (NSDictionary * _Nonnull)JSONObject {
    return self.originalData;
}

@end
