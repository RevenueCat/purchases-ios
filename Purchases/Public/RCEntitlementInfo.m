//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCEntitlementInfo.h"

@interface RCEntitlementInfo ()

@property (readwrite) NSString * identifier;
@property (readwrite) BOOL isActive;
@property (readwrite) RCPeriodType periodType;
@property (readwrite) NSDate * latestPurchaseDate;
@property (readwrite) NSDate * _Nullable originalPurchaseDate;
@property (readwrite) NSDate * _Nullable expirationDate;
@property (readwrite) RCStore store;
@property (readwrite) NSString * productIdentifier;
@property (readwrite) BOOL isSandbox;
@property (readwrite) NSDate * _Nullable unsubscribeDetectedAt;
@property (readwrite) NSDate * _Nullable billingIssueDetectedAt;
@property (readwrite) BOOL willRenew;

@end

@implementation RCEntitlementInfo


- (instancetype)initWithEntitlementId:(NSString *)entitlementId withEntitlementData:(NSDictionary<NSString *, id> *)entitlementData withProductData:(NSDictionary<NSString *, id> *)productData withDateFormatter:(NSDateFormatter *)dateFormatter withRequestDate:(NSDate *)requestDate
{
    if (self = [super init]) {
        self.identifier = entitlementId;
        self.isActive = [self checkIsActive:[self parseDate:entitlementData[@"expires_date"] withDateFormatter:dateFormatter] withRequestDate:requestDate];
        self.periodType = [self parsePeriodType:productData[@"period_type"]];
        self.latestPurchaseDate = [self parseDate:entitlementData[@"purchase_date"] withDateFormatter:dateFormatter];
        self.originalPurchaseDate = [self parseDate:productData[@"original_purchase_date"] withDateFormatter:dateFormatter];
        self.expirationDate = [self parseDate:productData[@"expires_date"] withDateFormatter:dateFormatter];
        self.store = [self parseStore:productData[@"store"]];
        self.productIdentifier = entitlementData[@"product_identifier"];
        self.isSandbox = [productData[@"is_sandbox"] boolValue];
        self.unsubscribeDetectedAt = [self parseDate:productData[@"unsubscribe_detected_at"] withDateFormatter:dateFormatter];
        self.billingIssueDetectedAt = [self parseDate:productData[@"billing_issues_detected_at"] withDateFormatter:dateFormatter];
        if ([entitlementData[@"expires_date"] isKindOfClass:NSNull.class]) { // TODO: test
            self.willRenew = true;
        } else {
            self.willRenew = self.unsubscribeDetectedAt == nil && self.billingIssueDetectedAt == nil;
        }
    }
    return self;
}

- (BOOL)checkIsActive:(NSDate * _Nullable)expirationDate withRequestDate:(NSDate *)requestDate
{
    return ((expirationDate == nil) || [self isAfterReferenceDate:expirationDate withRequestDate:requestDate]);
}

- (BOOL)isAfterReferenceDate:(NSDate *)date withRequestDate:requestDate {
    NSDate *referenceDate = requestDate ?: [NSDate date];
    return [date timeIntervalSinceDate:referenceDate] > 0;
}

- (NSDate * _Nullable)parseDate:(id)dateString withDateFormatter:(NSDateFormatter *)dateFormatter
{
    if ([dateString isKindOfClass:NSString.class]) {
        return [dateFormatter dateFromString:(NSString *)dateString];
    }
    return nil;
}

- (RCPeriodType)parsePeriodType:(NSString *)periodType
{
    if ([periodType isEqualToString:@"normal"]) {
        return RCNormal;
    } else if ([periodType isEqualToString:@"intro"]) {
        return RCIntro;
    } else if ([periodType isEqualToString:@"trial"]) {
        return RCTrial;
    }
    return RCNormal;
}

- (RCStore)parseStore:(NSString *)store
{
    if ([store isEqualToString:@"app_store"]) {
        return RCAppStore;
    } else if ([store isEqualToString:@"mac_app_store"]) {
        return RCMacAppStore;
    } else if ([store isEqualToString:@"play_store"]) {
        return RCPlayStore;
    } else if ([store isEqualToString:@"stripe"]) {
        return RCStripe;
    } else if ([store isEqualToString:@"promotional"]) {
        return RCPromotional;
    }
    return RCUnknownStore;
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"identifier=%@,\n", self.identifier];
    [description appendFormat:@"isActive=%d,\n", self.isActive];
    [description appendFormat:@"willRenew=%d,\n", self.willRenew];
    [description appendFormat:@"periodType=%li,\n", (long) self.periodType];
    [description appendFormat:@"latestPurchaseDate=%@,\n", self.latestPurchaseDate];
    [description appendFormat:@"originalPurchaseDate=%@,\n", self.originalPurchaseDate];
    [description appendFormat:@"expirationDate=%@,\n", self.expirationDate];
    [description appendFormat:@"store=%li,\n", (long) self.store];
    [description appendFormat:@"productIdentifier=%@,\n", self.productIdentifier];
    [description appendFormat:@"isSandbox=%d,\n", self.isSandbox];
    [description appendFormat:@"unsubscribeDetectedAt=%@,\n", self.unsubscribeDetectedAt];
    [description appendFormat:@"billingIssueDetectedAt=%@,\n", self.billingIssueDetectedAt];
    [description appendString:@">"];
    return description;
}

- (BOOL)isEqual:(id)other
{
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToInfo:other];
}

- (BOOL)isEqualToInfo:(RCEntitlementInfo *)info
{
    if (self == info)
        return YES;
    if (info == nil)
        return NO;
    if (self.identifier != info.identifier && ![self.identifier isEqualToString:info.identifier])
        return NO;
    if (self.isActive != info.isActive)
        return NO;
    if (self.willRenew != info.willRenew)
        return NO;
    if (self.periodType != info.periodType)
        return NO;
    if (self.latestPurchaseDate != info.latestPurchaseDate && ![self.latestPurchaseDate isEqualToDate:info.latestPurchaseDate])
        return NO;
    if (self.originalPurchaseDate != info.originalPurchaseDate && ![self.originalPurchaseDate isEqualToDate:info.originalPurchaseDate])
        return NO;
    if (self.expirationDate != info.expirationDate && ![self.expirationDate isEqualToDate:info.expirationDate])
        return NO;
    if (self.store != info.store)
        return NO;
    if (self.productIdentifier != info.productIdentifier && ![self.productIdentifier isEqualToString:info.productIdentifier])
        return NO;
    if (self.isSandbox != info.isSandbox)
        return NO;
    if (self.unsubscribeDetectedAt != info.unsubscribeDetectedAt && ![self.unsubscribeDetectedAt isEqualToDate:info.unsubscribeDetectedAt])
        return NO;
    if (self.billingIssueDetectedAt != info.billingIssueDetectedAt && ![self.billingIssueDetectedAt isEqualToDate:info.billingIssueDetectedAt])
        return NO;
    return YES;
}

- (NSUInteger)hash
{
    NSUInteger hash = [self.identifier hash];
    hash = hash * 31u + self.isActive;
    hash = hash * 31u + self.willRenew;
    hash = hash * 31u + (NSUInteger) self.periodType;
    hash = hash * 31u + [self.latestPurchaseDate hash];
    hash = hash * 31u + [self.originalPurchaseDate hash];
    hash = hash * 31u + [self.expirationDate hash];
    hash = hash * 31u + (NSUInteger) self.store;
    hash = hash * 31u + [self.productIdentifier hash];
    hash = hash * 31u + self.isSandbox;
    hash = hash * 31u + [self.unsubscribeDetectedAt hash];
    hash = hash * 31u + [self.billingIssueDetectedAt hash];
    return hash;
}


@end
