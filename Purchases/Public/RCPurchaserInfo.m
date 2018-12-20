//
//  RCPurchaserInfo.m
//  Purchases
//
//  Created by Jacob Eiting on 9/30/17.
//  Copyright © 2018 RevenueCat, Inc. All rights reserved.
//

#import "RCPurchaserInfo.h"
#import "RCPurchaserInfo+Protected.h"

@interface RCPurchaserInfo ()

@property (nonatomic) NSDictionary<NSString *, NSDate *> *expirationDatesByProduct;
@property (nonatomic) NSDictionary<NSString *, NSDate *> *purchaseDatesByProduct;
@property (nonatomic) NSDictionary<NSString *, NSObject *> *expirationDateByEntitlement;
@property (nonatomic) NSDictionary<NSString *, NSObject *> *purchaseDateByEntitlement;
@property (nonatomic) NSSet<NSString *> *nonConsumablePurchases;
@property (nonatomic) NSString *originalApplicationVersion;

@property (nonatomic) NSDictionary *originalData;
@property (nonatomic) NSDate * _Nullable requestDate;

@end

static NSDateFormatter *dateFormatter;
static dispatch_once_t onceToken;

@implementation RCPurchaserInfo

- (instancetype _Nullable)initWithData:(NSDictionary *)data
{
    if (self = [super init]) {
        if (data[@"subscriber"] == nil) {
            return nil;
        }
        
        self.originalData = data;
        
        NSDictionary *subscriberData = data[@"subscriber"];
        
        dispatch_once(&onceToken, ^{
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
            dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
            dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        });
        self.requestDate = [dateFormatter dateFromString:(NSString *)data[@"request_date"]];
        
        NSDictionary *subscriptions = subscriberData[@"subscriptions"];
        if (subscriptions == nil) {
            return nil;
        }
        
        NSDictionary *entitlements = subscriberData[@"entitlements"];
        self.expirationDateByEntitlement = [self parseExpirationDate:entitlements];
        self.purchaseDateByEntitlement = [self parsePurchaseDate:entitlements];
        
        NSDictionary<NSString *, id> *otherPurchases = subscriberData[@"other_purchases"];
        self.nonConsumablePurchases = [NSSet setWithArray:[otherPurchases allKeys]];
        
        NSMutableDictionary<NSString *, id> *allPurchases = [[NSMutableDictionary alloc] init];
        [allPurchases addEntriesFromDictionary:otherPurchases];
        [allPurchases addEntriesFromDictionary:subscriptions];
        
        self.expirationDatesByProduct = [self parseExpirationDate:subscriptions];
        self.purchaseDatesByProduct = [self parsePurchaseDate:allPurchases];
        
        NSString *originalApplicationVersion = subscriberData[@"original_application_version"];
        self.originalApplicationVersion = [originalApplicationVersion isKindOfClass:[NSNull class]] ? nil : originalApplicationVersion;
        
    }
    return self;
}

- (NSDictionary<NSString *, NSDate *> *)parseExpirationDate:(NSDictionary<NSString *, NSDictionary *> *)expirationDates
{
    return [self parseDatesIn:expirationDates withLabel:@"expires_date"];
}

- (NSDictionary<NSString *, NSDate *> *)parsePurchaseDate:(NSDictionary<NSString *, NSDictionary *> *)purchaseDates
{
    return [self parseDatesIn:purchaseDates withLabel:@"purchase_date"];
}

- (NSDictionary<NSString *, NSDate *> *)parseDatesIn:(NSDictionary<NSString *, NSDictionary *> *)dates
                                           withLabel:(NSString *)label
{
    NSMutableDictionary<NSString *, NSObject *> *parsedDates = [NSMutableDictionary new];

    for (NSString *identifier in dates) {
        id dateString = dates[identifier][label];

        if ([dateString isKindOfClass:NSString.class]) {
            NSDate *date = [dateFormatter dateFromString:(NSString *)dateString];

            if (date != nil) {
                parsedDates[identifier] = date;
            }
        } else {
            parsedDates[identifier] = [NSNull null];
        }
    }

    return [NSDictionary dictionaryWithDictionary:parsedDates];
}

- (NSSet<NSString *> *)allPurchasedProductIdentifiers
{
    return [self.nonConsumablePurchases setByAddingObjectsFromArray:self.expirationDatesByProduct.allKeys];
}

- (NSSet<NSString *> *)activeKeys:(NSDictionary<NSString *, NSObject *> *)dates
{
    NSMutableSet *activeSubscriptions = [NSMutableSet setWithCapacity:dates.count];
    
    for (NSString *identifier in dates) {
        NSDate *dateOrNull = (NSDate *)dates[identifier];
        if ([dateOrNull isKindOfClass:NSNull.class] || [self isAfterReferenceDate:dateOrNull]) {
            [activeSubscriptions addObject:identifier];
        }
    }
    
    return [NSSet setWithSet:activeSubscriptions];
}

- (BOOL)isAfterReferenceDate:(NSDate *)date {
    NSDate *referenceDate = self.requestDate ?: [NSDate date];
    return [date timeIntervalSinceDate:referenceDate] > 0;
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

- (NSSet<NSString *> *)activeEntitlements
{
    return [self activeKeys:self.expirationDateByEntitlement];
}

- (NSDate *)expirationDateForProductIdentifier:(NSString *)productIdentifier
{
    return self.expirationDatesByProduct[productIdentifier];
}

- (NSDate * _Nullable)purchaseDateForProductIdentifier:(NSString *)productIdentifier
{
    NSObject *dateOrNull = self.purchaseDatesByProduct[productIdentifier];
    return [dateOrNull isKindOfClass:NSNull.class] ? nil : (NSDate *)dateOrNull;
}

- (NSDate * _Nullable)expirationDateForEntitlement:(NSString *)entitlementId
{
    NSObject *dateOrNull = self.expirationDateByEntitlement[entitlementId];
    return [dateOrNull isKindOfClass:NSNull.class] ? nil : (NSDate *)dateOrNull;
}

- (NSDate * _Nullable)purchaseDateForEntitlement:(NSString *)entitlementId
{
    NSObject *dateOrNull = self.purchaseDateByEntitlement[entitlementId];
    return [dateOrNull isKindOfClass:NSNull.class] ? nil : (NSDate *)dateOrNull;
}

- (NSDictionary * _Nonnull)JSONObject {
    return self.originalData;
}

- (BOOL)isEqual:(RCPurchaserInfo *)other
{
    return ([self.expirationDatesByProduct isEqual:other.expirationDatesByProduct]
            && [self.purchaseDatesByProduct isEqual:other.purchaseDatesByProduct]
            && [self.expirationDateByEntitlement isEqual:other.expirationDateByEntitlement]
            && [self.purchaseDateByEntitlement isEqual:other.purchaseDateByEntitlement]
            && [self.nonConsumablePurchases isEqual:other.nonConsumablePurchases]
            && [self.originalApplicationVersion isEqual:other.originalApplicationVersion]);
}

@end
