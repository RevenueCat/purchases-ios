//
//  RCOffering+Protected.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat, Inc. All rights reserved.
//

#import "RCOffering.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCOffering (Protected)

- (instancetype)initWithIdentifier:(NSString *)identifier serverDescription:(NSString *)serverDescription availablePackages:(NSArray<RCPackage *> *)availablePackages;

@end

NS_ASSUME_NONNULL_END
