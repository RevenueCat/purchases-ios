//
// Created by Andrés Boedo on 5/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import "RCProductInfo.h"
#import "RCPromotionalOffer.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCProductInfo ()

@property (nonatomic, nullable, copy) NSString *normalDuration;
@property (nonatomic, nullable, copy) NSString *introDuration;
@property (nonatomic, assign) RCIntroDurationType introDurationType;
@property (nonatomic, assign) RCPaymentMode paymentMode;
@property (nonatomic, nullable, copy) NSDecimalNumber *price;
@property (nonatomic, nullable, copy) NSDecimalNumber *introPrice;
@property (nonatomic, copy) NSString *productIdentifier;
@property (nonatomic, copy) NSString *subscriptionGroup;
@property (nonatomic, copy) NSArray *discounts;
@property (nonatomic, copy) NSString *currencyCode;

@end

API_AVAILABLE(ios(11.2), macos(10.13.2))
RCPaymentMode RCPaymentModeFromSKProductDiscountPaymentMode(SKProductDiscountPaymentMode paymentMode)
{
    switch (paymentMode) {
        case SKProductDiscountPaymentModePayUpFront:
            return RCPaymentModePayUpFront;
        case SKProductDiscountPaymentModePayAsYouGo:
            return RCPaymentModePayAsYouGo;
        case SKProductDiscountPaymentModeFreeTrial:
            return RCPaymentModeFreeTrial;
        default:
            return RCPaymentModeNone;
    }
}

@implementation RCProductInfo

- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier
                              paymentMode:(RCPaymentMode)paymentMode
                             currencyCode:(NSString *)currencyCode
                                    price:(NSDecimalNumber *)price
                           normalDuration:(NSString *_Nullable)normalDuration
                            introDuration:(NSString *_Nullable)introDuration
                        introDurationType:(RCIntroDurationType)introDurationType
                               introPrice:(NSDecimalNumber *)introPrice
                        subscriptionGroup:(NSString *_Nullable)subscriptionGroup
                                discounts:(NSArray *_Nullable)discounts {
    self = [super init];
    if (self) {
        self.productIdentifier = productIdentifier;
        self.paymentMode = paymentMode;
        self.currencyCode = currencyCode;
        self.price = price;
        self.normalDuration = normalDuration;
        self.introDuration = introDuration;
        self.introDurationType = introDurationType;
        self.introPrice = introPrice;
        self.subscriptionGroup = subscriptionGroup;
        self.discounts = discounts;
    }

    return self;
}

- (NSDictionary *)asDictionary {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    if (self.productIdentifier) {
        dict[@"product_id"] = self.productIdentifier;
    }

    if (self.price) {
        dict[@"price"] = self.price;
    }

    if (self.currencyCode) {
        dict[@"currency"] = self.currencyCode;
    }

    if (self.paymentMode != RCPaymentModeNone) {
        dict[@"payment_mode"] = @((NSUInteger)self.paymentMode);
    }

    if (self.introPrice) {
        dict[@"introductory_price"] = self.introPrice;
    }

    if (self.subscriptionGroup) {
        dict[@"subscription_group_id"] = self.subscriptionGroup;
    }

    if (@available(iOS 12.2, macOS 10.14.4, tvOS 12.2, *)) {
        if (self.discounts) {
            NSMutableArray *offers = [NSMutableArray array];
            for (RCPromotionalOffer *discount in self.discounts) {
                [offers addObject:@{
                    @"offer_identifier": discount.offerIdentifier,
                    @"price": discount.price,
                    @"payment_mode": @((NSUInteger) discount.paymentMode)
                }];
            }
            dict[@"offers"] = offers;
        }
    }
    return dict;
}

@end


NS_ASSUME_NONNULL_END
