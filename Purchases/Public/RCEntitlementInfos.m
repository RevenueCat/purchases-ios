//
// Created by César de la Vega  on 2019-07-24.
//

#import "RCEntitlementInfos.h"
#import "RCEntitlementInfo.h"


@interface RCEntitlementInfos ()
@property (readwrite) NSDictionary<NSString *, RCEntitlementInfo *> *all;
@end

@implementation RCEntitlementInfos

- (instancetype)initWithEntitlements:(NSDictionary<NSString *, NSDictionary *> *)entitlements forPurchases:(NSDictionary<NSString *, id> *)purchases withDateFormatter:(NSDateFormatter *)dateFormatter withRequestDate:(NSDate *)requestDate
{
    if (self = [super init]) {
        NSMutableDictionary<NSString *, RCEntitlementInfo *> *entitlementInfos = [[NSMutableDictionary alloc] init];
        for (NSString *identifier in entitlements) {
            id entitlement = entitlements[identifier];
            
            if ([entitlement isKindOfClass:NSDictionary.class]) {
                id productIdentifier = entitlement[@"product_identifier"];
                if ([productIdentifier isKindOfClass:NSString.class]) {
                    id productData = purchases[productIdentifier];
                    if ([productData isKindOfClass:NSDictionary.class]) {
                        RCEntitlementInfo *entitlementInfo = [[RCEntitlementInfo alloc] initWithEntitlementId:identifier withEntitlementData:entitlement withProductData:productData withDateFormatter:dateFormatter withRequestDate:requestDate];
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

- (RCEntitlementInfo * _Nullable)objectForKeyedSubscript:(id)key
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

- (NSUInteger)hash
{
    return [self.all hash];
}


@end
