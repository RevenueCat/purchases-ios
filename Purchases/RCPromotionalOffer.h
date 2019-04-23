//
// Created by César de la Vega  on 2019-04-18.
// Copyright (c) 2019 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCBackend.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCPromotionalOffer : NSObject

@property(nonatomic, readonly) NSString *offerIdentifier;

@property(nonatomic, readonly) NSDecimalNumber *price;

@property(nonatomic, readonly) enum RCPaymentMode paymentMode;

- (instancetype)initWithProductDiscount:(SKProductDiscount *)productDiscount API_AVAILABLE(ios(12.2), macos(10.14.4));

@end
NS_ASSUME_NONNULL_END
