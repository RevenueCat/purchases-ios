//
//  RCOfferingsFactory.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCOfferings;
@class RCOffering;
@class RCPackage;

NS_ASSUME_NONNULL_BEGIN
NS_SWIFT_NAME(OfferingsFactory)
@interface RCOfferingsFactory : NSObject

+ (RCOfferings *)createOfferingsWithProducts:(NSDictionary<NSString *, SKProduct *> *)products data:(NSDictionary *)data;
+ (RCOffering * _Nullable)createOfferingWithProducts:(NSDictionary<NSString *, SKProduct *> *)products offeringData:(NSDictionary *)offeringData;
+ (RCPackage *_Nullable)createPackageWithData:(NSDictionary *)data products:(NSDictionary<NSString *, SKProduct *> *)products offeringIdentifier:(NSString *)offeringIdentifier;

@end

NS_ASSUME_NONNULL_END
