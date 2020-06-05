//
//  RCPurchaserInfo+Protected.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCPurchaserInfo.h"
NS_ASSUME_NONNULL_BEGIN
@interface RCPurchaserInfo (Protected)

- (nullable instancetype)initWithData:(NSDictionary *)data;

@property (nonatomic, readonly) NSDictionary<NSString *, NSDate *> *expirationDatesByProduct;
@property (nonatomic, readonly) NSDictionary<NSString *, NSDate *> *purchaseDatesByProduct;
@property (nonatomic, readonly) NSSet<NSString *> *nonConsumablePurchases;
@property (nonatomic, readonly, nullable) NSString  *originalApplicationVersion;
@property (nonatomic, readonly, nullable) NSDate *originalPurchaseDate;
@property (nonatomic, readonly, nullable) NSString *schemaVersion;

- (NSDictionary *)JSONObject;
+ (NSString *)currentSchemaVersion;

@end
NS_ASSUME_NONNULL_END
