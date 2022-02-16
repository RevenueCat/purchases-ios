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
    NSString *currencyCode = discount.currencyCode;
    NSDecimal price = discount.price;
    RCPaymentMode paymentMode = discount.paymentMode;
    RCSubscriptionPeriod *period = discount.subscriptionPeriod;

    NSLog(
          offerIdentifier,
          currencyCode,
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

+ (void)checkTypeEnum {
    RCDiscountType paymentMode = RCDiscountTypeIntroductory;

    switch (paymentMode) {
        case RCDiscountTypeIntroductory:
        case RCDiscountTypePromotional:
            break;
    }
}

@end
