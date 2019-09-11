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
- (NSString *)localizedPriceString;

/**
 @return A String containing the localized introductory price
 */
- (NSString *)localizedIntroductoryPriceString;

@end

NS_ASSUME_NONNULL_END
