//
//  RCCustomerInfoAPI.m
//  Purchases
//
//  Created by Madeline Beyl on 7/9/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

#import "RCCustomerInfoAPI.h"

@import RevenueCat;

@implementation RCCustomerInfoAPI

+ (void)checkAPI {
    // RCCustomerInfo initializer is publically unavailable.
    RCCustomerInfo *pi = nil;
    RCEntitlementInfos *ei = pi.entitlements;
    NSSet<NSString *> *as = pi.activeSubscriptions;
    NSSet<NSString *> *appis = pi.allPurchasedProductIdentifiers;
    NSDate *led = pi.latestExpirationDate;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSSet<NSString *> *ncp = pi.nonConsumablePurchases;
#pragma clang diagnostic pop
    NSArray<RCTransaction *> *nst = pi.nonSubscriptionTransactions;
    NSString *oav = pi.originalApplicationVersion;
    NSDate *opd = pi.originalPurchaseDate;
    NSDate *rd = pi.requestDate;
    NSDate *fs = pi.firstSeen;
    NSString *oaud = pi.originalAppUserId;
    NSURL *murl = pi.managementURL;
    
    NSDate *edfpi = [pi expirationDateForProductIdentifier:@""];
    NSDate *pdfpi = [pi purchaseDateForProductIdentifier:@""];
    NSDate *exdf = [pi expirationDateForEntitlement:@""];
    NSDate *pdfe = [pi purchaseDateForEntitlement:@""];
    
    NSString *d = [pi description];
    
    NSLog(pi, ei, as, appis, led, ncp, nst, oav, opd, rd, fs, oaud, murl, edfpi, pdfpi, exdf, pdfe, d);
}
@end
