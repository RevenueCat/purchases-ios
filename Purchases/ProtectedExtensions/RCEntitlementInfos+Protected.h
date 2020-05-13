//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCEntitlementInfos.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCEntitlementInfos (Protected)

- (instancetype)initWithEntitlementsData:(NSDictionary *)entitlementsData purchasesData:(NSDictionary *)purchasesData dateFormatter:(NSDateFormatter *)dateFormatter requestDate:(NSDate *)requestDate;

@end

NS_ASSUME_NONNULL_END
