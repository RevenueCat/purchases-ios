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

BOOL debugLogsEnabled;
RCLogLevel logLevel;
NSURL *proxyURL;
BOOL forceUniversalAppStore;
BOOL simulatesAskToBuyInSandbox;
RCPurchases *sharedPurchases;
BOOL isConfigured;
BOOL allowSharingAppStoreAccount;
BOOL finishTransactions;
RCPurchasesAreCompletedBy purchasesAreCompletedBy;
id<RCPurchasesDelegate> delegate;
NSString *appUserID;
BOOL isAnonymous;
NSString *storeFrontCountryCode;
NSLocale *storeFrontLocale;
RCWebPurchaseRedemption *webPurchaseRedemptionLink;
NSURL *url;

+ (void)checkAPI {
    RCPurchases *p = [RCPurchases configureWithAPIKey:@""];
    [RCPurchases configureWithConfiguration:[[RCConfiguration builderWithAPIKey:@""] build]];
    [RCPurchases configureWithConfigurationBuilder:[RCConfiguration builderWithAPIKey:@""]];
    [RCPurchases configureWithAPIKey:@"" appUserID:@""];
    [RCPurchases configureWithAPIKey:@"" appUserID:nil];
    [RCPurchases configureWithAPIKey:@"" appUserID:@"" purchasesAreCompletedBy:RCPurchasesAreCompletedByRevenueCat storeKitVersion:RCStoreKitVersion2];
    [RCPurchases configureWithAPIKey:@"" appUserID:nil purchasesAreCompletedBy:RCPurchasesAreCompletedByMyApp storeKitVersion:RCStoreKitVersion1];

    [RCPurchases setLogHandler:^(RCLogLevel l, NSString *i) {}];
    canI = [RCPurchases canMakePayments];
    version = [RCPurchases frameworkVersion];

    // all should have deprecation warning:
    // 'addAttributionData:fromNetwork:' is deprecated: Use the set<NetworkId> functions instead.
    [RCPurchases addAttributionData:@{} fromNetwork:RCAttributionNetworkBranch];
    [RCPurchases addAttributionData:@{} fromNetwork:RCAttributionNetworkBranch forNetworkUserId:@""];
    [RCPurchases addAttributionData:@{} fromNetwork:RCAttributionNetworkBranch forNetworkUserId:nil];

    // should have deprecation warning 'debugLogsEnabled' is deprecated: use logLevel instead
    debugLogsEnabled = [RCPurchases debugLogsEnabled];

    logLevel = [RCPurchases logLevel];
    proxyURL = [RCPurchases proxyURL];
    forceUniversalAppStore = [RCPurchases forceUniversalAppStore];
    simulatesAskToBuyInSandbox = [RCPurchases simulatesAskToBuyInSandbox];
    sharedPurchases = [RCPurchases sharedPurchases];
    isConfigured = [RCPurchases isConfigured];
    RCWebPurchaseRedemption *webPurchaseRedemption = [RCPurchases parseAsWebPurchaseRedemption:url];

    // should have deprecation warning:
    // 'allowSharingAppStoreAccount' is deprecated: Configure behavior through the RevenueCat dashboard instead.
    allowSharingAppStoreAccount = [p allowSharingAppStoreAccount];

    finishTransactions = [p finishTransactions];
    purchasesAreCompletedBy = [p purchasesAreCompletedBy];

    delegate = [p delegate];
    appUserID = [p appUserID];
    isAnonymous = [p isAnonymous];
    storeFrontCountryCode = [p storeFrontCountryCode];
    if (@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)) {
        storeFrontLocale = [p storeFrontLocale];
    }

    RCCustomerInfo *pi = nil;
    RCStoreProduct *storeProduct = nil;
    RCStoreProductDiscount *stpd = nil;
    RCPromotionalOffer *pro = nil;
    
    RCPackage *pack;

    [p invalidateCustomerInfoCache];

    NSDictionary<NSString *, NSString *> *attributes = nil;
    RCAttribution __unused *attribution = p.attribution;
    [p setAttributes: attributes];
    [p setEmail: nil];
    [p setEmail: @""];
    [p setPhoneNumber: nil];
    [p setPhoneNumber: @""];
    [p setDisplayName: nil];
    [p setDisplayName: @""];
    [p setPushToken: nil];
    [p setPushToken: [@"" dataUsingEncoding: NSUTF8StringEncoding]];
    [p setPushTokenString: @""];
    [p setPushTokenString: nil];
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
    [p setCleverTapID: nil];
    [p setCleverTapID: @""];
    [p setMixpanelDistinctID: nil];
    [p setMixpanelDistinctID: @""];
    [p setFirebaseAppInstanceID: nil];
    [p setFirebaseAppInstanceID: @""];
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
    #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
    RCPurchaseParams *purchaseParams;
    [p params:purchaseParams withCompletion:^(RCStoreTransaction *t, RCCustomerInfo *i, NSError *error, BOOL userCancelled) { }];
    #endif

    [p getCustomerInfoWithFetchPolicy:RCCacheFetchPolicyFetchCurrent completion:^(RCCustomerInfo *customerInfo,
                                                                                  NSError *error) {}];
    [p getCustomerInfoWithCompletion:^(RCCustomerInfo *info, NSError *error) {}];
    RCCustomerInfo * _Nullable __unused cachedCustomerInfo = p.cachedCustomerInfo;

    [p getOfferingsWithCompletion:^(RCOfferings *info, NSError *error) {}];
    RCOfferings * _Nullable __unused offerings = p.cachedOfferings;

    #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
    RCPurchaseParamsBuilder *packageParamBuilder = [[[RCPurchaseParamsBuilder alloc] initWithPackage:pack] withPromotionalOffer:pro];

    #if ENABLE_TRANSACTION_METADATA
    packageParamBuilder = [packageParamBuilder withMetadata:@{@"foo": @"bar"}];
    #endif
    RCPurchaseParams *packageParams = [packageParamBuilder build];


    RCPurchaseParamsBuilder *productParamBuilder = [[[RCPurchaseParamsBuilder alloc] initWithProduct:storeProduct] withPromotionalOffer:pro];
    #if ENABLE_TRANSACTION_METADATA
    productParamBuilder = [packageParamBuilder withMetadata:@{@"foo": @"bar"}];
    #endif
    RCPurchaseParams *productParams = [productParamBuilder build];

    // Win-back offers
    if (@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)) {
        [p eligibleWinBackOffersForProduct:storeProduct
                                completion:^(NSArray<RCWinBackOffer *> *winBackOffers, NSError *error) {
            RCPurchaseParams *productParams = [[[[RCPurchaseParamsBuilder alloc] initWithProduct:storeProduct]
                                                withWinBackOffer:winBackOffers.firstObject]
                                               build];
        }];

        [p eligibleWinBackOffersForPackage:pack
                                completion:^(NSArray<RCWinBackOffer *> *winBackOffers, NSError *error) {
            RCPurchaseParams *packageParams = [[[[RCPurchaseParamsBuilder alloc] initWithPackage:pack]
                                                withWinBackOffer:winBackOffers.firstObject]
                                               build];
        }];
    }

    [p purchaseWithParams:productParams completion:^(RCStoreTransaction *t, RCCustomerInfo *i, NSError *error, BOOL userCancelled) { }];
    [p purchaseWithParams:packageParams completion:^(RCStoreTransaction *t, RCCustomerInfo *i, NSError *error, BOOL userCancelled) { }];
    #endif

    [p getProductsWithIdentifiers:@[@""] completion:^(NSArray<RCStoreProduct *> *products) { }];
    [p purchaseProduct:storeProduct withCompletion:^(RCStoreTransaction *t, RCCustomerInfo *i, NSError *error, BOOL userCancelled) { }];
    [p purchasePackage:pack withCompletion:^(RCStoreTransaction *t, RCCustomerInfo *i, NSError *e, BOOL userCancelled) { }];
    [p restorePurchasesWithCompletion:^(RCCustomerInfo *i, NSError *e) {}];
    [p syncPurchasesWithCompletion:^(RCCustomerInfo *i, NSError *e) {}];
    
    [p checkTrialOrIntroDiscountEligibilityForProduct:storeProduct completion:^(RCIntroEligibilityStatus status) { }];
    [p checkTrialOrIntroDiscountEligibility:@[@""] completion:^(NSDictionary<NSString *,RCIntroEligibility *> *d) { }];
    [p getPromotionalOfferForProductDiscount:stpd
                                 withProduct:storeProduct
                              withCompletion:^(RCPromotionalOffer *offer, NSError *error) { }];
    [p purchaseProduct:storeProduct withPromotionalOffer:pro completion:^(RCStoreTransaction *t, RCCustomerInfo *i, NSError *e, BOOL userCancelled) { }];
    [p purchasePackage:pack withPromotionalOffer:pro completion:^(RCStoreTransaction *t, RCCustomerInfo *i, NSError *e, BOOL userCancelled) { }];

    [p logIn:@"" completion:^(RCCustomerInfo *i, BOOL created, NSError *e) { }];
    [p logOutWithCompletion:^(RCCustomerInfo *i, NSError *e) { }];

    [p redeemWebPurchaseWithWebPurchaseRedemption:webPurchaseRedemptionLink
                                       completion:^(RCCustomerInfo * _Nullable ci, NSError * _Nullable e) { }];

    [p.delegate purchases:p receivedUpdatedCustomerInfo:pi];
    [p.delegate purchases:p
  readyForPromotedProduct:storeProduct
                 purchase:^(void (^ _Nonnull completion)(RCStoreTransaction * _Nullable transaction,
                                                         RCCustomerInfo * _Nullable info,
                                                         NSError * _Nullable error,
                                                         BOOL cancelled)) {

    }];

    [p getVirtualCurrenciesWithCompletion: ^(RCVirtualCurrencies * _Nullable virtualCurrencies, NSError * _Nullable error) {

    }];

    [p invalidateVirtualCurrenciesCache];

    RCVirtualCurrencies * _Nullable __unused virtualCurrencies = p.cachedVirtualCurrencies;

    if (@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)) {
        [p recordPurchaseForProductID:@"product_id" completion:^(RCStoreTransaction * _Nullable transaction, NSError * _Nullable error) { }];
    }

#if (TARGET_OS_IPHONE || TARGET_OS_MACCATALYST) && !TARGET_OS_TV && !TARGET_OS_WATCH
    if (@available(iOS 15.0, *)) {
        [p beginRefundRequestForProduct:@"1234" completion:^(RCRefundRequestStatus s, NSError * _Nullable e) { }];
        [p beginRefundRequestForEntitlement:@"" completion:^(RCRefundRequestStatus s, NSError * _Nullable e) { }];
        [p beginRefundRequestForActiveEntitlementWithCompletion:^(RCRefundRequestStatus s, NSError * _Nullable e) { }];
    }

    if (@available(iOS 16.0, *)) {
        [p showStoreMessagesWithCompletion:^{ }];
        [p showStoreMessagesForTypes:[NSSet setWithObject:@(RCStoreMessageTypeBillingIssue)] completion:^{ }];
    }

    if (@available(iOS 13.4, *)) {
        [p showPriceConsentIfNeeded];
        BOOL consent __unused = [p.delegate shouldShowPriceConsent];
    }
#endif

#if TARGET_OS_IPHONE && !TARGET_OS_TV && !TARGET_OS_WATCH
    if (@available(iOS 14.0, *)) {
        [p presentCodeRedemptionSheet];
    }
#endif

    [p getStorefrontWithCompletion:^(RCStorefront * _Nullable s) { }];
}

+ (void)checkEnums {
    RCPeriodType t = RCNormal;
    switch(t) {
        case RCNormal:
        case RCIntro:
        case RCTrial:
        case RCPrepaid:
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
        case RCLogLevelVerbose:
        case RCLogLevelDebug:
        case RCLogLevelInfo:
        case RCLogLevelWarn:
        case RCLogLevelError:
            NSLog(@"%ld", (long)l);
    }

    RCStoreMessageType smt = RCStoreMessageTypeBillingIssue;
    switch(smt) {
        case RCStoreMessageTypeBillingIssue:
        case RCStoreMessageTypePriceIncreaseConsent:
        case RCStoreMessageTypeGeneric:
        case RCStoreMessageTypeWinBackOffer:
            NSLog(@"%ld", (long)smt);
    }

    RCPurchasesAreCompletedBy pacb = RCPurchasesAreCompletedByRevenueCat;
    switch(pacb) {
        case RCPurchasesAreCompletedByMyApp:
        case RCPurchasesAreCompletedByRevenueCat:
            NSLog(@"%ld", (long)pacb);
    }
}

+ (void)checkConstants {
    NSErrorDomain ped = RCPurchasesErrorCodeDomain;
    NSLog(@"%@", ped);
}

@end
