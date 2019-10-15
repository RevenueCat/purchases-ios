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

/**
 Enumeration of all possible Package types.
*/
typedef NS_ENUM(NSInteger, RCPackageType) {
    /// A package that was defined with a custom identifier.
    RCPackageTypeUnknown = -2,
    /// A package that was defined with a custom identifier.
    RCPackageTypeCustom,
    /// A package configured with the predefined lifetime identifier.
    RCPackageTypeLifetime,
    /// A package configured with the predefined annual identifier.
    RCPackageTypeAnnual,
    /// A package configured with the predefined six month identifier.
    RCPackageTypeSixMonth,
    /// A package configured with the predefined three month identifier.
    RCPackageTypeThreeMonth,
    /// A package configured with the predefined two month identifier.
    RCPackageTypeTwoMonth,
    /// A package configured with the predefined monthly identifier.
    RCPackageTypeMonthly,
    /// A package configured with the predefined weekly identifier.
    RCPackageTypeWeekly
} NS_SWIFT_NAME(Purchases.PackageType);

/**
 Contains information about the product available for the user to purchase. For more info see https://docs.revenuecat.com/docs/entitlements
*/
NS_SWIFT_NAME(Purchases.Package)
@interface RCPackage : NSObject

/**
 Unique identifier for this package. Can be one a predefined package type or a custom one.
*/
@property (readonly) NSString *identifier;

/**
 Package type for the product. Will be one of `RCPackageType`.
*/
@property (readonly) RCPackageType packageType;

/**
 `SKProduct` assigned to this package. https://developer.apple.com/documentation/storekit/skproduct
*/
@property (readonly) SKProduct *product;

/**
 A String containing the localized price
 */
@property (readonly) NSString *localizedPriceString;

/**
 A String containing the localized introductory price
 */
@property (readonly) NSString *localizedIntroductoryPriceString;

@end

NS_ASSUME_NONNULL_END
