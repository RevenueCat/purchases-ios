//
//  RCPackage+Protected.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright (c) 2019 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCPackage.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCPackage (Protected)

+ (nullable NSString *)getStringFromPackageType:(RCPackageType)packageType;

+ (RCPackageType)getPackageTypeFromString:(NSString *)string;

- (instancetype)initWithIdentifier:(NSString *)identifier packageType:(RCPackageType)packageType product:(SKProduct *)product;

@end

NS_ASSUME_NONNULL_END
