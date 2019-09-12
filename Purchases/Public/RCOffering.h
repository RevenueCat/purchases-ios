//
//  RCOffering.h
//  Purchases
//
//  Created by Jacob Eiting on 6/2/18.
//  Copyright © 2019 Purchases. All rights reserved.
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

@property (readonly) NSString *identifier;
@property (readonly) NSString *serverDescription;

@property (readonly) NSArray<RCPackage *> *availablePackages;

@property (readonly, nullable) RCPackage *lifetime;
@property (readonly, nullable) RCPackage *annual;
@property (readonly, nullable) RCPackage *sixMonth;
@property (readonly, nullable) RCPackage *threeMonth;
@property (readonly, nullable) RCPackage *twoMonth;
@property (readonly, nullable) RCPackage *monthly;
@property (readonly, nullable) RCPackage *weekly;

- (nullable RCPackage *)packageWithIdentifier:(nullable NSString *)identifier NS_SWIFT_NAME(package(identifier:));

- (nullable RCPackage *)objectForKeyedSubscript:(NSString *)key;

- (NSString *)description;

@end

NS_ASSUME_NONNULL_END
