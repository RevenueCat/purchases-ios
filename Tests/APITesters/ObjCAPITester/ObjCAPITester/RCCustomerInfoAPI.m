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
    RCCustomerInfo *ci = nil;
    RCEntitlementInfos *ei = ci.entitlements;
    NSSet<NSString *> *as = ci.activeSubscriptions;
    NSSet<NSString *> *appis = ci.allPurchasedProductIdentifiers;
    NSDate *led = ci.latestExpirationDate;
    NSSet<NSString *> *ncp = ci.nonConsumablePurchases;
    NSArray<RCNonSubscriptionTransaction *> *ns = ci.nonSubscriptions;
    NSArray<RCStoreTransaction *> *nst = ci.nonSubscriptionTransactions;
    NSString *oav = ci.originalApplicationVersion;
    NSDate *opd = ci.originalPurchaseDate;
    NSDate *rd = ci.requestDate;
    NSDate *fs = ci.firstSeen;
    NSString *oaud = ci.originalAppUserId;
    NSURL *murl = ci.managementURL;
    
    NSDate *edfpi = [ci expirationDateForProductIdentifier:@""];
    NSDate *pdfpi = [ci purchaseDateForProductIdentifier:@""];
    NSDate *exdf = [ci expirationDateForEntitlement:@""];
    NSDate *pdfe = [ci purchaseDateForEntitlement:@""];
    
    NSString *d = [ci description];

    NSDictionary<NSString *, id> *rawData = [ci rawData];
    
    NSLog(ci, ei, as, appis, led, ncp, ns, nst, oav, opd, rd, fs, oaud, murl, edfpi, pdfpi, exdf, pdfe, d, rawData);
}

+ (void)checkCacheFetchPolicyEnum:(RCCacheFetchPolicy) policy {
    switch (policy) {
        case RCCacheFetchPolicyFetchCurrent:
        case RCCacheFetchPolicyCachedOrFetched:
        case RCCacheFetchPolicyFromCacheOnly:
        case RCCacheFetchPolicyNotStaleCachedOrFetched:
            break;
    }
}

@end
