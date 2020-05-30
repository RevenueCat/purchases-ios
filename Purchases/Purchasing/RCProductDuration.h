//
// Created by Andrés Boedo on 5/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

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


@interface RCProductDuration : NSObject

@property (nonatomic, nullable, readonly, copy) NSString *normalDuration;
@property (nonatomic, nullable, readonly, copy) NSString *introDuration;
@property (nonatomic, readonly, assign) RCIntroDurationType introDurationType;
@property (nonatomic, readonly, assign) RCPaymentMode paymentMode;
@property (nonatomic, readonly, copy) NSString *productIdentifier;
@property (nonatomic, readonly, copy) NSString *subscriptionGroup;
@property (nonatomic, readonly, copy) NSArray *discounts;
@property (nonatomic, readonly, copy) NSString *currencyCode;
@property (nonatomic, readonly, copy) NSString *presentedOfferingIdentifier;
- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier
                              paymentMode:(RCPaymentMode)paymentMode
                             currencyCode:(NSString *)currencyCode
              presentedOfferingIdentifier:(NSString *_Nullable)presentedOfferingIdentifier
                           normalDuration:(NSString *_Nullable)normalDuration
                            introDuration:(NSString *_Nullable)introDuration
                        introDurationType:(RCIntroDurationType)introDurationType
                        subscriptionGroup:(NSString *_Nullable)subscriptionGroup
                                discounts:(NSArray *_Nullable)discounts;


@end


NS_ASSUME_NONNULL_END
