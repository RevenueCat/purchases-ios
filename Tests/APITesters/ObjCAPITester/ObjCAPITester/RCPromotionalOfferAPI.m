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

    NSLog(po, discount);
}

@end
