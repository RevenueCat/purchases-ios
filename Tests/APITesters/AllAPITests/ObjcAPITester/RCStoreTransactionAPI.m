//
//  RCStoreTransactionAPI.m
//  ObjCAPITester
//
//  Created by Nacho Soto on 1/5/22.
//

#import "RCStoreTransactionAPI.h"

@import StoreKit;
@import RevenueCat;

@implementation RCStoreTransactionAPI

+ (void)checkAPI {
    RCStoreTransaction *transaction;

    NSString *productIdentifier __unused = transaction.productIdentifier;
    NSDate *purchaseDate __unused = transaction.purchaseDate;
    NSString *transactionIdentifier __unused = transaction.transactionIdentifier;
    NSInteger quantity __unused = transaction.quantity;
    RCStorefront *__nullable storefront __unused = transaction.storefront;

    SKPaymentTransaction *sk1 __unused = transaction.sk1Transaction;
}

@end
