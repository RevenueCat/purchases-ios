//
//  RCEntitlementInfos.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCEntitlementInfos.h"
#import "RCEntitlementInfo.h"
#import "RCEntitlementInfo+Protected.h"


@interface RCEntitlementInfos ()
@property (readwrite) NSDictionary<NSString *, RCEntitlementInfo *> *all;
@end

@implementation RCEntitlementInfos

- (instancetype)initWithEntitlementsData:(NSDictionary *)entitlementsData purchasesData:(NSDictionary *)purchasesData dateFormatter:(NSDateFormatter *)dateFormatter requestDate:(NSDate *)requestDate
{
    if (self = [super init]) {
        NSMutableDictionary<NSString *, RCEntitlementInfo *> *entitlementInfos = [[NSMutableDictionary alloc] init];
        for (NSString *identifier in entitlementsData) {
            id entitlement = entitlementsData[identifier];
            if ([entitlement isKindOfClass:NSDictionary.class]) {
                id productIdentifier = entitlement[@"product_identifier"];
                if ([productIdentifier isKindOfClass:NSString.class]) {
                    id productData = purchasesData[productIdentifier];
                    if ([productData isKindOfClass:NSDictionary.class]) {
                        RCEntitlementInfo *entitlementInfo = [[RCEntitlementInfo alloc] initWithEntitlementId:identifier entitlementData:entitlement productData:productData dateFormatter:dateFormatter requestDate:requestDate];
                        entitlementInfos[identifier] = entitlementInfo;
                    }
                }
            }
        }
        self.all = [NSDictionary dictionaryWithDictionary:entitlementInfos];
    }
    return self;
}

- (NSDictionary<NSString *, RCEntitlementInfo *> *)active
{
    NSMutableDictionary<NSString *, RCEntitlementInfo *> *activeInfos = [[NSMutableDictionary alloc] init];
    for (NSString *identifier in self.all) {
        RCEntitlementInfo *info = self.all[identifier];
        if (info.isActive) {
            activeInfos[identifier] = info;
        }
    }
    return activeInfos.copy;
}

- (nullable RCEntitlementInfo *)objectForKeyedSubscript:(id)key
{
    return self.all[key];
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.all=%@", self.all];
    [description appendFormat:@", self.active=%@", self.active];
    [description appendString:@">"];
    return description;
}

- (BOOL)isEqual:(id)other
{
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToInfos:other];
}

- (BOOL)isEqualToInfos:(RCEntitlementInfos *)infos
{
    if (self == infos)
        return YES;
    if (infos == nil)
        return NO;
    if (self.all != infos.all && ![self.all isEqualToDictionary:infos.all])
        return NO;
    return YES;
}

@end
