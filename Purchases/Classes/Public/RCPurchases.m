//
//  RCPurchases.m
//  Purchases
//
//  Created by Jacob Eiting on 9/29/17.
//  Copyright © 2018 RevenueCat, Inc. All rights reserved.
//

#import "RCPurchases.h"
#import "RCPurchases+Protected.h"

#import "RCStoreKitRequestFetcher.h"
#import "RCBackend.h"
#import "RCStoreKitWrapper.h"
#import "RCPurchaserInfo+Protected.h"
#import "RCUtils.h"
#import "NSLocale+RCExtensions.h"
#import "RCPurchaserInfo.h"
#import "RCCrossPlatformSupport.h"
#import "RCEntitlement+Protected.h"
#import "RCOffering+Protected.h"

@interface RCPurchases () <RCStoreKitWrapperDelegate>

@property (nonatomic) NSString *appUserID;

@property (nonatomic) RCStoreKitRequestFetcher *requestFetcher;
@property (nonatomic) RCBackend *backend;
@property (nonatomic) RCStoreKitWrapper *storeKitWrapper;
@property (nonatomic) NSNotificationCenter *notificationCenter;
@property (nonatomic) NSUserDefaults *userDefaults;

@property (nonatomic) NSDate *cachesLastUpdated;
@property (nonatomic) NSDictionary<NSString *, RCEntitlement *> *cachedEntitlements;
@property (nonatomic) NSMutableDictionary<NSString *, SKProduct *> *productsByIdentifier;

@property (nonatomic) BOOL isUsingAnonymousID;

@end

NSString * RCAppUserDefaultsKey = @"com.revenuecat.userdefaults.appUserID";
NSString * RCPurchaserInfoAppUserDefaultsKeyBase = @"com.revenuecat.userdefaults.purchaserInfo.";

@implementation RCPurchases

- (instancetype _Nullable)initWithAPIKey:(NSString *)APIKey
{
    return [self initWithAPIKey:APIKey appUserID:nil];
}

- (instancetype _Nullable)initWithAPIKey:(NSString *)APIKey appUserID:(NSString * _Nullable)appUserID
{
    return [self initWithAPIKey:APIKey appUserID:appUserID userDefaults:nil];
}

- (instancetype _Nullable)initWithAPIKey:(NSString *)APIKey
                               appUserID:(NSString * _Nullable)appUserID
                            userDefaults:(NSUserDefaults * _Nullable)userDefaults
{
    RCStoreKitRequestFetcher *fetcher = [[RCStoreKitRequestFetcher alloc] init];
    RCBackend *backend = [[RCBackend alloc] initWithAPIKey:APIKey];
    RCStoreKitWrapper *storeKitWrapper = [[RCStoreKitWrapper alloc] init];

    if (userDefaults == nil) {
        userDefaults = [NSUserDefaults standardUserDefaults];
    }

    return [self initWithAppUserID:appUserID
                    requestFetcher:fetcher
                           backend:backend
                   storeKitWrapper:storeKitWrapper
                notificationCenter:[NSNotificationCenter defaultCenter]
                      userDefaults:userDefaults];
}

+ (NSString *)frameworkVersion {
    return @"1.0.0";
}

- (instancetype _Nullable)initWithAppUserID:(NSString *)appUserID
                             requestFetcher:(RCStoreKitRequestFetcher *)requestFetcher
                                    backend:(RCBackend *)backend
                            storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
                         notificationCenter:(NSNotificationCenter *)notificationCenter
                               userDefaults:(NSUserDefaults *)userDefaults
{
    if (self = [super init]) {

        if (appUserID == nil) {
            appUserID = [userDefaults stringForKey:RCAppUserDefaultsKey];
            if (appUserID == nil) {
                NSString *generatedUserID = NSUUID.new.UUIDString;
                [userDefaults setObject:generatedUserID forKey:RCAppUserDefaultsKey];
                appUserID = generatedUserID;
            }
            self.isUsingAnonymousID = YES;
        }
        self.appUserID = appUserID;

        self.requestFetcher = requestFetcher;
        self.backend = backend;
        self.storeKitWrapper = storeKitWrapper;
        
        self.notificationCenter = notificationCenter;
        self.userDefaults = userDefaults;

        self.productsByIdentifier = [NSMutableDictionary new];
    }

    return self;
}

- (void)dealloc
{
    self.delegate = nil;
}

@synthesize delegate=_delegate;

- (void)setDelegate:(id<RCPurchasesDelegate>)delegate
{
    _delegate = delegate;

    if (delegate != nil) {
        self.storeKitWrapper.delegate = self;
        [self.notificationCenter addObserver:self
                                    selector:@selector(applicationDidBecomeActive:)
                                        name:APP_DID_BECOME_ACTIVE_NOTIFICATION_NAME object:nil];
        [self readPurchaserInfoFromCache];
        [self updateCaches];
    } else {
        self.storeKitWrapper.delegate = nil;
        [self.notificationCenter removeObserver:self
                                           name:APP_DID_BECOME_ACTIVE_NOTIFICATION_NAME
                                         object:nil];
    }
}

- (id<RCPurchasesDelegate>)delegate
{
    return _delegate;
}

- (void)applicationDidBecomeActive:(__unused NSNotification *)notif
{
    [self updateCaches];
}

- (void)readPurchaserInfoFromCache {
    NSData *purchaserInfoData = [self.userDefaults dataForKey:self.purchaserInfoUserDefaultCacheKey];
    if (purchaserInfoData) {
        NSError *jsonError;
        NSDictionary *infoDict = [NSJSONSerialization JSONObjectWithData:purchaserInfoData options:0 error:&jsonError];
        if (jsonError == nil && infoDict != nil) {
            RCPurchaserInfo *info = [[RCPurchaserInfo alloc] initWithData:infoDict];
            if (info) {
                [self handleUpdatedPurchaserInfo:info error:nil];
            }
        }
    }
}

- (void)cachePurchaserInfo:(RCPurchaserInfo *)info {
    if (info.JSONObject) {
        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:info.JSONObject
                                                           options:0
                                                             error:&jsonError];
        if (jsonError == nil) {
            [self.userDefaults setObject:jsonData
                                  forKey:self.purchaserInfoUserDefaultCacheKey];
        }
    }
}

- (void)updateCaches
{
    NSTimeInterval timeSinceLastCheck = -[self.cachesLastUpdated timeIntervalSinceNow];
    if (self.cachesLastUpdated != nil && timeSinceLastCheck < 60.) {
        [self readPurchaserInfoFromCache];
        return;
    }

    self.cachesLastUpdated = [NSDate date];

    [self.backend getSubscriberDataWithAppUserID:self.appUserID
                                      completion:^(RCPurchaserInfo * _Nullable info,
                                                   NSError * _Nullable error) {
        if (error == nil) {
            [self handleUpdatedPurchaserInfo:info error:nil];
        } else {
            self.cachesLastUpdated = nil;
        }
    }];

    [self getEntitlements:^(NSDictionary<NSString *,RCEntitlement *> *entitlements) {}];
}

-(NSDictionary<NSString *, RCEntitlement *> * _Nullable)entitlements
{
    return self.cachedEntitlements;
}

- (void)performOnEachOfferingInEntitlements:(NSDictionary<NSString *,RCEntitlement *> *)entitlements block:(void (^)(RCOffering *offering))block
{
    for (NSString *entitlementID in entitlements) {
        RCEntitlement *entitlement = entitlements[entitlementID];
        for (NSString *offeringID in entitlement.offerings) {
            RCOffering *offering = entitlement.offerings[offeringID];
            block(offering);
        }
    }
}

- (void)entitlements:(void (^)(NSDictionary<NSString *, RCEntitlement *> *))completion
{
    if (self.cachedEntitlements) {
        completion(self.cachedEntitlements);
    } else {
        [self getEntitlements:completion];
    }
}

- (void)getEntitlements:(void (^)(NSDictionary<NSString *, RCEntitlement *> *entitlements))completion
{
    [self.backend getEntitlementsForAppUserID:self.appUserID
                                   completion:^(NSDictionary<NSString *,RCEntitlement *> *entitlements) {
                                       NSMutableSet *productIdentifiers = [NSMutableSet new];

                                       [self performOnEachOfferingInEntitlements:entitlements block:^(RCOffering *offering) {
                                           [productIdentifiers addObject:offering.activeProductIdentifier];
                                       }];

                                       [self.requestFetcher fetchProducts:productIdentifiers completion:^(NSArray<SKProduct *> * _Nonnull products) {
                                           NSMutableDictionary *productsById = [NSMutableDictionary new];
                                           for (SKProduct *p in products) {
                                               productsById[p.productIdentifier] = p;
                                           }

                                           [self performOnEachOfferingInEntitlements:entitlements block:^(RCOffering *offering) {
                                               offering.activeProduct = productsById[offering.activeProductIdentifier];
                                           }];

                                           if (entitlements != nil) {
                                               self.cachedEntitlements = entitlements;
                                           } else {
                                               self.cachesLastUpdated = nil;
                                           }

                                           completion(entitlements);
                                       }];

    }];
}

- (void)productsWithIdentifiers:(NSSet<NSString *> *)productIdentifiers
                     completion:(void (^)(NSArray<SKProduct *>* products))completion
{
    [self.requestFetcher fetchProducts:productIdentifiers completion:^(NSArray<SKProduct *> * _Nonnull products) {
        @synchronized(self) {
            for (SKProduct *product in products) {
                self.productsByIdentifier[product.productIdentifier] = product;
            }
        }
        completion(products);
    }];
}

- (void)updatedPurchaserInfo
{
    [self.backend getSubscriberDataWithAppUserID:self.appUserID completion:^(RCPurchaserInfo * _Nullable purchaserInfo, NSError * _Nullable error) {

        [self handleUpdatedPurchaserInfo:purchaserInfo error:error];
    }];
}

- (void)checkTrialOrIntroductoryPriceEligibility:(NSArray<NSString *> *)productIdentifiers
                                      completion:(RCReceiveIntroEligibilityBlock)receiveEligibility
{
    [self receiptData:^(NSData * _Nonnull data) {
        [self.backend getIntroElgibilityForAppUserID:self.appUserID
                                         receiptData:data
                                  productIdentifiers:productIdentifiers
                                          completion:receiveEligibility];
    }];
}

- (void)makePurchase:(SKProduct *)product
{
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    payment.applicationUsername = self.appUserID;

    [self.storeKitWrapper addPayment:payment];
}

- (void)receiptData:(void (^ _Nonnull)(NSData * _Nonnull data))completion
{
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    if (receiptData == nil) {
        [self.requestFetcher fetchReceiptData:^{
            NSData *newReceiptData = [NSData dataWithContentsOfURL:receiptURL];
            completion(newReceiptData ?: [NSData data]);
        }];
    } else {
        completion(receiptData);
    }
}

- (void)handleReceiptPostWithTransaction:(SKPaymentTransaction *)transaction
                           purchaserInfo:(RCPurchaserInfo * _Nullable)info
                                   error:(NSError * _Nullable)error
{
    if (info) {
        [self cachePurchaserInfo:info];
        [self.delegate purchases:self
            completedTransaction:transaction
                 withUpdatedInfo:info];
        [self.storeKitWrapper finishTransaction:transaction];
    } else if (error.code == RCFinishableError) {
        [self.delegate purchases:self failedTransaction:transaction withReason:error];
        [self.storeKitWrapper finishTransaction:transaction];
    } else if (error.code == RCUnfinishableError) {
        [self.delegate purchases:self failedTransaction:transaction withReason:error];
    } else {
        RCLog(@"Unexpected error from backend");
        [self.delegate purchases:self failedTransaction:transaction withReason:error];
    }
}

/*
 RCStoreKitWrapperDelegate
 */

- (void)storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
     updatedTransaction:(SKPaymentTransaction *)transaction
{
    switch (transaction.transactionState) {
        case SKPaymentTransactionStatePurchased: {
            [self handlePurchasedTransaction:transaction];
            break;
        }
        case SKPaymentTransactionStateFailed: {
            [self.delegate purchases:self failedTransaction:transaction withReason:transaction.error];
            [self.storeKitWrapper finishTransaction:transaction];
            break;
        }
        case SKPaymentTransactionStateDeferred:
        case SKPaymentTransactionStatePurchasing:
        case SKPaymentTransactionStateRestored:
            break;
    }    
}

- (void)storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
     removedTransaction:(SKPaymentTransaction *)transaction
{

}

- (BOOL)storeKitWrapper:(nonnull RCStoreKitWrapper *)storeKitWrapper shouldAddStorePayment:(nonnull SKPayment *)payment forProduct:(nonnull SKProduct *)product {
    @synchronized(self) {
        self.productsByIdentifier[product.productIdentifier] = product;
    }
    
    if ([(id<NSObject>)self.delegate respondsToSelector:@selector(purchases:shouldPurchasePromoProduct:defermentBlock:)]) {
        return [self.delegate purchases:self shouldPurchasePromoProduct:product defermentBlock:^{
            [self.storeKitWrapper addPayment:payment];
        }];
    } else {
        return NO;
    }
}


- (SKProduct * _Nullable)productForIdentifier:(NSString *)productIdentifier
{
    @synchronized(self) {
        return self.productsByIdentifier[productIdentifier];
    }
}

- (NSString *)purchaserInfoUserDefaultCacheKey {
    return [RCPurchaserInfoAppUserDefaultsKeyBase stringByAppendingString:self.appUserID];
}

- (void)handleUpdatedPurchaserInfo:(RCPurchaserInfo * _Nullable)info error:(NSError * _Nullable)error
{
    if (error) {
        [self.delegate purchases:self failedToUpdatePurchaserInfoWithError:error];
    } else if (info) {
        [self cachePurchaserInfo:info];
        [self.delegate purchases:self receivedUpdatedPurchaserInfo:info];
    }
}

- (void)handlePurchasedTransaction:(SKPaymentTransaction *)transaction
{
    [self receiptData:^(NSData * _Nonnull data) {
        SKProduct *product = [self productForIdentifier:transaction.payment.productIdentifier];

        NSString *productIdentifier = product.productIdentifier;
        NSDecimalNumber *price = product.price;

        RCPaymentMode paymentMode = RCPaymentModeNone;
        NSDecimalNumber *introPrice = nil;

        if (@available(iOS 11.2, macOS 10.13.2, *)) {
            if (product.introductoryPrice) {
                paymentMode = RCPaymentModeFromSKProductDiscountPaymentMode(product.introductoryPrice.paymentMode);
                introPrice = product.introductoryPrice.price;
            }
        }

        NSString *currencyCode = product.priceLocale.rc_currencyCode;

        [self.backend postReceiptData:data
                            appUserID:self.appUserID
                            isRestore:self.isUsingAnonymousID
                    productIdentifier:productIdentifier
                                price:price
                          paymentMode:paymentMode
                    introductoryPrice:introPrice
                         currencyCode:currencyCode
                           completion:^(RCPurchaserInfo * _Nullable info,
                                        NSError * _Nullable error) {
                               [self handleReceiptPostWithTransaction:transaction
                                                        purchaserInfo:info
                                                                error:error];
                           }];
    }];
}

- (void)restoreTransactionsForAppStoreAccount
{
    // Refresh the receipt and post to backend, this will allow the transactions to be transferred.
    // https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/Restoring.html
    [self receiptData:^(NSData * _Nonnull data) {
        [self.backend postReceiptData:data
                            appUserID:self.appUserID
                            isRestore:YES
                    productIdentifier:nil
                                price:nil
                          paymentMode:RCPaymentModeNone
                    introductoryPrice:nil
                         currencyCode:nil
                           completion:^(RCPurchaserInfo * _Nullable info,
                                        NSError * _Nullable error) {
                               if (error) {
                                   [self.delegate purchases:self failedToRestoreTransactionsWithError:error];
                               } else if (info) {
                                   [self cachePurchaserInfo:info];
                                   [self.delegate purchases:self restoredTransactionsWithPurchaserInfo:info];
                               }
                           }];
    }];
}

- (void)updateOriginalApplicationVersion
{
    [self.backend getSubscriberDataWithAppUserID:self.appUserID completion:^(RCPurchaserInfo * _Nullable info,
                                                                             NSError * _Nullable error) {
        if (error) {
            [self.delegate purchases:self failedToUpdatePurchaserInfoWithError:error];
        } else if (info.originalApplicationVersion) {
            [self.delegate purchases:self receivedUpdatedPurchaserInfo:info];
        } else {
            [self receiptData:^(NSData * _Nonnull data) {
                [self.backend postReceiptData:data
                                    appUserID:self.appUserID
                                    isRestore:NO
                            productIdentifier:nil
                                        price:nil
                                  paymentMode:RCPaymentModeNone
                            introductoryPrice:nil
                                 currencyCode:nil
                                   completion:^(RCPurchaserInfo * _Nullable info, NSError * _Nullable error) {
                                       [self handleUpdatedPurchaserInfo:info error:error];
                                   }];
            }];
        }
    }];
}

@end
