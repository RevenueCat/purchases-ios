//
//  RCPurchaserInfo.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCPurchaserInfo.h"
#import "RCPurchaserInfo+Protected.h"
#import "RCEntitlementInfos.h"
#import "RCEntitlementInfos+Protected.h"
#import "RCEntitlementInfo.h"
@import PurchasesCoreSwift;

@interface RCPurchaserInfo ()

@property (nonatomic) NSDictionary<NSString *, NSDate *> *expirationDatesByProduct;
@property (nonatomic) NSDictionary<NSString *, NSDate *> *purchaseDatesByProduct;
@property (nonatomic) NSSet<NSString *> *nonConsumablePurchases;
@property (nonatomic) NSArray<RCTransaction *> *nonSubscriptionTransactions;
@property (nonatomic, nullable) NSString *originalApplicationVersion;
@property (nonatomic, nullable) NSDate *originalPurchaseDate;
@property (nonatomic) NSDictionary *originalData;
@property (nonatomic, nullable) NSDate *requestDate;
@property (nonatomic) NSDate *firstSeen;
@property (nonatomic) RCEntitlementInfos *entitlements;
@property (nonatomic) NSString *originalAppUserId;
@property (nonatomic, nullable) NSString *schemaVersion;
@property (nonatomic, nullable) NSURL *managementURL;

@end

static NSDateFormatter *dateFormatter;
static dispatch_once_t onceToken;

@implementation RCPurchaserInfo

- (nullable instancetype)initWithData:(NSDictionary *)data {
    if (self = [super init]) {
        if (data[@"subscriber"] == nil) {
            return nil;
        }
        [self setUpDateFormatter];

        self.originalData = data;
        self.schemaVersion = data[@"schema_version"];
        self.requestDate = [dateFormatter dateFromString:(NSString *)data[@"request_date"]];

        NSDictionary *subscriberData = data[@"subscriber"];

        NSDictionary *subscriptions = subscriberData[@"subscriptions"];
        if (subscriptions == nil) {
            return nil;
        }

        [self configureWithSubscriberData:subscriberData subscriptions:subscriptions];
    }
    return self;
}

- (void)configureWithSubscriberData:(NSDictionary *)subscriberData subscriptions:(NSDictionary *)subscriptions {
    [self initializePurchasesAndEntitlementsWithSubscriberData:subscriberData subscriptions:subscriptions];
    [self initializeMetadataWithSubscriberData:subscriberData];
}

- (void)initializeMetadataWithSubscriberData:(NSDictionary *)subscriberData {
    NSObject *originalApplicationVersionOrNull = subscriberData[@"original_application_version"];
    self.originalApplicationVersion = [originalApplicationVersionOrNull isKindOfClass:[NSNull class]]
                                      ? nil
                                      : (NSString *)originalApplicationVersionOrNull;

    self.originalPurchaseDate = [self parseDate:subscriberData[@"original_purchase_date"]
                              withDateFormatter:dateFormatter];

    self.firstSeen = [self parseDate:subscriberData[@"first_seen"] withDateFormatter:dateFormatter];

    self.originalAppUserId = subscriberData[@"original_app_user_id"];

    self.managementURL = [self parseURL:subscriberData[@"management_url"]];
}

- (void)initializePurchasesAndEntitlementsWithSubscriberData:(NSDictionary *)subscriberData
                                               subscriptions:(NSDictionary *)subscriptions {
    NSDictionary<NSString *, NSArray *> *nonSubscriptionsData = subscriberData[@"non_subscriptions"];
    self.nonConsumablePurchases = [NSSet setWithArray:[nonSubscriptionsData allKeys]];
    
    RCTransactionsFactory *transactionsFactory = [[RCTransactionsFactory alloc] init];
    self.nonSubscriptionTransactions = [transactionsFactory nonSubscriptionTransactionsWithSubscriptionsData:nonSubscriptionsData dateFormatter:dateFormatter];

    NSMutableDictionary<NSString *, id> *nonSubscriptionsLatestPurchases = [[NSMutableDictionary alloc] init];
    for (NSString* productId in nonSubscriptionsData) {
        NSArray *arrayOfPurchases = nonSubscriptionsData[productId];
        if (arrayOfPurchases.count > 0) {
            nonSubscriptionsLatestPurchases[productId] = arrayOfPurchases[arrayOfPurchases.count - 1];
        }
    }

    NSMutableDictionary<NSString *, id> *allPurchases = [[NSMutableDictionary alloc] init];
    [allPurchases addEntriesFromDictionary:nonSubscriptionsLatestPurchases];
    [allPurchases addEntriesFromDictionary:subscriptions];
    NSDictionary *entitlements = subscriberData[@"entitlements"];
    self.entitlements = [[RCEntitlementInfos alloc] initWithEntitlementsData:entitlements
                                                               purchasesData:allPurchases
                                                               dateFormatter:dateFormatter
                                                                 requestDate:self.requestDate];

    self.expirationDatesByProduct = [self parseExpirationDate:subscriptions];
    self.purchaseDatesByProduct = [self parsePurchaseDate:allPurchases];
}

- (void)setUpDateFormatter {
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
        dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    });
}

- (nullable NSDate *)parseDate:(id)dateString withDateFormatter:(NSDateFormatter *)dateFormatter {
    if ([dateString isKindOfClass:NSString.class]) {
        return [dateFormatter dateFromString:(NSString *)dateString];
    }
    return nil;
}

- (nullable NSURL *)parseURL:(id)urlString {
    if ([urlString isKindOfClass:NSString.class]) {
        return [NSURL URLWithString:urlString];
    }
    return nil;
}

- (NSDictionary<NSString *, NSDate *> *)parseExpirationDate:(NSDictionary<NSString *, NSDictionary *> *)expirationDates {
    return [self parseDatesIn:expirationDates withLabel:@"expires_date"];
}

- (NSDictionary<NSString *, NSDate *> *)parsePurchaseDate:(NSDictionary<NSString *, NSDictionary *> *)purchaseDates {
    return [self parseDatesIn:purchaseDates withLabel:@"purchase_date"];
}

- (NSDictionary<NSString *, NSDate *> *)parseDatesIn:(NSDictionary<NSString *, NSDictionary *> *)dates
                                           withLabel:(NSString *)label {
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

- (NSSet<NSString *> *)allPurchasedProductIdentifiers {
    return [self.nonConsumablePurchases setByAddingObjectsFromArray:self.expirationDatesByProduct.allKeys];
}

- (NSSet<NSString *> *)activeKeys:(NSDictionary<NSString *, NSObject *> *)dates {
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

- (NSSet<NSString *> *)activeSubscriptions {
    return [self activeKeys:self.expirationDatesByProduct];
}

- (nullable NSDate *)latestExpirationDate {
    NSDate *maxDate = nil;
    
    for (NSDate *date in self.expirationDatesByProduct.allValues) {
        if (date.timeIntervalSince1970 > maxDate.timeIntervalSince1970) {
            maxDate = date;
        }
    }
    
    return maxDate;
}

- (NSSet<NSString *> *)activeEntitlements {
    return [NSSet setWithArray:self.entitlements.active.allKeys];
}

- (nullable NSDate *)expirationDateForProductIdentifier:(NSString *)productIdentifier {
    return self.expirationDatesByProduct[productIdentifier];
}

- (nullable NSDate *)purchaseDateForProductIdentifier:(NSString *)productIdentifier {
    NSObject *dateOrNull = self.purchaseDatesByProduct[productIdentifier];
    return [dateOrNull isKindOfClass:NSNull.class] ? nil : (NSDate *)dateOrNull;
}

- (nullable NSDate *)expirationDateForEntitlement:(NSString *)entitlementId {
    return self.entitlements[entitlementId].expirationDate;
}

- (nullable NSDate *)purchaseDateForEntitlement:(NSString *)entitlementId {
    return self.entitlements[entitlementId].latestPurchaseDate;
}

- (NSDictionary *)JSONObject {
    NSMutableDictionary *dictionary = [self.originalData mutableCopy];
    dictionary[@"schema_version"] = [RCPurchaserInfo currentSchemaVersion];
    return dictionary;
}

+ (NSString *)currentSchemaVersion {
    return @"2";
}

- (BOOL)isEqual:(RCPurchaserInfo *)other {
    BOOL isEqual = ([self.expirationDatesByProduct isEqual:other.expirationDatesByProduct]
                    && [self.purchaseDatesByProduct isEqual:other.purchaseDatesByProduct]
                    && [self.nonConsumablePurchases isEqual:other.nonConsumablePurchases]);
    
    isEqual &= ([self.entitlements isEqual:other.entitlements]);
    
    
    if (self.originalApplicationVersion != nil || other.originalApplicationVersion != nil) {
        isEqual &= ([self.originalApplicationVersion isEqual:other.originalApplicationVersion]);
    }
    
    return isEqual;
}

- (NSDictionary *)descriptionDictionaryForEntitlementInfo:(RCEntitlementInfo *)info {
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

- (NSString *)description {
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

    return [NSString stringWithFormat:@"<PurchaserInfo\n "
                                       "originalApplicationVersion: %@,\n "
                                       "latestExpirationDate: %@\n "
                                       "activeEntitlements: %@,\n "
                                       "activeSubscriptions: %@,\n "
                                       "nonConsumablePurchases: %@,\n "
                                       "requestDate: %@\n "
                                       "firstSeen: %@,\n"
                                       "originalAppUserId: %@,\n"
                                       "entitlements: %@,\n"
                                       ">",
                                       self.originalApplicationVersion,
                                       self.latestExpirationDate,
                                       activeEntitlements,
                                       activeSubscriptions,
                                       self.nonConsumablePurchases,
                                       self.requestDate,
                                       self.firstSeen,
                                       self.originalAppUserId,
                                       entitlements];
}

@end
