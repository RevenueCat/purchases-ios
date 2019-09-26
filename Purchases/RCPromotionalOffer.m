//
//  RCPromotionalOffer.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCPromotionalOffer.h"
#import "RCBackend.h"


@interface RCPromotionalOffer ()
@property (nonatomic, readwrite) NSString *offerIdentifier;
@property (readwrite) NSDecimalNumber *price;
@property (readwrite) RCPaymentMode paymentMode;
@end

@implementation RCPromotionalOffer

- (instancetype)initWithProductDiscount:(SKProductDiscount *)productDiscount
API_AVAILABLE(ios(12.2), macos(10.14.4)) {
    if (self = [super init]) {
        self.offerIdentifier = productDiscount.identifier;
        self.price = productDiscount.price;
        self.paymentMode = RCPaymentModeFromSKProductDiscountPaymentMode(productDiscount.paymentMode);
    }
    return self;
}

@end
