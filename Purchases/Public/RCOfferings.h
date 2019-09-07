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

- (RCOffering * _Nullable)offeringWithIdentifier:(NSString * _Nullable)identifier NS_SWIFT_NAME(offering(identifier:));

- (RCOffering * _Nullable)objectForKeyedSubscript:(NSString *)key;

- (NSString *)description;

@end

NS_ASSUME_NONNULL_END
