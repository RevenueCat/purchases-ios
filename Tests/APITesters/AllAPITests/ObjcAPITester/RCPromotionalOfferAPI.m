//
//  RCPromotionalOfferAPI.m
//  ObjCAPITester
//
//  Created by Joshua Liebowitz on 4/18/22.
//

@import RevenueCat;
#import "RCPromotionalOfferAPI.h"

@implementation RCPromotionalOfferAPI

+ (void)checkAPI {
    RCPromotionalOffer *po = nil;
    RCStoreProductDiscount *discount = po.discount;

    RCPromotionalOfferSignedData *signedData = po.signedData;

    NSString *identifier __unused = signedData.identifier;
    NSString *keyIdentifier __unused = signedData.keyIdentifier;
    NSUUID *nonce __unused = signedData.nonce;
    NSString *signature __unused = signedData.signature;
    NSInteger timestamp __unused = signedData.timestamp;

    RCStoreProduct *product = nil;
    RCPromotionalOfferRequest *request = [[RCPromotionalOfferRequest alloc] initWithDiscount:discount product:product];
    RCStoreProduct *requestedProduct __unused = request.product;
    RCStoreProductDiscount *requestedDiscount __unused = request.discount;
    [[RCPurchases sharedPurchases] getPromotionalOffersForRequests:@[request]
                                                      completion:^(NSArray<RCPromotionalOfferResult *> *results) {
        for (RCPromotionalOfferResult *result in results) {
            RCPromotionalOfferRequest *originalRequest __unused = result.request;
            RCPromotionalOffer *signedOffer __unused = result.offer;
            NSError *error __unused = result.error;
        }
    }];

    NSLog(po, discount);
}

@end
