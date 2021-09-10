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
    RCTransaction *rct = [[RCTransaction alloc] initWithTransactionId:@"" productId:@"" purchaseDate:NSDate.now];
    NSString *rci = rct.revenueCatId;
    NSString *pid = rct.productId;
    NSDate *date = rct.purchaseDate;
    NSLog(rct, rci, pid, date);
}

@end
