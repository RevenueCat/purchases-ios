//
//  RCNonSubscriptionTransactionAPI.m
//  ObjCAPITester
//
//  Created by Nacho Soto on 6/23/22.
//

#import "RCNonSubscriptionTransactionAPI.h"

@import RevenueCat;

@implementation RCNonSubscriptionTransactionAPI

+ (void)checkAPI {
    RCNonSubscriptionTransaction *transaction;

    NSString *pid __unused = transaction.productIdentifier;
    NSDate *pd __unused = transaction.purchaseDate;
    NSString *tid __unused = transaction.transactionIdentifier;
}

@end
