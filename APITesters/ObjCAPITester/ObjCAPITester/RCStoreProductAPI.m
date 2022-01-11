//
//  RCStoreProductAPI.m
//  ObjCAPITester
//
//  Created by Nacho Soto on 1/5/22.
//

#import "RCStoreProductAPI.h"

@import RevenueCat;

@implementation RCStoreProductAPI

+ (void)checkAPI {
    RCStoreProduct *product;

    NSString *localizedDescription = product.localizedDescription;
    NSString *localizedTitle = product.localizedTitle;
    NSDecimal price = product.price;
    NSString *localizedPriceString = product.localizedPriceString;
    NSString *productIdentifier = product.productIdentifier;
    BOOL isFamilyShareable = product.isFamilyShareable;
    NSString *subscriptionGroupIdentifier = product.subscriptionGroupIdentifier;
    NSNumberFormatter *priceFormatter = product.priceFormatter;
    RCSubscriptionPeriod *subscriptionPeriod = product.subscriptionPeriod;
    RCStoreProductDiscount *introductoryPrice = product.introductoryStoreProductDiscount;
    NSArray<RCStoreProductDiscount *> *discounts = product.discounts;
    NSDecimalNumber *pricePerMonth = product.pricePerMonth;
    NSString *localizedIntroductoryStoreProductDiscountString = product.localizedIntroductoryStoreProductDiscountString;

    SKProduct *sk1 = product.sk1Product;

    NSLog(
          product,
          localizedDescription,
          localizedTitle,
          price,
          localizedPriceString,
          productIdentifier,
          isFamilyShareable,
          subscriptionGroupIdentifier,
          priceFormatter,
          subscriptionPeriod,
          introductoryPrice,
          discounts,
          pricePerMonth,
          localizedIntroductoryStoreProductDiscountString,
          sk1
      );
}

@end
