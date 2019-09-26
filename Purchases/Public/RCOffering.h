//
//  RCOffering.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SKProduct;
@class RCPackage, RCOffering;

/**
 An offering is collection of different Packages that lets the user purchase access in different ways.
 */
NS_SWIFT_NAME(Offering)
@interface RCOffering : NSObject
/**
TODO
*/
@property (readonly) NSString *identifier;
/**
TODO
*/
@property (readonly) NSString *serverDescription;
/**
TODO
*/
@property (readonly) NSArray<RCPackage *> *availablePackages;
/**
TODO
*/
@property (readonly, nullable) RCPackage *lifetime;
/**
TODO
*/
@property (readonly, nullable) RCPackage *annual;
/**
TODO
*/
@property (readonly, nullable) RCPackage *sixMonth;
/**
TODO
*/
@property (readonly, nullable) RCPackage *threeMonth;
/**
TODO
*/
@property (readonly, nullable) RCPackage *twoMonth;
/**
TODO
*/
@property (readonly, nullable) RCPackage *monthly;
/**
TODO
*/
@property (readonly, nullable) RCPackage *weekly;
/**
TODO
*/
- (nullable RCPackage *)packageWithIdentifier:(nullable NSString *)identifier NS_SWIFT_NAME(package(identifier:));
/// :nodoc:
- (nullable RCPackage *)objectForKeyedSubscript:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
