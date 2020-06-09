//
// Created by Andrés Boedo on 5/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RCIntroDurationType) {
    RCIntroDurationTypeNone = -1,
    RCIntroDurationTypeFreeTrial = 0,
    RCIntroDurationTypeIntroPrice = 1
};

typedef NS_ENUM(NSInteger, RCPaymentMode) {
    RCPaymentModeNone = -1,
    RCPaymentModePayAsYouGo = 0,
    RCPaymentModePayUpFront = 1,
    RCPaymentModeFreeTrial = 2
};

API_AVAILABLE(ios(11.2), macos(10.13.2))
RCPaymentMode RCPaymentModeFromSKProductDiscountPaymentMode(SKProductDiscountPaymentMode paymentMode);

@class RCPromotionalOffer;

@interface RCProductInfo : NSObject

@property (nonatomic, readonly, copy) NSString *productIdentifier;
@property (nonatomic, readonly, assign) RCPaymentMode paymentMode;
@property (nonatomic, readonly, copy) NSString *currencyCode;
@property (nonatomic, readonly, copy) NSDecimalNumber *price;
@property (nonatomic, nullable, readonly, copy) NSString *normalDuration;
@property (nonatomic, nullable, readonly, copy) NSString *introDuration;
@property (nonatomic, readonly, assign) RCIntroDurationType introDurationType;
@property (nonatomic, readonly, copy) NSDecimalNumber *introPrice;
@property (nonatomic, readonly, copy) NSString *subscriptionGroup;
@property (nonatomic, readonly, copy) NSArray<RCPromotionalOffer *> *discounts;

- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier
                              paymentMode:(RCPaymentMode)paymentMode
                             currencyCode:(NSString *)currencyCode
                                    price:(NSDecimalNumber *)price
                           normalDuration:(nullable NSString *)normalDuration
                            introDuration:(nullable NSString *)introDuration
                        introDurationType:(RCIntroDurationType)introDurationType
                               introPrice:(nullable NSDecimalNumber *)introPrice
                        subscriptionGroup:(nullable NSString *)subscriptionGroup
                                discounts:(nullable NSArray<RCPromotionalOffer *> *)discounts NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

- (NSDictionary *)asDictionary;

- (NSString *)cacheKey;

@end


NS_ASSUME_NONNULL_END
