//
//  RCPurchaserInfo.m
//  Purchases
//
//  Created by Jacob Eiting on 9/30/17.
//  Copyright © 2019 RevenueCat, Inc. All rights reserved.
//

#import "RCPurchaserInfo.h"
#import "RCPurchaserInfo+Protected.h"
#import "RCEntitlementInfos.h"
#import "RCEntitlementInfos+Protected.h"
#import "RCEntitlementInfo.h"

@interface RCPurchaserInfo ()

@property (nonatomic) NSDictionary<NSString *, NSDate *> *expirationDatesByProduct;
@property (nonatomic) NSDictionary<NSString *, NSDate *> *purchaseDatesByProduct;
@property (nonatomic) NSSet<NSString *> *nonConsumablePurchases;
@property (nonatomic) NSString *originalApplicationVersion;
@property (nonatomic) NSDictionary *originalData;
@property (nonatomic) NSDate * _Nullable requestDate;
@property (nonatomic) NSDate *firstSeen;
@property (nonatomic) RCEntitlementInfos *entitlements;
@property (nonatomic) NSString *originalAppUserId;
@property (nonatomic) NSString * _Nullable schemaVersion;

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
        self.schemaVersion = data[@"schema_version"];
        
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
        

        NSDictionary<NSString *, NSArray *> *nonSubscriptions = subscriberData[@"non_subscriptions"];
        self.nonConsumablePurchases = [NSSet setWithArray:[nonSubscriptions allKeys]];

        NSMutableDictionary<NSString *, id> *nonSubscriptionsLatestPurchases = [[NSMutableDictionary alloc] init];
        for (NSString* productId in nonSubscriptions) {
            NSArray *arrayOfPurchases = nonSubscriptions[productId];
            if (arrayOfPurchases.count > 0) {
                nonSubscriptionsLatestPurchases[productId] = arrayOfPurchases[arrayOfPurchases.count - 1];
            }
        }
        
        NSMutableDictionary<NSString *, id> *allPurchases = [[NSMutableDictionary alloc] init];
        [allPurchases addEntriesFromDictionary:nonSubscriptionsLatestPurchases];
        [allPurchases addEntriesFromDictionary:subscriptions];
        
        self.expirationDatesByProduct = [self parseExpirationDate:subscriptions];
        self.purchaseDatesByProduct = [self parsePurchaseDate:allPurchases];
        
        NSString *originalApplicationVersion = subscriberData[@"original_application_version"];
        self.originalApplicationVersion = [originalApplicationVersion isKindOfClass:[NSNull class]] ? nil : originalApplicationVersion;

        self.firstSeen = [self parseDate:subscriberData[@"first_seen"] withDateFormatter:dateFormatter];
        
        NSDictionary *entitlements = subscriberData[@"entitlements"];
        
        self.entitlements = [[RCEntitlementInfos alloc] initWithEntitlementsData:entitlements purchasesData:allPurchases dateFormatter:dateFormatter requestDate:self.requestDate];
        self.originalAppUserId = subscriberData[@"original_app_user_id"];
    }
    return self;
}

- (NSDate * _Nullable)parseDate:(id)dateString withDateFormatter:(NSDateFormatter *)dateFormatter
{
    if ([dateString isKindOfClass:NSString.class]) {
        return [dateFormatter dateFromString:(NSString *)dateString];
    }
    return nil;
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
    return [NSSet setWithArray:self.entitlements.active.allKeys];
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
    return self.entitlements[entitlementId].expirationDate;
}

- (NSDate * _Nullable)purchaseDateForEntitlement:(NSString *)entitlementId
{
    return self.entitlements[entitlementId].latestPurchaseDate;
}

- (NSDictionary * _Nonnull)JSONObject {
    NSMutableDictionary *dictionary = [self.originalData mutableCopy];
    dictionary[@"schema_version"] = [RCPurchaserInfo currentSchemaVersion];
    return dictionary;
}

+ (NSString *)currentSchemaVersion {
    return @"2";
}

- (BOOL)isEqual:(RCPurchaserInfo *)other
{
    BOOL isEqual = ([self.expirationDatesByProduct isEqual:other.expirationDatesByProduct]
                    && [self.purchaseDatesByProduct isEqual:other.purchaseDatesByProduct]
                    && [self.nonConsumablePurchases isEqual:other.nonConsumablePurchases]);
    
    isEqual &= ([self.entitlements isEqual:other.entitlements]);
    
    
    if (self.originalApplicationVersion != nil || other.originalApplicationVersion != nil) {
        isEqual &= ([self.originalApplicationVersion isEqual:other.originalApplicationVersion]);
    }
    
    return isEqual;
}

- (NSDictionary *)descriptionDictionaryForEntitlementInfo:(RCEntitlementInfo *)info
{
    return @{
             @"expiresDate": info.expirationDate ?: @"null",
             @"latestPurchaseDate": info.latestPurchaseDate ?: @"null",
             @"originalPurchaseDate": info.originalPurchaseDate ?: @"null",
             @"periodType": info.periodType ? @(info.periodType) : @"null",
             @"isActive": info.isActive ? @"Yes" : @"No",
             @"willRenew": info.willRenew ? @"Yes" : @"No",
             @"store": @(info.store),
             @"productIdentifier": info.productIdentifier ?: @"null",
             @"isSandbox": info.isSandbox ? @"Yes" : @"No",
             @"unsubscribeDetectedAt": info.unsubscribeDetectedAt ?: @"null",
             @"billingIssueDetectedAt": info.billingIssueDetectedAt ?: @"null"
             };
}

- (NSString *)description
{
    NSMutableDictionary *activeSubscriptions = [NSMutableDictionary dictionary];
    for (NSString *activeSubscriptionId in self.activeSubscriptions) {
        activeSubscriptions[activeSubscriptionId] = @{
                                                      @"expiresDate": [self expirationDateForProductIdentifier:activeSubscriptionId] ?: @"null",
                                                      };
    }

    NSMutableDictionary *activeEntitlements = [NSMutableDictionary dictionary];
    for (NSString *entitlementId in self.entitlements.active) {
        activeEntitlements[entitlementId] = [self descriptionDictionaryForEntitlementInfo:self.entitlements.active[entitlementId]];
    }

    NSMutableDictionary *entitlements = [NSMutableDictionary dictionary];
    for (NSString *entitlementId in self.entitlements.all) {
        entitlements[entitlementId] = [self descriptionDictionaryForEntitlementInfo:self.entitlements[entitlementId]];
    }

    return [NSString stringWithFormat:@"<PurchaserInfo\n originalApplicationVersion: %@,\n latestExpirationDate: %@\n activeEntitlements: %@,\n activeSubscriptions: %@,\n nonConsumablePurchases: %@,\n requestDate: %@\nfirstSeen: %@,\noriginalAppUserId: %@,\nentitlements: %@,\n>", self.originalApplicationVersion, self.latestExpirationDate, activeEntitlements, activeSubscriptions, self.nonConsumablePurchases, self.requestDate, self.firstSeen, self.originalAppUserId, entitlements];
}

@end
