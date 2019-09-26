//
//  RCEntitlementInfos.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCEntitlementInfo;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(EntitlementInfos)
@interface RCEntitlementInfos : NSObject

@property (readonly) NSDictionary<NSString *, RCEntitlementInfo *> *all;
@property (readonly) NSDictionary<NSString *, RCEntitlementInfo *> *active;

- (RCEntitlementInfo * _Nullable)objectForKeyedSubscript:(id)key;

@end

NS_ASSUME_NONNULL_END
