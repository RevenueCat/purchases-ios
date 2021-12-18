//
//  RevenueCatAPI.m
//  MigrateTester
//
//  Created by Joshua Liebowitz on 6/18/21.
//

@import RevenueCat;
@import StoreKit;

#import "RCPurchasesAPI.h"

@implementation RCPurchasesAPI

bool canI;
NSString *version;

BOOL automaticAppleSearchAdsAttributionCollection;
BOOL debugLogsEnabled;
RCLogLevel logLevel;
NSURL *proxyURL;
BOOL forceUniversalAppStore;
BOOL simulatesAskToBuyInSandbox;
RCPurchases *sharedPurchases;
BOOL isConfigured;
BOOL allowSharingAppStoreAccount;
BOOL finishTransactions;
id<RCPurchasesDelegate> delegate;
NSString *appUserID;
BOOL isAnonymous;

+ (void)checkAPI {
    RCPurchases *p = [RCPurchases configureWithAPIKey:@""];
    [RCPurchases configureWithAPIKey:@"" appUserID:@""];
    [RCPurchases configureWithAPIKey:@"" appUserID:nil];
    [RCPurchases configureWithAPIKey:@"" appUserID:@"" observerMode:false];
    [RCPurchases configureWithAPIKey:@"" appUserID:nil observerMode:false];
    [RCPurchases configureWithAPIKey:@"" appUserID:@"" observerMode:false userDefaults:nil];
    [RCPurchases configureWithAPIKey:@"" appUserID:nil observerMode:false userDefaults:nil];
    [RCPurchases configureWithAPIKey:@"" appUserID:@"" observerMode:false userDefaults:[[NSUserDefaults alloc] init]];
    [RCPurchases configureWithAPIKey:@"" appUserID:nil observerMode:false userDefaults:[[NSUserDefaults alloc] init]];
    
    [RCPurchases setLogHandler:^(RCLogLevel l, NSString *i) {}];
    canI = [RCPurchases canMakePayments];
    version = [RCPurchases frameworkVersion];

    // all should have deprecation warning:
    // 'addAttributionData:fromNetwork:' is deprecated: Use the set<NetworkId> functions instead.
    [RCPurchases addAttributionData:@{} fromNetwork:RCAttributionNetworkBranch];
    [RCPurchases addAttributionData:@{} fromNetwork:RCAttributionNetworkBranch forNetworkUserId:@""];
    [RCPurchases addAttributionData:@{} fromNetwork:RCAttributionNetworkBranch forNetworkUserId:nil];
        
    automaticAppleSearchAdsAttributionCollection = [RCPurchases automaticAppleSearchAdsAttributionCollection];

    // should have deprecation warning 'debugLogsEnabled' is deprecated: use logLevel instead
    debugLogsEnabled = [RCPurchases debugLogsEnabled];

    logLevel = [RCPurchases logLevel];
    proxyURL = [RCPurchases proxyURL];
    forceUniversalAppStore = [RCPurchases forceUniversalAppStore];
    simulatesAskToBuyInSandbox = [RCPurchases simulatesAskToBuyInSandbox];
    sharedPurchases = [RCPurchases sharedPurchases];
    isConfigured = [RCPurchases isConfigured];

    // should have deprecation warning:
    // 'allowSharingAppStoreAccount' is deprecated: Configure behavior through the RevenueCat dashboard instead.
    allowSharingAppStoreAccount = [p allowSharingAppStoreAccount];

    finishTransactions = [p finishTransactions];
    delegate = [p delegate];
    appUserID = [p appUserID];
    isAnonymous = [p isAnonymous];
    
    RCCustomerInfo *pi = nil;
    SKProduct *skp = [[SKProduct alloc] init];
    SKProductDiscount *skpd = [[SKProductDiscount alloc] init];
    SKPaymentDiscount *skmd = [[SKPaymentDiscount alloc] init];
    
    RCPackage *pack;

    [p invalidateCustomerInfoCache];

    NSDictionary<NSString *, NSString *> *attributes = nil;
    [p setAttributes: attributes];
    [p setEmail: nil];
    [p setEmail: @""];
    [p setPhoneNumber: nil];
    [p setPhoneNumber: @""];
    [p setDisplayName: nil];
    [p setDisplayName: @""];
    [p setPushToken: nil];
    [p setPushToken: [@"" dataUsingEncoding: NSUTF8StringEncoding]];
    [p setAdjustID: nil];
    [p setAdjustID: @""];
    [p setAppsflyerID: nil];
    [p setAppsflyerID: @""];
    [p setFBAnonymousID: nil];
    [p setFBAnonymousID: @""];
    [p setMparticleID: nil];
    [p setMparticleID: @""];
    [p setOnesignalID: nil];
    [p setOnesignalID: @""];
    [p setMediaSource: nil];
    [p setMediaSource: @""];
    [p setCampaign: nil];
    [p setCampaign: @""];
    [p setAdGroup: nil];
    [p setAdGroup: @""];
    [p setAd: nil];
    [p setAd: @""];
    [p setKeyword: nil];
    [p setKeyword: @""];
    [p setCreative: nil];
    [p setCreative: @""];
    [p collectDeviceIdentifiers];
    
    [p getCustomerInfoWithCompletion:^(RCCustomerInfo *info, NSError *error) {}];
    [p getOfferingsWithCompletion:^(RCOfferings *info, NSError *error) {}];
    [p getProductsWithIdentifiers:@[@""] completion:^(NSArray<SKProduct *> *products) { }];
    [p purchaseProduct:skp withCompletion:^(SKPaymentTransaction *t, RCCustomerInfo *i, NSError *error, BOOL userCancelled) { }];
    [p purchasePackage:pack withCompletion:^(SKPaymentTransaction *t, RCCustomerInfo *i, NSError *e, BOOL userCancelled) { }];
    [p restoreTransactionsWithCompletion:^(RCCustomerInfo *i, NSError *e) {}];
    [p syncPurchasesWithCompletion:^(RCCustomerInfo *i, NSError *e) {}];
    [p checkTrialOrIntroductoryPriceEligibility:@[@""] completion:^(NSDictionary<NSString *,RCIntroEligibility *> *d) { }];
    [p paymentDiscountForProductDiscount:skpd product:skp completion:^(SKPaymentDiscount *d, NSError *e) { }];
    [p purchaseProduct:skp withDiscount:skmd completion:^(SKPaymentTransaction *t, RCCustomerInfo *i, NSError *e, BOOL userCancelled) { }];
    [p purchasePackage:pack withDiscount:skmd completion:^(SKPaymentTransaction *t, RCCustomerInfo *i, NSError *e, BOOL userCancelled) { }];
    
    [p logIn:@"" completion:^(RCCustomerInfo *i, BOOL created, NSError *e) { }];
    [p logOutWithCompletion:^(RCCustomerInfo *i, NSError *e) { }];

    [p.delegate purchases:p receivedUpdatedCustomerInfo:pi];
    [p.delegate purchases:p
shouldPurchasePromoProduct:skp
           defermentBlock:^(void (^ _Nonnull completion)(SKPaymentTransaction * _Nullable transaction,
                                                         RCCustomerInfo * _Nullable info,
                                                         NSError * _Nullable error,
                                                         BOOL cancelled)) {}];

#if (TARGET_OS_IPHONE || TARGET_OS_MACCATALYST) && !TARGET_OS_TV
    [p beginRefundRequestForProductID:@"1234" completion:^(RCRefundRequestStatus s, NSError * _Nullable e) { }];
    [p beginRefundRequestForEntitlementID:@"" completion:^(RCRefundRequestStatus s, NSError * _Nullable e) { }];
    [p beginRefundRequestForActiveEntitlementWithCompletion:^(RCRefundRequestStatus s, NSError * _Nullable e) { }];
#endif

#if TARGET_OS_IPHONE && !TARGET_OS_TV
    [p presentCodeRedemptionSheet];
#endif
}

+ (void)checkEnums {
    RCPeriodType t = RCNormal;
    switch(t) {
        case RCNormal:
        case RCIntro:
        case RCTrial:
            NSLog(@"%ld", (long)t);
    }

    RCPurchaseOwnershipType o = RCPurchaseOwnershipTypePurchased;
    switch(o) {
        case RCPurchaseOwnershipTypePurchased:
        case RCPurchaseOwnershipTypeFamilyShared:
        case RCPurchaseOwnershipTypeUnknown:
            NSLog(@"%ld", (long)o);
    }

    RCLogLevel l = RCLogLevelInfo;
    switch(l) {
        case RCLogLevelInfo:
        case RCLogLevelWarn:
        case RCLogLevelDebug:
        case RCLogLevelError:
            NSLog(@"%ld", (long)o);
    }
}

+ (void)checkConstants {
    NSErrorDomain ped = RCPurchasesErrorCodeDomain;
    NSLog(@"%@", ped);
}

@end
