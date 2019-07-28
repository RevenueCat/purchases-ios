//
// Created by César de la Vega  on 2019-07-24.
//

#import <Foundation/Foundation.h>

@class RCEntitlementInfo;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(EntitlementInfos)
@interface RCEntitlementInfos : NSObject

@property (readonly) NSDictionary<NSString *, RCEntitlementInfo *> *all;
@property (readonly) NSDictionary<NSString *, RCEntitlementInfo *> *active;

- (instancetype)initWithEntitlements:(NSDictionary<NSString *, NSDictionary *> *)entitlements forPurchases:(NSDictionary<NSString *, id> *)purchases withDateFormatter:(NSDateFormatter *)dateFormatter withRequestDate:(NSDate *)requestDate;

- (RCEntitlementInfo *_Nullable)objectForKeyedSubscript:(id)key;

@end

NS_ASSUME_NONNULL_END
