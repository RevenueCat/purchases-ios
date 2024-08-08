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

    NSString *localizedDescription __unused = product.localizedDescription;
    NSString *localizedTitle __unused = product.localizedTitle;
    NSString *currencyCode __unused = product.currencyCode;
    NSDecimalNumber *price __unused = product.price;
    NSString *localizedPriceString __unused = product.localizedPriceString;
    NSString *localizedPricePerWeek __unused = product.localizedPricePerWeek;
    NSString *localizedPricePerMonth __unused = product.localizedPricePerMonth;
    NSString *localizedPricePerYear __unused = product.localizedPricePerYear;
    NSString *productIdentifier __unused = product.productIdentifier;
    if (@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)) {
        BOOL isFamilyShareable  __unused = product.isFamilyShareable;
    }
    NSString *subscriptionGroupIdentifier  __unused = product.subscriptionGroupIdentifier;
    NSNumberFormatter *priceFormatter  __unused = product.priceFormatter;

    RCSubscriptionPeriod *subscriptionPeriod __unused = product.subscriptionPeriod;
    RCStoreProductDiscount *introductoryPrice __unused = product.introductoryDiscount;
    NSDecimalNumber *pricePerWeek __unused = product.pricePerWeek;
    NSDecimalNumber *pricePerMonth __unused = product.pricePerMonth;
    NSDecimalNumber *pricePerYear __unused = product.pricePerYear;
    NSString *localizedIntroductoryPriceString __unused = product.localizedIntroductoryPriceString;
    NSArray<RCStoreProductDiscount *> *discounts __unused = product.discounts;
    SKProduct *sk1 __unused = product.sk1Product;
}

+ (void)checkConstructors {
    SKProduct *sk1Product = nil;

    RCStoreProduct *stp1 = [[RCStoreProduct alloc] initWithSk1Product:sk1Product];

    NSLog(@"%@", stp1);
}

+ (void)checkProductCategory {
    RCStoreProductCategory category = RCStoreProductCategorySubscription;

    switch (category) {
        case RCStoreProductCategorySubscription: break;
        case RCStoreProductCategoryNonSubscription: break;
    }
}

+ (void)checkProductType {
    RCStoreProductType type = RCStoreProductTypeNonRenewableSubscription;

    switch (type) {
        case RCStoreProductTypeConsumable: break;
        case RCStoreProductTypeNonConsumable: break;
        case RCStoreProductTypeNonRenewableSubscription: break;
        case RCStoreProductTypeAutoRenewableSubscription: break;
    }
}

@end
