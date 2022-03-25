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
    NSDecimalNumber *price = discount.price;
    NSString *localizedPriceString = discount.localizedPriceString;
    RCPaymentMode paymentMode = discount.paymentMode;
    RCSubscriptionPeriod *period = discount.subscriptionPeriod;

    NSLog(
          offerIdentifier,
          currencyCode,
          price,
          localizedPriceString,
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
