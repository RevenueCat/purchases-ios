//
//  RCPackage.h
//  Purchases
//
//  Created by Jacob Eiting on 7/22/19.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SKProduct;

typedef NS_ENUM(NSInteger, RCPackageType) {
    RCPackageTypeCustom = -1,
    RCPackageTypeAnnual,
    RCPackageTypeSixMonth,
    RCPackageTypeThreeMonth,
    RCPackageTypeTwoMonth,
    RCPackageTypeMonthly,
    RCPackageTypeWeekly
} NS_SWIFT_NAME(PackageType);

NS_SWIFT_NAME(Package)
@interface RCPackage : NSObject

@property NSString * _Nonnull identifier;
@property RCPackageType packageType;
@property SKProduct *product;

@end

NS_ASSUME_NONNULL_END
