//
//  RCOffering+Protected.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat, Inc. All rights reserved.
//

#import "RCOfferings.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCOfferings (Protected)

@property (readonly) NSDictionary<NSString *, RCOffering *> *all;

- (instancetype)initWithOfferings:(NSDictionary<NSString *, RCOffering *> *)offerings currentOfferingID:(NSString *)currentOfferingID;

@end

NS_ASSUME_NONNULL_END