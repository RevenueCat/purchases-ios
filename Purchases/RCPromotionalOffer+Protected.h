//
//  RCPromotionalOffer+Protected.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCPromotionalOffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCPromotionalOffer (Protected)

@property (nonatomic, readwrite) NSString *offerIdentifier;

@property (nonatomic, readwrite) NSDecimalNumber *price;

@property (nonatomic, readwrite) enum RCPaymentMode paymentMode;

@end

NS_ASSUME_NONNULL_END
