//
// Created by Andrés Boedo on 5/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import "RCProductDuration.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCProductDuration ()

@property (nonatomic, nullable, copy) NSString *normalDuration;
@property (nonatomic, nullable, copy) NSString *introDuration;
@property (nonatomic, assign) RCIntroDurationType introDurationType;
@property (nonatomic, assign) RCPaymentMode paymentMode;
@property (nonatomic, copy) NSString *productIdentifier;
@property (nonatomic, copy) NSString *subscriptionGroup;
@property (nonatomic, copy) NSArray *discounts;
@property (nonatomic, copy) NSString *currencyCode;
@property (nonatomic, copy) NSString *presentedOfferingIdentifier;

@end


@implementation RCProductDuration

- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier
                              paymentMode:(RCPaymentMode)paymentMode
                             currencyCode:(NSString *)currencyCode
              presentedOfferingIdentifier:(NSString * _Nullable)presentedOfferingIdentifier
                           normalDuration:(NSString * _Nullable)normalDuration
                            introDuration:(NSString * _Nullable)introDuration
                        introDurationType:(RCIntroDurationType)introDurationType
                        subscriptionGroup:(NSString * _Nullable)subscriptionGroup
                                discounts:(NSArray * _Nullable)discounts {
    self = [super init];
    if (self) {
        self.productIdentifier = productIdentifier;
        self.paymentMode = paymentMode;
        self.currencyCode = currencyCode;
        self.presentedOfferingIdentifier = presentedOfferingIdentifier;
        self.normalDuration = normalDuration;
        self.introDuration = introDuration;
        self.introDurationType = introDurationType;
        self.subscriptionGroup = subscriptionGroup;
        self.discounts = discounts;
    }

    return self;
}


@end


NS_ASSUME_NONNULL_END
