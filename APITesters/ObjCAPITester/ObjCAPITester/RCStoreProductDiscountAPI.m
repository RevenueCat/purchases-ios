//
//  RCStoreProductDiscountAPI.m
//  ObjCAPITester
//
//  Created by Nacho Soto on 1/5/22.
//

#import "RCStoreProductDiscountAPI.h"

@import RevenueCat;

@implementation RCStoreProductDiscountAPI

+ (void)checkAPI {
    RCStoreProductDiscount *discount;

    NSString *offerIdentifier = discount.offerIdentifier;
    NSDecimal price = discount.price;
    RCPaymentMode paymentMode = discount.paymentMode;
    RCSubscriptionPeriod *period = discount.subscriptionPeriod;

    NSLog(
          offerIdentifier,
          price,
          paymentMode,
          period
    );
}

+ (void)checkPaymentModeEnum {
    RCPaymentMode paymentMode = RCPaymentModePayAsYouGo;

    switch (paymentMode) {
        case RCPaymentModePayAsYouGo:
        case RCPaymentModePayUpFront:
        case RCPaymentModeFreeTrial:
            break;
    }
}

@end
