//
//  RCTransaction.h
//  Purchases
//
//  Created by Andrés Boedo on 8/13/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Purchases.Transaction)
@interface RCTransaction : NSObject

@property (nonatomic, readonly, copy) NSString *revenueCatId;
@property (nonatomic, readonly, copy) NSString *productId;
@property (nonatomic, readonly, copy) NSDate *purchaseDate;

- (instancetype)initWithTransactionId:(NSString *)transactionId
                            productId:(NSString *)productId
                         purchaseDate:(NSDate *)purchaseDate NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
