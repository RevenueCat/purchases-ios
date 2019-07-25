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

@property NSString *identifier;
@property NSString *serverDescription;

@property NSArray<RCPackage *> *availablePackages;

@property RCPackage * _Nullable lifetime;
@property RCPackage * _Nullable annual;
@property RCPackage * _Nullable sixMonth;
@property RCPackage * _Nullable threeMonth;
@property RCPackage * _Nullable twoMonth;
@property RCPackage * _Nullable monthly;
@property RCPackage * _Nullable weekly;

- (RCPackage * _Nullable)packageWithIdentifier:(NSString * _Nullable)identifier NS_SWIFT_NAME(package(identifier:));

@end

NS_ASSUME_NONNULL_END
