//
//  RCPurchaserInfoAPI.m
//  Purchases
//
//  Created by Madeline Beyl on 7/9/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

#import "RCPurchaserInfoAPI.h"

@import Purchases;
@import PurchasesCoreSwift;

@implementation RCPurchaserInfoAPI

+ (void)checkAPI {
    RCPurchaserInfo *pi = [[RCPurchaserInfo alloc]init];
    RCEntitlementInfos *ei = pi.entitlements;
    NSSet<NSString *> *as = pi.activeSubscriptions;
    NSDate *led = pi.latestExpirationDate;
    NSSet<NSString *> *ncp = pi.nonConsumablePurchases;
    NSArray<RCTransaction *> *nst = pi.nonSubscriptionTransactions;
    NSString *oav = pi.originalApplicationVersion;
    NSDate *opd = pi.originalPurchaseDate;
    NSDate *rd = pi.requestDate;
    NSDate *fs = pi.firstSeen;
    NSString *oaud = pi.originalAppUserId;
    NSURL *murl = pi.managementURL;
    
    [pi expirationDateForProductIdentifier:@""];
    [pi purchaseDateForProductIdentifier:@""];
    [pi expirationDateForEntitlement:@""];
    [pi purchaseDateForEntitlement:@""];
    
    NSLog(pi, ei, as, led, ncp, nst, oav, opd, rd, fs, oaud, murl);
}

@end
