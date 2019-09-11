//
//  RCOfferings.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCOffering;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Offerings)
@interface RCOfferings : NSObject

@property (readonly) RCOffering *currentOffering NS_SWIFT_NAME(current);

- (nullable RCOffering *)offeringWithIdentifier:(nullable NSString *)identifier NS_SWIFT_NAME(offering(identifier:));

- (nullable RCOffering *)objectForKeyedSubscript:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
