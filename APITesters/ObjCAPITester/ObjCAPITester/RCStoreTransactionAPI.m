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

    NSString *productIdentifier = transaction.productIdentifier;
    NSDate *purchaseDate = transaction.purchaseDate;
    NSString *transactionIdentifier = transaction.transactionIdentifier;
    NSInteger quantity = transaction.quantity;

    SKPaymentTransaction *sk1 = transaction.sk1Transaction;

    NSLog(
          productIdentifier,
          purchaseDate,
          transactionIdentifier,
          quantity,
          sk1
          );
}

@end
