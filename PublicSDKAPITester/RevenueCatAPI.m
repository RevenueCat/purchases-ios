//
//  RevenueCatAPI.m
//  MigrateTester
//
//  Created by Joshua Liebowitz on 6/18/21.
//

#import "RevenueCatAPI.h"
#import "Purchases.h"
#import "RCPurchases.h"

@import StoreKit;
@import PurchasesCoreSwift;

@implementation RevenueCatAPI

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

+ (void)allTheThings {
//    typedef void (^RCReceivePurchaserInfoBlock)(RCPurchaserInfo * _Nullable, NSError * _Nullable) NS_SWIFT_NAME(Purchases.ReceivePurchaserInfoBlock);
//    typedef void (^RCReceiveIntroEligibilityBlock)(NSDictionary<NSString *, RCIntroEligibility *> *) NS_SWIFT_NAME(Purchases.ReceiveIntroEligibilityBlock);
//    typedef void (^RCReceiveOfferingsBlock)(RCOfferings * _Nullable, NSError * _Nullable) NS_SWIFT_NAME(Purchases.ReceiveOfferingsBlock);
//    typedef void (^RCReceiveProductsBlock)(NSArray<SKProduct *> *) NS_SWIFT_NAME(Purchases.ReceiveProductsBlock);
//    typedef void (^RCPurchaseCompletedBlock)(SKPaymentTransaction * _Nullable, RCPurchaserInfo * _Nullable, NSError * _Nullable, BOOL userCancelled) NS_SWIFT_NAME(Purchases.PurchaseCompletedBlock);
//    typedef void (^RCDeferredPromotionalPurchaseBlock)(RCPurchaseCompletedBlock);
//    typedef void (^RCPaymentDiscountBlock)(SKPaymentDiscount * _Nullable, NSError * _Nullable) NS_SWIFT_NAME(Purchases.PaymentDiscountBlock);

    //    [p presentCodeRedemptionSheet]; ///TODO: iOS ONLY, TEST FOR THIS API BY LOOKING UP SELECTOR
    RCPurchases *p = [RCPurchases configureWithAPIKey:@""];
    
    [RCPurchases setLogHandler:^(RCLogLevel l, NSString *i) {}];
    canI = [RCPurchases canMakePayments];
    version = [RCPurchases frameworkVersion];
    [RCPurchases addAttributionData:@{} fromNetwork:RCAttributionNetworkBranch];
    [RCPurchases addAttributionData:@{} fromNetwork:RCAttributionNetworkBranch forNetworkUserId:@""];
        
    automaticAppleSearchAdsAttributionCollection = [RCPurchases automaticAppleSearchAdsAttributionCollection];
    debugLogsEnabled = [RCPurchases debugLogsEnabled];
    logLevel = [RCPurchases logLevel];
    proxyURL = [RCPurchases proxyURL];
    forceUniversalAppStore = [RCPurchases forceUniversalAppStore];
    simulatesAskToBuyInSandbox = [RCPurchases simulatesAskToBuyInSandbox];
    sharedPurchases = [RCPurchases sharedPurchases];
    isConfigured = [RCPurchases isConfigured];
    allowSharingAppStoreAccount = [p allowSharingAppStoreAccount];
    finishTransactions = [p finishTransactions];
    delegate = [p delegate];
    appUserID = [p appUserID];
    isAnonymous = [p isAnonymous];
    
    RCPurchaserInfo *pi = [[RCPurchaserInfo alloc] init];
    SKProduct *skp = [[SKProduct alloc] init];
    SKProductDiscount *skpd = [[SKProductDiscount alloc] init];
    SKPaymentDiscount *skmd = [[SKPaymentDiscount alloc] init];
    
    RCPackage *pack = [[RCPackage alloc] initWithIdentifier:@"" packageType:RCPackageTypeCustom product:skp offeringIdentifier:@""];
    [RCPurchases configureWithAPIKey:@"" appUserID:@""];
    [RCPurchases configureWithAPIKey:@"" appUserID:@"" observerMode:false];
    [RCPurchases configureWithAPIKey:@"" appUserID:@"" observerMode:false userDefaults:nil];
    
    [p invalidatePurchaserInfoCache];

    NSDictionary<NSString *, NSString *> *attributes = nil;
    [p setAttributes: attributes];
    [p setEmail: @""];
    [p setPhoneNumber: @""];
    [p setDisplayName: @""];
    [p setPushToken: [@"" dataUsingEncoding: NSUTF8StringEncoding]];
    [p setAdjustID: @""];
    [p setAppsflyerID: @""];
    [p setFBAnonymousID: @""];
    [p setMparticleID: @""];
    [p setOnesignalID: @""];
    [p setMediaSource: @""];
    [p setCampaign: @""];
    [p setAdGroup: @""];
    [p setAd: @""];
    [p setKeyword: @""];
    [p setCreative: @""];
    [p collectDeviceIdentifiers];
    
    [p purchaserInfoWithCompletionBlock:^(RCPurchaserInfo *info, NSError *error) {}];
    [p offeringsWithCompletionBlock:^(RCOfferings *info, NSError *error) {}];
    [p productsWithIdentifiers:@[@""] completionBlock:^(NSArray<SKProduct *> *products) { }];
    [p purchaseProduct:skp withCompletionBlock:^(SKPaymentTransaction *t, RCPurchaserInfo *i, NSError *error, BOOL userCancelled) { }];
    [p purchasePackage:pack withCompletionBlock:^(SKPaymentTransaction *t, RCPurchaserInfo *i, NSError *e, BOOL userCancelled) { }];
    [p restoreTransactionsWithCompletionBlock:^(RCPurchaserInfo *i, NSError *e) {}];
    [p syncPurchasesWithCompletionBlock:^(RCPurchaserInfo *i, NSError *e) {}];
    [p checkTrialOrIntroductoryPriceEligibility:@[@""] completionBlock:^(NSDictionary<NSString *,RCIntroEligibility *> *d) { }];
    [p checkTrialOrIntroductoryPriceEligibility:@[@""] completionBlock:^(NSDictionary<NSString *,RCIntroEligibility *> *r) { }];
    [p paymentDiscountForProductDiscount:skpd product:skp completion:^(SKPaymentDiscount *d, NSError *e) { }];
    [p purchaseProduct:skp withDiscount:skmd completionBlock:^(SKPaymentTransaction *t, RCPurchaserInfo *i, NSError *e, BOOL userCancelled) { }];
    [p purchasePackage:pack withDiscount:skmd completionBlock:^(SKPaymentTransaction *t, RCPurchaserInfo *i, NSError *e, BOOL userCancelled) { }];
    
    [p createAlias:@"" completionBlock:^(RCPurchaserInfo *i, NSError *e) { }];
    [p identify:@"" completionBlock:^(RCPurchaserInfo *i, NSError *e) { }];
    [p resetWithCompletionBlock:^(RCPurchaserInfo *i, NSError *e) { }];
        
    // RCPurchasesDelegate
    [p.delegate purchases:p didReceiveUpdatedPurchaserInfo:pi];
    [p.delegate purchases:p shouldPurchasePromoProduct:skp defermentBlock:^(RCPurchaseCompletedBlock makeDeferredPurchase) {}];
}



@end
