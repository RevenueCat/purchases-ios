//
//  RCTransactionAPI.m
//  APITester
//
//  Created by Joshua Liebowitz on 6/29/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

@import RevenueCat;

#import "RCTransactionAPI.h"

@implementation RCTransactionAPI

+ (void)checkAPI {
    RCStoreTransaction *rct;
    NSString *rci = rct.transactionIdentifier;
    NSString *pid = rct.productIdentifier;
    NSDate *date = rct.purchaseDate;
    NSLog(rct, rci, pid, date);
}

@end
