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

NSErrorDomain const RCPurchasesAPIErrorDomain = @"RCPurchasesAPIErrorDomain";

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
@property (nonatomic) NSMutableDictionary<NSString *, RCPurchaseCompletedBlock> *purchaseCompleteCallbacks;

@end

NSString * RCAppUserDefaultsKey = @"com.revenuecat.userdefaults.appUserID";
NSString * RCPurchaserInfoAppUserDefaultsKeyBase = @"com.revenuecat.userdefaults.purchaserInfo.";

@implementation RCPurchases

static RCPurchases *_sharedPurchases = nil;
@synthesize delegate=_delegate;

+ (NSString *)frameworkVersion {
    return @"1.3.0-SNAPSHOT";
}

+ (instancetype)sharedPurchases {
    if (!_sharedPurchases) {
        RCLog(@"There is no singleton instance. Make sure you configure Purchases before trying to get the default instance.");
    }
    return _sharedPurchases;
}

+ (void)setDefaultInstance:(RCPurchases *)instance {
    @synchronized([RCPurchases class]) {
        _sharedPurchases = instance;
    }
}

+ (instancetype)configureWithAPIKey:(NSString *)APIKey
{
    RCPurchases *purchases = [[RCPurchases alloc] initWithAPIKey:APIKey];
    [RCPurchases setDefaultInstance:purchases];
    return purchases;
}

- (instancetype)initWithAPIKey:(NSString *)APIKey
{
    return [self initWithAPIKey:APIKey appUserID:nil];
}

+ (instancetype)configureWithAPIKey:(NSString *)APIKey appUserID:(NSString * _Nullable)appUserID
{
    RCPurchases *purchases = [[RCPurchases alloc] initWithAPIKey:APIKey appUserID:appUserID];
    [RCPurchases setDefaultInstance:purchases];
    return purchases;
}

- (instancetype)initWithAPIKey:(NSString *)APIKey appUserID:(NSString * _Nullable)appUserID
{
    return [self initWithAPIKey:APIKey appUserID:appUserID userDefaults:nil];
}

+ (instancetype)configureWithAPIKey:(NSString *)APIKey
                          appUserID:(NSString * _Nullable)appUserID
                       userDefaults:(NSUserDefaults * _Nullable)userDefaults
{
    RCPurchases *purchases = [[RCPurchases alloc] initWithAPIKey:APIKey appUserID:appUserID userDefaults:userDefaults];
    [RCPurchases setDefaultInstance:purchases];
    return purchases;
}

- (instancetype)initWithAPIKey:(NSString *)APIKey
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

- (instancetype)initWithAppUserID:(NSString *)appUserID
                   requestFetcher:(RCStoreKitRequestFetcher *)requestFetcher
                          backend:(RCBackend *)backend
                  storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
               notificationCenter:(NSNotificationCenter *)notificationCenter
                     userDefaults:(NSUserDefaults *)userDefaults
{
    if (self = [super init]) {
        self.requestFetcher = requestFetcher;
        self.backend = backend;
        self.storeKitWrapper = storeKitWrapper;

        self.notificationCenter = notificationCenter;
        self.userDefaults = userDefaults;

        self.productsByIdentifier = [NSMutableDictionary new];
        self.purchaseCompleteCallbacks = [NSMutableDictionary new];

        self.finishTransactions = YES;

        if (appUserID == nil) {
            appUserID = [userDefaults stringForKey:RCAppUserDefaultsKey];
            if (appUserID == nil) {
                appUserID = [self generateAndCacheID];
            }
            self.allowSharingAppStoreAccount = YES;
            self.appUserID = appUserID;
        } else {
            [self identify:appUserID completionBlock:nil];
        }
        
        self.storeKitWrapper.delegate = self;
        [self.notificationCenter addObserver:self
                                    selector:@selector(applicationDidBecomeActive:)
                                        name:APP_DID_BECOME_ACTIVE_NOTIFICATION_NAME object:nil];
        [self readPurchaserInfoFromCache];
        [self updateCaches];
    }

    return self;
}

- (void)dealloc
{
    self.storeKitWrapper.delegate = nil;
    [self.notificationCenter removeObserver:self
                                       name:APP_DID_BECOME_ACTIVE_NOTIFICATION_NAME
                                     object:nil];
    self.delegate = nil;
}

- (void)addAttributionData:(NSDictionary *)data
               fromNetwork:(RCAttributionNetwork)network
{
    if (data.count > 0) {
        [self.backend postAttributionData:data
                              fromNetwork:network
                             forAppUserID:self.appUserID];
    }
}

- (void)applicationDidBecomeActive:(__unused NSNotification *)notif
{
    [self updateCaches];
}

- (RCPurchaserInfo *)readPurchaserInfoFromCache {
    NSData *purchaserInfoData = [self.userDefaults dataForKey:self.purchaserInfoUserDefaultCacheKey];
    if (purchaserInfoData) {
        NSError *jsonError;
        NSDictionary *infoDict = [NSJSONSerialization JSONObjectWithData:purchaserInfoData options:0 error:&jsonError];
        if (jsonError == nil && infoDict != nil) {
            RCPurchaserInfo *info = [[RCPurchaserInfo alloc] initWithData:infoDict];
            return info;
        }
    }
    return nil;
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

    [self getEntitlements:nil];
}

- (void)purchaserInfoWithCompletionBlock:(RCReceivePurchaserInfoBlock)completion
{
    RCPurchaserInfo *info = [self readPurchaserInfoFromCache];
    if (info) {
        if (completion) {
            completion(info, nil);
        }
        return;
    } else {
        [self.backend getSubscriberDataWithAppUserID:self.appUserID
                                          completion:^(RCPurchaserInfo *info, NSError *error) {
                                              if (error) {
                                                  if (completion) {
                                                      completion(nil, error);
                                                  } else {
                                                      completion(info, nil);
                                                  }
                                              }
                                          }];
    }
    
    
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

- (void)entitlementsWithCompletionBlock:(RCReceiveEntitlementsBlock)completion
{
    if (self.cachedEntitlements) {
        completion(self.cachedEntitlements, nil);
    } else {
        [self getEntitlements:completion];
    }
}

- (void)getEntitlements:(RCReceiveEntitlementsBlock _Nullable)completion
{
    [self.backend getEntitlementsForAppUserID:self.appUserID
                                   completion:^(NSDictionary<NSString *,RCEntitlement *> *entitlements, NSError *error) {
                                       if (error != nil) {
                                           if (completion) {
                                               completion(nil, error);
                                           }
                                           return;
                                       }

                                       NSMutableSet *productIdentifiers = [NSMutableSet new];
                                       [self performOnEachOfferingInEntitlements:entitlements block:^(RCOffering *offering) {
                                           [productIdentifiers addObject:offering.activeProductIdentifier];
                                       }];

                                       [self productsWithIdentifiers:productIdentifiers.allObjects completionBlock:^(NSArray<SKProduct *> * _Nonnull products) {
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

                                           if (completion) {
                                               completion(entitlements, nil);
                                           }
                                       }];
    }];
}

- (void)productsWithIdentifiers:(NSArray<NSString *> *)productIdentifiers
                     completionBlock:(void (^)(NSArray<SKProduct *>* products))completion
{
    [self.requestFetcher fetchProducts:[NSSet setWithArray:productIdentifiers] completion:^(NSArray<SKProduct *> * _Nonnull products) {
        @synchronized(self) {
            for (SKProduct *product in products) {
                self.productsByIdentifier[product.productIdentifier] = product;
            }
        }
        completion(products);
    }];
}


- (void)checkTrialOrIntroductoryPriceEligibility:(NSArray<NSString *> *)productIdentifiers
                                      completionBlock:(RCReceiveIntroEligibilityBlock)receiveEligibility
{
    [self receiptData:^(NSData * _Nonnull data) {
        [self.backend getIntroEligibilityForAppUserID:self.appUserID
                                          receiptData:data
                                   productIdentifiers:productIdentifiers
                                           completion:receiveEligibility];
    }];
}

- (void)makePurchase:(SKProduct *)product withCompletionBlock:(RCPurchaseCompletedBlock)completion
{
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    payment.applicationUsername = self.appUserID;
    
    @synchronized (self) {
        if (self.purchaseCompleteCallbacks[product.productIdentifier]) {
            completion(nil, nil, [NSError errorWithDomain:RCPurchasesAPIErrorDomain
                                                     code:RCDuplicateMakePurchaseCallsError
                                                 userInfo:@{
                                                            NSLocalizedDescriptionKey: @"Purchase already in progress for this product."
                                                            }]);
        }
        self.purchaseCompleteCallbacks[product.productIdentifier] = [completion copy];
    }

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
    [self dispatch:^{
        RCPurchaseCompletedBlock completion = nil;
        @synchronized (self) {
             completion = self.purchaseCompleteCallbacks[transaction.payment.productIdentifier];
        }
        
        if (info) {
            [self cachePurchaserInfo:info];
            if (completion) {
                completion(transaction, info, nil);
            }
            // TODO call delegate
            if (self.finishTransactions) {
                [self.storeKitWrapper finishTransaction:transaction];
            }
        } else if (error.code == RCFinishableError) {
            if (completion) {
                completion(transaction, nil, error);
            }
            if (self.finishTransactions) {
                [self.storeKitWrapper finishTransaction:transaction];
            }
        } else if (error.code == RCUnfinishableError) {
            if (completion) {
                completion(transaction, nil, error);
            }
        } else {
            RCLog(@"Unexpected error from backend");
            if (completion) {
                completion(transaction, nil, error);
            }
        }
        
        @synchronized (self) {
            self.purchaseCompleteCallbacks[transaction.payment.productIdentifier] = nil;
        }
    }];
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
            [self dispatch:^{
//                [self.delegate purchases:self failedTransaction:transaction withReason:transaction.error];
            }];
            if (self.finishTransactions) {
                [self.storeKitWrapper finishTransaction:transaction];
            }
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

    if ([self.delegate respondsToSelector:@selector(purchases:shouldPurchasePromoProduct:defermentBlock:)]) {
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

- (void)dispatch:(void (^ _Nonnull)(void))block
{
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}


- (void)handleUpdatedPurchaserInfo:(RCPurchaserInfo * _Nullable)info error:(NSError * _Nullable)error
{
    [self dispatch:^{
        if (info) {
            [self cachePurchaserInfo:info];
        }
    }];
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
                            isRestore:self.allowSharingAppStoreAccount
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

- (void)restoreTransactionsWithCompletionBlock:(RCReceivePurchaserInfoBlock)completion
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
                               [self dispatch:^{
                                   if (error) {
                                       if (completion) {
                                           completion(nil, error);
                                       }
                                   } else if (info) {
                                       [self cachePurchaserInfo:info];
                                       if (completion) {
                                           completion(info, nil);
                                       }
                                   }
                               }];
                           }];
    }];
}

- (void)updateOriginalApplicationVersionWithCompletionBlock:(RCReceivePurchaserInfoBlock _Nullable)completion
{
    [self.backend getSubscriberDataWithAppUserID:self.appUserID completion:^(RCPurchaserInfo * _Nullable info,
                                                                             NSError * _Nullable error) {
        if (error) {
            [self dispatch:^{
                completion(nil, error);
            }];
        } else if (info.originalApplicationVersion) {
            [self dispatch:^{
                completion(info, nil);
            }];
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
                                       if (completion) {
                                           completion(info, error);
                                       }
                                   }];
            }];
        }
    }];
}

- (void)createAlias:(NSString *)alias
{
    [self createAlias:alias completionBlock:^(RCPurchaserInfo *info, NSError *e) {}];
}

- (void)createAlias:(NSString *)alias completionBlock:(RCReceivePurchaserInfoBlock)completion
{
    [self.backend createAliasForAppUserID:self.appUserID withNewAppUserID:alias completion:^(NSError * _Nullable error) {
        if (error == nil) {
            [self identify:alias completionBlock:nil];
        }
        if (completion != nil) {
            [self dispatch:^{
                completion(nil, error);
            }];
        }
    }];
}

- (void)identify:(NSString *)appUserID completionBlock:(RCReceivePurchaserInfoBlock)completion
{
    [self.userDefaults removeObjectForKey:RCAppUserDefaultsKey];
    self.appUserID = appUserID;
    self.cachesLastUpdated = nil;
    if (self.delegate != nil) {
        [self updateCaches];
    }
}

- (void)reset
{
    self.appUserID = [self generateAndCacheID];
    self.allowSharingAppStoreAccount = YES;
    self.cachesLastUpdated = nil;
    if (self.delegate != nil) {
        [self updateCaches];
    }
}

- (NSString *)generateAndCacheID
{
    NSString *generatedUserID = NSUUID.new.UUIDString;
    [self.userDefaults setObject:generatedUserID forKey:RCAppUserDefaultsKey];
    return generatedUserID;
}

@end
