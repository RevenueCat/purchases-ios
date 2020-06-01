//
// Created by Andrés Boedo on 5/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import "RCProductInfoExtractor.h"
#import "RCProductInfo.h"
#import "RCISOPeriodFormatter.h"
#import "RCPromotionalOffer.h"
#import "NSLocale+RCExtensions.h"
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface RCProductInfoExtractor ()


@end


@implementation RCProductInfoExtractor

- (RCProductInfo *)extractInfoFromProduct:(SKProduct *)product {
    NSString *productIdentifier = product.productIdentifier;
    NSDecimalNumber *price = product.price;

    RCPaymentMode paymentMode = RCPaymentModeNone;
    NSDecimalNumber *introPrice = nil;

    NSString *normalDuration = nil;
    NSString *introDuration = nil;
    RCIntroDurationType introDurationType = RCIntroDurationTypeNone;

    if (@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *)) {
        RCISOPeriodFormatter *formatter = [[RCISOPeriodFormatter alloc] init];

        if (product.introductoryPrice) {
            paymentMode = RCPaymentModeFromSKProductDiscountPaymentMode(product.introductoryPrice.paymentMode);
            introPrice = product.introductoryPrice.price;
            BOOL isFreeTrial = product.introductoryPrice.paymentMode == SKProductDiscountPaymentModeFreeTrial;
            NSString *introPriceDuration = [formatter stringFromProductSubscriptionPeriod:product.introductoryPrice.subscriptionPeriod];
            if (isFreeTrial) {
                introDurationType = RCIntroDurationTypeFreeTrial;
                introDuration = introPriceDuration;
            } else {
                introDurationType = RCIntroDurationTypeIntroPrice;
                introDuration = introPriceDuration;
            }
        }
        if (product.subscriptionPeriod) {
            normalDuration = [formatter stringFromProductSubscriptionPeriod:product.subscriptionPeriod];
        }
    }

    NSString *subscriptionGroup = nil;
    if (@available(iOS 12.0, macOS 10.14.0, tvOS 12.0, *)) {
        subscriptionGroup = product.subscriptionGroupIdentifier;
    }

    NSMutableArray *discounts = nil;
    if (@available(iOS 12.2, macOS 10.14.4, tvOS 12.2, *)) {
        discounts = [NSMutableArray new];
        for (SKProductDiscount *discount in product.discounts) {
            [discounts addObject:[[RCPromotionalOffer alloc] initWithProductDiscount:discount]];
        }
    }

    NSString *currencyCode = product.priceLocale.rc_currencyCode;

    RCProductInfo *productInfo = [[RCProductInfo alloc]
                                                 initWithProductIdentifier:productIdentifier
                                                               paymentMode:paymentMode
                                                              currencyCode:currencyCode
                                                                     price:price
                                                            normalDuration:normalDuration
                                                             introDuration:introDuration
                                                         introDurationType:introDurationType
                                                                introPrice:introPrice
                                                         subscriptionGroup:subscriptionGroup
                                                                 discounts:discounts];

    return productInfo;
}


@end


NS_ASSUME_NONNULL_END

