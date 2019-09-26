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
/**
TODO
*/
NS_SWIFT_NAME(Offerings)
@interface RCOfferings : NSObject
/**
TODO
*/
@property (readonly, nullable) RCOffering *current;
/**
TODO
*/
- (nullable RCOffering *)offeringWithIdentifier:(nullable NSString *)identifier NS_SWIFT_NAME(offering(identifier:));
/// :nodoc:
- (nullable RCOffering *)objectForKeyedSubscript:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
