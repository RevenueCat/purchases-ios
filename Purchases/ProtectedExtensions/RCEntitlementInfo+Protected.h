//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCEntitlementInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCEntitlementInfo (Protected)

- (instancetype)initWithEntitlementId:(NSString *)entitlementId entitlementData:(NSDictionary *)entitlementData productData:(NSDictionary *)productData dateFormatter:(NSDateFormatter *)dateFormatter requestDate:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END
