//
//  RCPurchaserInfo+Protected.h
//  Purchases
//
//  Created by Jacob Eiting on 10/22/17.
//  Copyright © 2019 RevenueCat, Inc. All rights reserved.
//

#import "RCPurchaserInfo.h"
NS_ASSUME_NONNULL_BEGIN
@interface RCPurchaserInfo (Protected)

- (nullable instancetype)initWithData:(NSDictionary *)data;

@property (nonatomic, readonly) NSDictionary<NSString *, NSDate *> *expirationDatesByProduct;
@property (nonatomic, readonly) NSDictionary<NSString *, NSDate *> *purchaseDatesByProduct;
@property (nonatomic, readonly) NSSet<NSString *> *nonConsumablePurchases;
@property (nonatomic, readonly, nullable) NSString  *originalApplicationVersion;
@property (readonly, nullable) NSString *schemaVersion;

- (NSDictionary *)JSONObject;
+ (NSString *)currentSchemaVersion;

@end
NS_ASSUME_NONNULL_END
