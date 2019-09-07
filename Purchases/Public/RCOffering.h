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

@property (readonly) RCPackage * _Nullable lifetime;
@property (readonly) RCPackage * _Nullable annual;
@property (readonly) RCPackage * _Nullable sixMonth;
@property (readonly) RCPackage * _Nullable threeMonth;
@property (readonly) RCPackage * _Nullable twoMonth;
@property (readonly) RCPackage * _Nullable monthly;
@property (readonly) RCPackage * _Nullable weekly;

- (RCPackage * _Nullable)packageWithIdentifier:(NSString * _Nullable)identifier NS_SWIFT_NAME(package(identifier:));

- (RCPackage * _Nullable)objectForKeyedSubscript:(NSString *)key;

- (NSString *)description;

@end

NS_ASSUME_NONNULL_END
