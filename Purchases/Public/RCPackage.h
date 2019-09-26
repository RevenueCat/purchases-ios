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
TODO
*/
typedef NS_ENUM(NSInteger, RCPackageType) {
    /**
    TODO
    */
    RCPackageTypeCustom = -1,
    /**
    TODO
    */
    RCPackageTypeLifetime,
    /**
    TODO
    */
    RCPackageTypeAnnual,
    /**
    TODO
    */
    RCPackageTypeSixMonth,
    /**
    TODO
    */
    RCPackageTypeThreeMonth,
    /**
    TODO
    */
    RCPackageTypeTwoMonth,
    /**
    TODO
    */
    RCPackageTypeMonthly,
    /**
    TODO
    */
    RCPackageTypeWeekly
} NS_SWIFT_NAME(PackageType);
/**
TODO
*/
NS_SWIFT_NAME(Package)
@interface RCPackage : NSObject
/**
TODO
*/
@property (readonly) NSString *identifier;
/**
TODO
*/
@property (readonly) RCPackageType packageType;
/**
TODO
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
