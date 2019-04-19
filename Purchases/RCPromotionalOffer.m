//
// Created by César de la Vega  on 2019-04-18.
// Copyright (c) 2019 Purchases. All rights reserved.
//

#import "RCPromotionalOffer.h"
#import "RCBackend.h"


@interface RCPromotionalOffer ()
@property(nonatomic, readwrite) NSString *offerIdentifier;
@property(readwrite) NSDecimalNumber *price;
@property(readwrite) RCPaymentMode paymentMode;
@end

@implementation RCPromotionalOffer

- (instancetype)initWithSKProductDiscount:(SKProductDiscount *)skProductDiscount
API_AVAILABLE(ios(12.2), macos(10.14.4)) {
    if (self = [super init]) {
        self.offerIdentifier = skProductDiscount.identifier;
        self.price = skProductDiscount.price;
        self.paymentMode = RCPaymentModeFromSKProductDiscountPaymentMode(skProductDiscount.paymentMode);
    }
    return self;
}

@end
