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

    NSLog(po, discount);
}

@end
