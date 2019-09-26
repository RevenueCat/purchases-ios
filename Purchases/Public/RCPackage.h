//
//  RCPackage.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SKProduct;

typedef NS_ENUM(NSInteger, RCPackageType) {
    RCPackageTypeCustom = -1,
    RCPackageTypeLifetime,
    RCPackageTypeAnnual,
    RCPackageTypeSixMonth,
    RCPackageTypeThreeMonth,
    RCPackageTypeTwoMonth,
    RCPackageTypeMonthly,
    RCPackageTypeWeekly
} NS_SWIFT_NAME(PackageType);

NS_SWIFT_NAME(Package)
@interface RCPackage : NSObject

@property (readonly) NSString *identifier;
@property (readonly) RCPackageType packageType;
@property (readonly) SKProduct *product;

/**
 @return A String containing the localized price
 */
@property (readonly) NSString *localizedPriceString;

/**
 @return A String containing the localized introductory price
 */
@property (readonly) NSString *localizedIntroductoryPriceString;

@end

NS_ASSUME_NONNULL_END
