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

@property (nonatomic) RCISOPeriodFormatter *formatter API_AVAILABLE(ios(11.2), macos(10.13.2), tvos(11.2));

@end


@implementation RCProductInfoExtractor

# pragma mark - public methods

- (instancetype)init {
    if (self = [super init]) {
        if (@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *)) {
            self.formatter = [[RCISOPeriodFormatter alloc] init];
        }
    }
    return self;
}

- (RCProductInfo *)extractInfoFromProduct:(SKProduct *)product {
    NSString *productIdentifier = product.productIdentifier;
    NSDecimalNumber *price = product.price;
    NSString *currencyCode = product.priceLocale.rc_currencyCode;

    RCPaymentMode paymentMode = [self extractPaymentModeForProduct:product];
    NSDecimalNumber *introPrice = [self extractIntroPriceForProduct:product];

    NSString *normalDuration = [self extractNormalDurationForProduct:product];
    NSString *introDuration = [self extractIntroDurationForProduct:product];
    RCIntroDurationType introDurationType = [self extractIntroDurationTypeForProduct:product];

    NSString *subscriptionGroup = [self extractSubscriptionGroupForProduct:product];
    NSArray *discounts = [self extractDiscountsForProduct:product];

    RCProductInfo *productInfo = [[RCProductInfo alloc] initWithProductIdentifier:productIdentifier
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

# pragma mark - private methods

- (RCIntroDurationType)extractIntroDurationTypeForProduct:(SKProduct *)product {
    RCIntroDurationType introDurationType = RCIntroDurationTypeNone;

    if (@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *)) {
        if (product.introductoryPrice) {
            introDurationType = [self isFreeTrial:product] ? RCIntroDurationTypeFreeTrial
                                                           : RCIntroDurationTypeIntroPrice;
        }
    }
    return introDurationType;
}

- (BOOL)isFreeTrial:(SKProduct *)product API_AVAILABLE(ios(11.2), macos(10.13.2), tvos(11.2)) {
    return product.introductoryPrice.paymentMode == SKProductDiscountPaymentModeFreeTrial;
}

- (nullable NSString *)extractSubscriptionGroupForProduct:(SKProduct *)product {
    NSString *subscriptionGroup = nil;
    if (@available(iOS 12.0, macOS 10.14.0, tvOS 12.0, *)) {
        subscriptionGroup = product.subscriptionGroupIdentifier;
    }
    return subscriptionGroup;
}

- (nullable NSArray<RCPromotionalOffer *> *)extractDiscountsForProduct:(SKProduct *)product {
    NSMutableArray *discounts = nil;
    if (@available(iOS 12.2, macOS 10.14.4, tvOS 12.2, *)) {
        discounts = [NSMutableArray new];
        for (SKProductDiscount *discount in product.discounts) {
            [discounts addObject:[[RCPromotionalOffer alloc] initWithProductDiscount:discount]];
        }
    }
    return discounts;
}

- (RCPaymentMode)extractPaymentModeForProduct:(SKProduct *)product {
    RCPaymentMode paymentMode = RCPaymentModeNone;
    if (@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *)) {
        if (product.introductoryPrice) {
            paymentMode = RCPaymentModeFromSKProductDiscountPaymentMode(product.introductoryPrice.paymentMode);
        }
    }
    return paymentMode;
}

- (nullable NSDecimalNumber *)extractIntroPriceForProduct:(SKProduct *)product {
    NSDecimalNumber *introPrice = nil;
    if (@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *)) {
        if (product.introductoryPrice) {
            introPrice = product.introductoryPrice.price;
        }
    }
    return introPrice;
}

- (nullable NSString *)extractNormalDurationForProduct:(SKProduct *)product {
    NSString *normalDuration = nil;
    if (@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *)) {
        if (product.subscriptionPeriod && product.subscriptionPeriod.numberOfUnits != 0) {
            normalDuration = [self.formatter stringFromProductSubscriptionPeriod:product.subscriptionPeriod];
        }
    }
    return normalDuration;
}

- (nullable NSString *)extractIntroDurationForProduct:(SKProduct *)product {
    NSString *introDuration = nil;
    if (@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *)) {
        if (product.introductoryPrice) {
            SKProductSubscriptionPeriod *subscriptionPeriod = product.introductoryPrice.subscriptionPeriod;
            NSString *introPriceDuration = [self.formatter stringFromProductSubscriptionPeriod:subscriptionPeriod];
            introDuration = introPriceDuration;
        }
    }
    return introDuration;
}

@end


NS_ASSUME_NONNULL_END

