//
//  RCSubscriptionInfoAPI.m
//  AllAPITests
//
//  Created by Cesar de la Vega on 3/12/24.
//

#import "RCSubscriptionInfoAPI.h"

@import RevenueCat;

@implementation RCSubscriptionInfoAPI

+ (void)checkAPI {
    RCSubscriptionInfo *subscription;
    
    NSString *productIdentifier __unused = subscription.productIdentifier;
    NSDate *purchaseDate __unused = subscription.purchaseDate;
    NSDate *originalPurchaseDate __unused = subscription.originalPurchaseDate;
    NSDate *expiresDate __unused = subscription.expiresDate;
    RCStore store __unused = subscription.store;
    BOOL isSandbox __unused = subscription.isSandbox;
    NSDate *unsubscribeDetectedAt __unused = subscription.unsubscribeDetectedAt;
    NSDate *billingIssuesDetectedAt __unused = subscription.billingIssuesDetectedAt;
    NSDate *gracePeriodExpiresDate __unused = subscription.gracePeriodExpiresDate;
    RCPurchaseOwnershipType ownershipType __unused = subscription.ownershipType;
    RCPeriodType periodType __unused = subscription.periodType;
    NSDate *refundedAt __unused = subscription.refundedAt;
    NSString *storeTransactionId __unused = subscription.storeTransactionId;
    BOOL isActive __unused = subscription.isActive;
    BOOL willRenew __unused = subscription.willRenew;
    NSString *displayName __unused = subscription.displayName;
    NSURL *managementURL __unused = subscription.managementURL;
}

@end
