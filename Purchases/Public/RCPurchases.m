//
//  RCPurchases.m
//  Purchases
//
//  Created by Jacob Eiting on 9/29/17.
//  Copyright © 2019 RevenueCat, Inc. All rights reserved.
//

#import "RCPurchases.h"
#import "RCPurchases+Protected.h"

#import "RCStoreKitRequestFetcher.h"
#import "RCBackend.h"
#import "RCStoreKitWrapper.h"
#import "RCPurchaserInfo+Protected.h"
#import "RCUtils.h"
#import "NSLocale+RCExtensions.h"
#import "RCCrossPlatformSupport.h"
#import "RCOffering+Protected.h"
#import "RCPurchasesErrors.h"
#import "RCPurchasesErrorUtils.h"
#import "RCReceiptFetcher.h"

#define CALL_AND_DISPATCH_IF_SET(completion, ...) if (completion) [self dispatch:^{ completion(__VA_ARGS__); }];
#define CALL_IF_SET(completion, ...) if (completion) completion(__VA_ARGS__);

@interface RCPurchases () <RCStoreKitWrapperDelegate>

@property (nonatomic) NSString *appUserID;

@property (nonatomic) RCStoreKitRequestFetcher *requestFetcher;
@property (nonatomic) RCReceiptFetcher *receiptFetcher;
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

#pragma mark - Configuration
static RCPurchases *_sharedPurchases = nil;

+ (void)setDebugLogsEnabled:(BOOL)enabled
{
    RCSetShowDebugLogs(enabled);
}

+ (BOOL)debugLogsEnabled
{
    return RCShowDebugLogs();
}

+ (NSString *)frameworkVersion {
    return @"2.1.0-SNAPSHOT";
}

+ (instancetype)sharedPurchases {
    if (!_sharedPurchases) {
        RCLog(@"There is no singleton instance. Make sure you configure Purchases before trying to get the default instance.");
    }
    return _sharedPurchases;
}

+ (void)setDefaultInstance:(RCPurchases *)instance {
    @synchronized([RCPurchases class]) {
        if (_sharedPurchases) {
            RCLog(@"Purchases instance already set. Did you mean to configure two Purchases objects?");
        }
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
    RCReceiptFetcher *receiptFetcher = [[RCReceiptFetcher alloc] init];
    RCBackend *backend = [[RCBackend alloc] initWithAPIKey:APIKey];
    RCStoreKitWrapper *storeKitWrapper = [[RCStoreKitWrapper alloc] init];

    if (userDefaults == nil) {
        userDefaults = [NSUserDefaults standardUserDefaults];
    }

    return [self initWithAppUserID:appUserID
                    requestFetcher:fetcher
                    receiptFetcher:receiptFetcher
                           backend:backend
                   storeKitWrapper:storeKitWrapper
                notificationCenter:[NSNotificationCenter defaultCenter]
                      userDefaults:userDefaults];
}

- (instancetype)initWithAppUserID:(NSString *)appUserID
                   requestFetcher:(RCStoreKitRequestFetcher *)requestFetcher
                   receiptFetcher:(RCReceiptFetcher *)receiptFetcher
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
        self.receiptFetcher = receiptFetcher;
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

@synthesize delegate=_delegate;

- (void)setDelegate:(id<RCPurchasesDelegate>)delegate
{
    _delegate = delegate;
    RCDebugLog(@"Delegate set");
    
    RCPurchaserInfo *infoFromCache = [self readPurchaserInfoFromCache];
    if (infoFromCache) {
        [self sendUpdatedPurchaserInfoToDelegateIfChanged:infoFromCache];
    }
}

#pragma mark - Public Methods

#pragma mark Attribution
- (void)addAttributionData:(NSDictionary *)data
               fromNetwork:(RCAttributionNetwork)network
{
    if (data.count > 0) {
        [self.backend postAttributionData:data
                              fromNetwork:network
                             forAppUserID:self.appUserID];
    }
}

#pragma mark Identity

- (void)createAlias:(NSString *)alias completionBlock:(RCReceivePurchaserInfoBlock _Nullable)completion
{
    if ([alias isEqualToString:self.appUserID]) {
        [self purchaserInfoWithCompletionBlock:completion];
    } else {
        RCDebugLog(@"Creating an alias to %@ from %@", self.appUserID, alias);
        [self.backend createAliasForAppUserID:self.appUserID withNewAppUserID:alias completion:^(NSError * _Nullable error) {
            if (error == nil) {
                RCDebugLog(@"Alias created");
                [self identify:alias completionBlock:completion];
            } else {
                CALL_AND_DISPATCH_IF_SET(completion, nil, error);
            }
        }];
    }
}

- (void)identify:(NSString *)appUserID completionBlock:(RCReceivePurchaserInfoBlock)completion
{
    if ([appUserID isEqualToString:self.appUserID]) {
        [self purchaserInfoWithCompletionBlock:completion];
    } else {
        RCDebugLog(@"Changing App User ID: %@ -> %@", self.appUserID, appUserID);
        [self clearCaches];
        self.appUserID = appUserID;
        [self updateCachesWithCompletionBlock:completion];
    }
}

- (void)resetWithCompletionBlock:(RCReceivePurchaserInfoBlock)completion
{
    [self clearCaches];
    self.appUserID = [self generateAndCacheID];
    [self updateCachesWithCompletionBlock:completion];
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

#pragma mark Purchasing

- (void)productsWithIdentifiers:(NSArray<NSString *> *)productIdentifiers
                completionBlock:(RCReceiveProductsBlock)completion
{
    NSMutableArray<SKProduct *> *products = [NSMutableArray array];
    NSMutableSet<NSString *> *missingProductIdentifiers = [NSMutableSet set];
    
    @synchronized(self) {
        for (NSString *identifier in productIdentifiers) {
            SKProduct *product = self.productsByIdentifier[identifier];
            if (product) {
                [products addObject:product];
            } else {
                [missingProductIdentifiers addObject:identifier];
            }
        }
    }
    
    if (missingProductIdentifiers.count > 0) {
        [self.requestFetcher fetchProducts:missingProductIdentifiers
                                completion:^(NSArray<SKProduct *> * _Nonnull newProducts) {
                                    @synchronized (self) {
                                        for (SKProduct *p in newProducts)
                                        {
                                            self.productsByIdentifier[p.productIdentifier] = p;
                                        }
                                    }
                                    CALL_AND_DISPATCH_IF_SET(completion, [products arrayByAddingObjectsFromArray:newProducts]);
                                }];
    } else {
        CALL_AND_DISPATCH_IF_SET(completion, products);
    }
}

- (void)makePurchase:(SKProduct *)product withCompletionBlock:(RCPurchaseCompletedBlock)completion
{
    // This is to prevent the UIApplicationDidBecomeActive call from the purchase popup
    // from triggering a refresh.
    self.cachesLastUpdated = [NSDate date];
    
    RCDebugLog(@"makePurchase - %@", product.productIdentifier);
    
    @synchronized (self) {
        self.productsByIdentifier[product.productIdentifier] = product;
    }
    
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    payment.applicationUsername = self.appUserID;
    
    @synchronized (self) {
        if (self.purchaseCompleteCallbacks[product.productIdentifier]) {
            completion(nil, nil, [NSError errorWithDomain:RCPurchasesErrorDomain
                                                     code:RCOperationAlreadyInProgressError
                                                 userInfo:@{
                                                            NSLocalizedDescriptionKey: @"Purchase already in progress for this product."
                                                            }], false);
            return;
        }
        self.purchaseCompleteCallbacks[product.productIdentifier] = [completion copy];
    }
    
    [self.storeKitWrapper addPayment:payment];
}

- (void)restoreTransactionsWithCompletionBlock:(RCReceivePurchaserInfoBlock)completion
{
    // Refresh the receipt and post to backend, this will allow the transactions to be transferred.
    // https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/Restoring.html
    [self receiptData:^(NSData * _Nonnull data) {
        if (data.length == 0) {
            if (RCIsSandbox()) {
                RCLog(@"App running on sandbox without a receipt file. Restoring transactions won't work unless you've purchased before and there is a receipt available.");
            }
            CALL_AND_DISPATCH_IF_SET(completion, nil, [RCPurchasesErrorUtils missingReceiptFileError]);
            return;
        }
        [self.backend postReceiptData:data
                            appUserID:self.appUserID
                            isRestore:YES
                    productIdentifier:nil
                                price:nil
                          paymentMode:RCPaymentModeNone
                    introductoryPrice:nil
                         currencyCode:nil
                    subscriptionGroup:nil
                           completion:^(RCPurchaserInfo * _Nullable info,
                                        NSError * _Nullable error) {
                               [self dispatch:^{
                                   if (error) {
                                       CALL_AND_DISPATCH_IF_SET(completion, nil, error);
                                   } else if (info) {
                                       [self cachePurchaserInfo:info forAppUserID:self.appUserID];
                                       [self sendUpdatedPurchaserInfoToDelegateIfChanged:info];
                                       CALL_AND_DISPATCH_IF_SET(completion, info, nil);
                                   }
                               }];
                           }];
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

#pragma mark - Private Methods

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
                                              [self sendUpdatedPurchaserInfoToDelegateIfChanged:info];
                                          } else {
                                              self.cachesLastUpdated = nil;
                                          }
                                          
                                          CALL_AND_DISPATCH_IF_SET(completion, info, error);
                                      }];
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

- (void)receiptData:(void (^ _Nonnull)(NSData * _Nonnull data))completion
{
    NSData *receiptData = [self.receiptFetcher receiptData];
    if (receiptData == nil) {
        RCDebugLog(@"Receipt empty, fetching");
        [self.requestFetcher fetchReceiptData:^{
            NSData *newReceiptData = [self.receiptFetcher receiptData];
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
            
            [self sendUpdatedPurchaserInfoToDelegateIfChanged:info];
            
            CALL_IF_SET(completion, transaction, info, nil, false);
            
            if (self.finishTransactions) {
                [self.storeKitWrapper finishTransaction:transaction];
            }
        } else if ([error.userInfo[RCFinishableKey] boolValue]) {
            CALL_IF_SET(completion, transaction, nil, error, false);
            if (self.finishTransactions) {
                [self.storeKitWrapper finishTransaction:transaction];
            }
        } else if (![error.userInfo[RCFinishableKey] boolValue]) {
            CALL_IF_SET(completion, transaction, nil, error, false);
        } else {
            RCLog(@"Unexpected error from backend");
            CALL_IF_SET(completion, transaction, nil, error, false);
        }
        
        @synchronized (self) {
            self.purchaseCompleteCallbacks[transaction.payment.productIdentifier] = nil;
        }
    }];
}

- (void)sendUpdatedPurchaserInfoToDelegateIfChanged:(RCPurchaserInfo *)info {
    
    if ([self.delegate respondsToSelector:@selector(purchases:didReceiveUpdatedPurchaserInfo:)]) {
        @synchronized (self) {
            if (![self.lastSentPurchaserInfo isEqual:info]) {
                if (self.lastSentPurchaserInfo) {
                    RCDebugLog(@"Purchaser info updated, sending to delegate");
                } else {
                    RCDebugLog(@"Sending latest purchaser info to delegate");
                }
                self.lastSentPurchaserInfo = info;
                [self dispatch:^{
                    [self.delegate purchases:self didReceiveUpdatedPurchaserInfo:info];
                }];
            }
        }
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

            CALL_AND_DISPATCH_IF_SET(
                    completion,
                    transaction,
                    nil,
                    [RCPurchasesErrorUtils purchasesErrorWithSKError:transaction.error],
                    transaction.error.code == SKErrorPaymentCancelled);
            
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
        if (data.length == 0) {
            [self handleReceiptPostWithTransaction:transaction
                                     purchaserInfo:nil
                                             error:[RCPurchasesErrorUtils missingReceiptFileError]];
        } else {
            [self productsWithIdentifiers:@[transaction.payment.productIdentifier]
                          completionBlock:^(NSArray<SKProduct *> *products) {
                              SKProduct *product = products.lastObject;

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

                              NSString *subscriptionGroup = nil;
                              if (@available(iOS 12.0, macOS 10.14.0, *)) {
                                  subscriptionGroup = product.subscriptionGroupIdentifier;
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
                                          subscriptionGroup:subscriptionGroup
                                                 completion:^(RCPurchaserInfo *_Nullable info,
                                                             NSError * _Nullable error) {
                                                     [self handleReceiptPostWithTransaction:transaction
                                                                              purchaserInfo:info
                                                                                      error:error];
                                                 }];
                          }];
        }
    }];
}

- (void)clearCaches {
    if (self.appUserID) {
        [self.userDefaults removeObjectForKey:[self purchaserInfoUserDefaultCacheKeyForAppUserID:self.appUserID]];
    }
    self.cachesLastUpdated = nil;
    self.cachedEntitlements = nil;
}

- (NSString *)generateAndCacheID
{
    NSString *generatedUserID = NSUUID.new.UUIDString;
    [self.userDefaults setObject:generatedUserID forKey:RCAppUserDefaultsKey];
    return generatedUserID;
}

@end
