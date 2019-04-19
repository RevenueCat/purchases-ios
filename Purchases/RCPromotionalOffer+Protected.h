//
// Created by César de la Vega  on 2019-04-18.
// Copyright (c) 2019 Purchases. All rights reserved.
//

#import "RCPromotionalOffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCPromotionalOffer (Protected)

@property(nonatomic, readwrite) NSString *offerIdentifier;

@property(nonatomic, readwrite) NSDecimalNumber *price;

@property(nonatomic, readwrite) enum RCPaymentMode paymentMode;

@end
NS_ASSUME_NONNULL_END
