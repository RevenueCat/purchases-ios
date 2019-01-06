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

#define CALL_AND_DISPATCH_IF_SET(completion, ...) if (completion) [self dispatch:^{ completion(__VA_ARGS__); }];
#define CALL_IF_SET(completion, ...) if (completion) completion(__VA_ARGS__);

NSErrorDomain const RCPurchasesAPIErrorDomain = @"RCPurchasesAPIErrorDomain";

@interface RCPurchases () <RCStoreKitWrapperDelegate>

@property (nonatomic) NSString *appUserID;

@property (nonatomic) RCStoreKitRequestFetcher *requestFetcher;
@property (nonatomic) RCBackend *backend;
@property (nonatomic) RCStoreKitWrapper *storeKitWrapper;
@property (nonatomic) NSNotificationCenter *notificationCenter;
@property (nonatomic) NSUserDefaults *userDefaults;

@property (nonatomic) NSDate *cachesLastUpdated;
@property (nonatomic) RCEntitlements *cachedEntitlements;
@property (nonatomic) NSMutableDictionary<NSString *, SKProduct *> *productsByIdentifier;
@property (nonatomic) NSMutableDictionary<NSString *, RCPurchaseCompletedBlock> *purchaseCompleteCallbacks;
@property (nonatomic) RCPurchaserInfo *lastSentPurchaserInfo;

@end

NSString * RCAppUserDefaultsKey = @"com.revenuecat.userdefaults.appUserID";
NSString * RCPurchaserInfoAppUserDefaultsKeyBase = @"com.revenuecat.userdefaults.purchaserInfo.";

@implementation RCPurchases

static RCPurchases *_sharedPurchases = nil;
@synthesize delegate=_delegate;

+ (void)setDebugLogsEnabled:(BOOL)enabled
{
    RCSetShowDebugLogs(enabled);
}

+ (BOOL)debugLogsEnabled
{
    return RCShowDebugLogs();
}

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
        RCDebugLog(@"Debug logging enabled.");
        RCDebugLog(@"SDK Version - %@", self.class.frameworkVersion);
        RCDebugLog(@"Initial App User ID - %@", appUserID);
        
        self.requestFetcher = requestFetcher;
        self.backend = backend;
        self.storeKitWrapper = storeKitWrapper;

        self.notificationCenter = notificationCenter;
        self.userDefaults = userDefaults;

        self.productsByIdentifier = [NSMutableDictionary new];
        self.purchaseCompleteCallbacks = [NSMutableDictionary new];

        self.finishTransactions = YES;
        
        RCReceivePurchaserInfoBlock callDelegate = ^void(RCPurchaserInfo *info, NSError *error) {
            if (info) {
                [self sendUpdatedPurchaserInfoToDelegateIfChanged:info];
            }
        };

        if (appUserID == nil) {
            appUserID = [userDefaults stringForKey:RCAppUserDefaultsKey];
            if (appUserID == nil) {
                appUserID = [self generateAndCacheID];
                RCDebugLog(@"Generated New App User ID - %@", appUserID);
            }
            
            self.allowSharingAppStoreAccount = YES;
            self.appUserID = appUserID;
            [self updateCachesWithCompletionBlock:callDelegate];
        } else {
            // this will call updateCaches
            [self identify:appUserID completionBlock:callDelegate];
        }
        
        self.storeKitWrapper.delegate = self;
        [self.notificationCenter addObserver:self
                                    selector:@selector(applicationDidBecomeActive:)
                                        name:APP_DID_BECOME_ACTIVE_NOTIFICATION_NAME object:nil];
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
    RCDebugLog(@"applicationDidBecomeActive");
    if ([self isCacheStale]) {
        RCDebugLog(@"Cache is stale, updating caches");
        [self updateCachesWithCompletionBlock:^(RCPurchaserInfo *info, NSError *error) {
            if (info) {
                [self sendUpdatedPurchaserInfoToDelegateIfChanged:info];
            }
        }];
    }
}

- (RCPurchaserInfo *)readPurchaserInfoFromCache {
    NSData *purchaserInfoData = [self.userDefaults dataForKey:[self purchaserInfoUserDefaultCacheKeyForAppUserID:self.appUserID]];
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

- (void)cachePurchaserInfo:(RCPurchaserInfo *)info forAppUserID:(NSString *)appUserID {
    if (info) {
        [self dispatch:^{
            if (info.JSONObject) {
                NSError *jsonError = nil;
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:info.JSONObject
                                                                   options:0
                                                                     error:&jsonError];
                if (jsonError == nil) {
                    [self.userDefaults setObject:jsonData
                                          forKey:[self purchaserInfoUserDefaultCacheKeyForAppUserID:appUserID]];
                }
            }
        }];
    }
}

- (BOOL)isCacheStale {
    NSTimeInterval timeSinceLastCheck = -[self.cachesLastUpdated timeIntervalSinceNow];
    return !(self.cachesLastUpdated != nil && timeSinceLastCheck < 60. * 5);
}

- (void)updateCaches {
    [self updateCachesWithCompletionBlock:nil];
}

- (void)updateCachesWithCompletionBlock:(RCReceivePurchaserInfoBlock _Nullable)completion
{
    self.cachesLastUpdated = [NSDate date];
    [self updatePurchaserInfoCache:completion];
    [self updateEntitlementsCache:nil];
}

- (void)updatePurchaserInfoCache:(RCReceivePurchaserInfoBlock _Nullable)completion
{
    NSString *appUserID = self.appUserID;
    [self.backend getSubscriberDataWithAppUserID:self.appUserID
                                      completion:^(RCPurchaserInfo * _Nullable info,
                                                   NSError * _Nullable error) {
                                          if (error == nil) {
                                              [self cachePurchaserInfo:info forAppUserID:appUserID];
                                          } else {
                                              self.cachesLastUpdated = nil;
                                          }
                                          CALL_AND_DISPATCH_IF_SET(completion, info, error);
                                      }];
}

- (void)purchaserInfoWithCompletionBlock:(RCReceivePurchaserInfoBlock)completion
{
    RCPurchaserInfo *infoFromCache = [self readPurchaserInfoFromCache];
    if (infoFromCache) {
        RCDebugLog(@"Vending purchaserInfo from cache");
        CALL_IF_SET(completion, infoFromCache, nil);
        if ([self isCacheStale]) {
            RCDebugLog(@"Cache is stale, updating caches");
            [self updateCaches];
        }
    } else {
        RCDebugLog(@"No cached purchaser info, fetching");
        [self updateCachesWithCompletionBlock:completion];
    }
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
        RCDebugLog(@"Vending entitlements from cache");
        CALL_IF_SET(completion, self.cachedEntitlements, nil);
        if ([self isCacheStale]) {
            RCDebugLog(@"Cache is stale, updating caches");
            [self updateCaches];
        }
    } else {
        RCDebugLog(@"No cached entitlements, fetching");
        [self updateEntitlementsCache:completion];
    }
}

- (void)updateEntitlementsCache:(RCReceiveEntitlementsBlock _Nullable)completion
{
    [self.backend getEntitlementsForAppUserID:self.appUserID
                                   completion:^(NSDictionary<NSString *,RCEntitlement *> *entitlements, NSError *error) {
                                       if (error != nil) {
                                           RCLog(@"Error fetching entitlements - %@", error);
                                           CALL_AND_DISPATCH_IF_SET(completion, nil, error);
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
                                           
                                           NSMutableArray *missingProducts = [NSMutableArray new];

                                           [self performOnEachOfferingInEntitlements:entitlements block:^(RCOffering *offering) {
                                               SKProduct *product = productsById[offering.activeProductIdentifier];
                                               
                                               
                                               if (product == nil) {
                                                   [missingProducts addObject:offering.activeProductIdentifier];
                                               }
                                               
                                               offering.activeProduct = product;
                                           }];
                                           
                                           if (missingProducts.count > 0) {
                                               RCLog(@"Could not find SKProduct for %@", missingProducts);
                                               RCLog(@"Ensure your products are correctly configured in App Store Connect");
                                               RCLog(@"See https://www.revenuecat.com/2018/10/11/configuring-in-app-products-is-hard");
                                           }

                                           if (entitlements != nil) {
                                               self.cachedEntitlements = entitlements;
                                           }
                                           
                                           CALL_AND_DISPATCH_IF_SET(completion, entitlements, nil);
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
        CALL_AND_DISPATCH_IF_SET(completion, products);
    }];
}


- (void)checkTrialOrIntroductoryPriceEligibility:(NSArray<NSString *> *)productIdentifiers
                                      completionBlock:(RCReceiveIntroEligibilityBlock)receiveEligibility
{
    [self receiptData:^(NSData * _Nonnull data) {
        [self.backend getIntroEligibilityForAppUserID:self.appUserID
                                          receiptData:data
                                   productIdentifiers:productIdentifiers
                                           completion:^(NSDictionary<NSString *,RCIntroEligibility *> * _Nonnull result) {
                                               CALL_AND_DISPATCH_IF_SET(receiveEligibility, result);
                                           }];
    }];
}

- (void)makePurchase:(SKProduct *)product withCompletionBlock:(RCPurchaseCompletedBlock)completion
{
    // This is to prevent the UIApplicationDidBecomeActive call from the purchase popup
    // from triggering a refresh.
    self.cachesLastUpdated = [NSDate date];
    
    RCDebugLog(@"makePurchase - %@", product.productIdentifier);
    
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    payment.applicationUsername = self.appUserID;
    
    @synchronized (self) {
        if (self.purchaseCompleteCallbacks[product.productIdentifier]) {
            completion(nil, nil, [NSError errorWithDomain:RCPurchasesAPIErrorDomain
                                                     code:RCDuplicateMakePurchaseCallsError
                                                 userInfo:@{
                                                            NSLocalizedDescriptionKey: @"Purchase already in progress for this product."
                                                            }]);
            return;
        }
        self.purchaseCompleteCallbacks[product.productIdentifier] = [completion copy];
    }

    [self.storeKitWrapper addPayment:payment];
}

- (void)receiptData:(void (^ _Nonnull)(NSData * _Nonnull data))completion
{
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    RCDebugLog(@"Loaded receipt from %@", receiptURL);
    if (receiptData == nil) {
        RCDebugLog(@"Receipt empty, fetching");
        [self.requestFetcher fetchReceiptData:^{
            NSData *newReceiptData = [NSData dataWithContentsOfURL:receiptURL];
            if (newReceiptData == nil) {
                RCLog(@"Unable to load receipt, ensure you are logged in to a Sandbox account");
            }
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
            [self cachePurchaserInfo:info forAppUserID:self.appUserID];
            
            CALL_IF_SET(completion, transaction, info, nil);
            
            if (!completion) {
                [self sendUpdatedPurchaserInfoToDelegateIfChanged:info];
            }
            
            if (self.finishTransactions) {
                [self.storeKitWrapper finishTransaction:transaction];
            }
        } else if (error.code == RCFinishableError) {
            CALL_IF_SET(completion, transaction, nil, error);
            if (self.finishTransactions) {
                [self.storeKitWrapper finishTransaction:transaction];
            }
        } else if (error.code == RCUnfinishableError) {
            CALL_IF_SET(completion, transaction, nil, error);
        } else {
            RCLog(@"Unexpected error from backend");
            CALL_IF_SET(completion, transaction, nil, error);
        }
        
        @synchronized (self) {
            self.purchaseCompleteCallbacks[transaction.payment.productIdentifier] = nil;
        }
    }];
}

- (void)sendUpdatedPurchaserInfoToDelegateIfChanged:(RCPurchaserInfo *)info {
    if (![self.lastSentPurchaserInfo isEqual:info]) {
        [self.delegate purchases:self didReceivePurchaserInfo:info];
        self.lastSentPurchaserInfo = info;
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
            RCPurchaseCompletedBlock completion = nil;
            @synchronized (self) {
                completion = self.purchaseCompleteCallbacks[transaction.payment.productIdentifier];
            }
            
            CALL_AND_DISPATCH_IF_SET(completion, transaction, nil, transaction.error);
            
            if (self.finishTransactions) {
                [self.storeKitWrapper finishTransaction:transaction];
            }
            
            @synchronized (self) {
                self.purchaseCompleteCallbacks[transaction.payment.productIdentifier] = nil;
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
{}

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

- (NSString *)purchaserInfoUserDefaultCacheKeyForAppUserID:(NSString *)appUserID {
    return [RCPurchaserInfoAppUserDefaultsKeyBase stringByAppendingString:appUserID];
}

- (void)dispatch:(void (^ _Nonnull)(void))block
{
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
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
                                       CALL_AND_DISPATCH_IF_SET(completion, nil, error);
                                   } else if (info) {
                                       [self cachePurchaserInfo:info forAppUserID:self.appUserID];
                                       CALL_AND_DISPATCH_IF_SET(completion, info, nil);
                                   }
                               }];
                           }];
    }];
}

- (void)clearCaches {
    if (self.appUserID) {
        [self.userDefaults removeObjectForKey:[self purchaserInfoUserDefaultCacheKeyForAppUserID:self.appUserID]];
    }
    self.cachesLastUpdated = nil;
    self.cachedEntitlements = nil;
}

- (void)createAlias:(NSString *)alias
{
    [self createAlias:alias completionBlock:nil];
}

- (void)createAlias:(NSString *)alias completionBlock:(RCReceivePurchaserInfoBlock _Nullable)completion
{
    [self.backend createAliasForAppUserID:self.appUserID withNewAppUserID:alias completion:^(NSError * _Nullable error) {
        if (error == nil) {
            [self identify:alias completionBlock:completion];
        } else {
            CALL_AND_DISPATCH_IF_SET(completion, nil, error);
        }
    }];
}

- (void)identify:(NSString *)appUserID completionBlock:(RCReceivePurchaserInfoBlock)completion
{
    [self clearCaches];
    self.appUserID = appUserID;
    [self updateCachesWithCompletionBlock:completion];
}

- (void)reset
{
    [self clearCaches];
    self.appUserID = [self generateAndCacheID];
    [self updateCaches];
}

- (NSString *)generateAndCacheID
{
    NSString *generatedUserID = NSUUID.new.UUIDString;
    [self.userDefaults setObject:generatedUserID forKey:RCAppUserDefaultsKey];
    return generatedUserID;
}

@end
