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
/**
 TODO
 */
NS_SWIFT_NAME(EntitlementInfos)
@interface RCEntitlementInfos : NSObject
/**
TODO
*/
@property (readonly) NSDictionary<NSString *, RCEntitlementInfo *> *all;
/**
TODO
*/
@property (readonly) NSDictionary<NSString *, RCEntitlementInfo *> *active;

/// :nodoc:
- (nullable RCEntitlementInfo *)objectForKeyedSubscript:(id)key;

@end

NS_ASSUME_NONNULL_END
