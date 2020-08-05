//
//  RCPurchases.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCPurchases.h"
#import "RCPurchases+SubscriberAttributes.h"
#import "RCPurchases+Protected.h"

#import "RCStoreKitRequestFetcher.h"
#import "RCBackend.h"
#import "RCStoreKitWrapper.h"
#import "RCPurchaserInfo+Protected.h"
#import "RCLogUtils.h"
#import "NSLocale+RCExtensions.h"
#import "RCCrossPlatformSupport.h"
#import "RCPurchasesErrors.h"
#import "RCPurchasesErrorUtils.h"
#import "RCReceiptFetcher.h"
#import "RCAttributionFetcher.h"
#import "RCAttributionData.h"
#import "RCPromotionalOffer.h"
#import "RCOfferingsFactory.h"
#import "RCPackage+Protected.h"
#import "RCDeviceCache.h"
#import "RCIdentityManager.h"
#import "RCSubscriberAttributesManager.h"
#import "RCSystemInfo.h"
#import "RCISOPeriodFormatter.h"
#import "RCProductInfo.h"
#import "RCProductInfoExtractor.h"
#import "RCIntroEligibility+Protected.h"
#import "RCPurchasesSwiftImport.h"
#import "RCLocalReceiptParser.h"
#import "RCOperationDispatcher.h"

@interface RCPurchases () <RCStoreKitWrapperDelegate> {
    NSNumber * _Nullable _allowSharingAppStoreAccount;
}

/**
 * Completion block for calls that send back receipt data
 */
typedef void (^RCReceiveReceiptDataBlock)(NSData *);

@property (nonatomic) RCStoreKitRequestFetcher *requestFetcher;
@property (nonatomic) RCReceiptFetcher *receiptFetcher;
@property (nonatomic) RCBackend *backend;
@property (nonatomic) RCStoreKitWrapper *storeKitWrapper;
@property (nonatomic) NSNotificationCenter *notificationCenter;
@property (nonatomic) NSUserDefaults *userDefaults;

@property (nonatomic) NSMutableDictionary<NSString *, SKProduct *> *productsByIdentifier;
@property (nonatomic) NSMutableDictionary<NSString *, NSString *> *presentedOfferingsByProductIdentifier;
@property (nonatomic) NSMutableDictionary<NSString *, RCPurchaseCompletedBlock> *purchaseCompleteCallbacks;
@property (nonatomic) RCPurchaserInfo *lastSentPurchaserInfo;
@property (nonatomic) RCAttributionFetcher *attributionFetcher;
@property (nonatomic) RCOfferingsFactory *offeringsFactory;
@property (nonatomic) RCDeviceCache *deviceCache;
@property (nonatomic) RCIdentityManager *identityManager;
@property (nonatomic) RCSystemInfo *systemInfo;
@property (nonatomic) RCOperationDispatcher *operationDispatcher;

@end

static NSString * const RCAttributionDataDefaultsKeyBase = @"com.revenuecat.userdefaults.attribution.";
static NSMutableArray<RCAttributionData *> * _Nullable postponedAttributionData;
static RCPurchases *_sharedPurchases = nil;

@implementation RCPurchases

#pragma mark - Configuration

- (BOOL)allowSharingAppStoreAccount {
    if (_allowSharingAppStoreAccount == nil) {
        return self.isAnonymous;
    }

    return [_allowSharingAppStoreAccount boolValue];
}

- (void)setAllowSharingAppStoreAccount:(BOOL)allow {
    _allowSharingAppStoreAccount = @(allow);
}

static BOOL _automaticAppleSearchAdsAttributionCollection = NO;

+ (void)setAutomaticAppleSearchAdsAttributionCollection:(BOOL)automaticAppleSearchAdsAttributionCollection {
    _automaticAppleSearchAdsAttributionCollection = automaticAppleSearchAdsAttributionCollection;
}

+ (BOOL)automaticAppleSearchAdsAttributionCollection {
    return _automaticAppleSearchAdsAttributionCollection;
}

+ (void)setDebugLogsEnabled:(BOOL)enabled {
    RCSetShowDebugLogs(enabled);
}

+ (BOOL)debugLogsEnabled {
    return RCShowDebugLogs();
}

+ (NSURL *)proxyURL {
    return RCSystemInfo.proxyURL;
}

+ (void)setProxyURL:(nullable NSURL *)proxyURL {
    RCSystemInfo.proxyURL = proxyURL;
}

+ (NSString *)frameworkVersion {
    return RCSystemInfo.frameworkVersion;
}

- (BOOL)finishTransactions {
    return self.systemInfo.finishTransactions;
}

- (void)setFinishTransactions:(BOOL)finishTransactions {
    self.systemInfo.finishTransactions = finishTransactions;
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

+ (BOOL)canMakePayments {
    return [SKPaymentQueue canMakePayments];
}

+ (instancetype)configureWithAPIKey:(NSString *)APIKey {
    return [self configureWithAPIKey:APIKey appUserID:nil];
}

+ (instancetype)configureWithAPIKey:(NSString *)APIKey appUserID:(nullable NSString *)appUserID {
    return [self configureWithAPIKey:APIKey appUserID:appUserID observerMode:false];
}

+ (instancetype)configureWithAPIKey:(NSString *)APIKey
                          appUserID:(nullable NSString *)appUserID
                       observerMode:(BOOL)observerMode {
    return [self configureWithAPIKey:APIKey appUserID:appUserID observerMode:observerMode userDefaults:nil];
}

+ (instancetype)configureWithAPIKey:(NSString *)APIKey
                          appUserID:(nullable NSString *)appUserID
                       observerMode:(BOOL)observerMode
                       userDefaults:(nullable NSUserDefaults *)userDefaults {
    return [self configureWithAPIKey:APIKey
                           appUserID:appUserID
                        observerMode:observerMode
                        userDefaults:userDefaults
                      platformFlavor:nil
               platformFlavorVersion:nil];
}

+ (instancetype)configureWithAPIKey:(NSString *)APIKey
                          appUserID:(nullable NSString *)appUserID
                       observerMode:(BOOL)observerMode
                       userDefaults:(nullable NSUserDefaults *)userDefaults
                     platformFlavor:(NSString *)platformFlavor
              platformFlavorVersion:(NSString *)platformFlavorVersion {
    RCPurchases *purchases = [[self alloc] initWithAPIKey:APIKey
                                                appUserID:appUserID
                                             userDefaults:userDefaults
                                             observerMode:observerMode
                                           platformFlavor:platformFlavor
                                    platformFlavorVersion:platformFlavorVersion];
    [self setDefaultInstance:purchases];
    return purchases;
}

- (instancetype)initWithAPIKey:(NSString *)APIKey appUserID:(nullable NSString *)appUserID {
    return [self initWithAPIKey:APIKey
                      appUserID:appUserID
                   userDefaults:nil
                   observerMode:false
                 platformFlavor:nil
          platformFlavorVersion:nil];
}

- (instancetype)initWithAPIKey:(NSString *)APIKey
                     appUserID:(nullable NSString *)appUserID
                  userDefaults:(nullable NSUserDefaults *)userDefaults
                  observerMode:(BOOL)observerMode
                platformFlavor:(nullable NSString *)platformFlavor
         platformFlavorVersion:(nullable NSString *)platformFlavorVersion {
    RCStoreKitRequestFetcher *fetcher = [[RCStoreKitRequestFetcher alloc] init];
    RCReceiptFetcher *receiptFetcher = [[RCReceiptFetcher alloc] init];
    RCAttributionFetcher *attributionFetcher = [[RCAttributionFetcher alloc] init];
    RCSystemInfo *systemInfo = [[RCSystemInfo alloc] initWithPlatformFlavor:platformFlavor
                                                      platformFlavorVersion:platformFlavorVersion
                                                         finishTransactions:!observerMode];
    RCBackend *backend = [[RCBackend alloc] initWithAPIKey:APIKey systemInfo:systemInfo];
    RCStoreKitWrapper *storeKitWrapper = [[RCStoreKitWrapper alloc] init];
    RCOfferingsFactory *offeringsFactory = [[RCOfferingsFactory alloc] init];

    if (userDefaults == nil) {
        userDefaults = [NSUserDefaults standardUserDefaults];
    }

    RCDeviceCache *deviceCache = [[RCDeviceCache alloc] initWith:userDefaults];
    RCIdentityManager *identityManager = [[RCIdentityManager alloc] initWith:deviceCache backend:backend];
    RCSubscriberAttributesManager *subscriberAttributesManager =
            [[RCSubscriberAttributesManager alloc] initWithBackend:backend
                                                       deviceCache:deviceCache];
    RCOperationDispatcher *operationDispatcher = [[RCOperationDispatcher alloc] init];

    return [self initWithAppUserID:appUserID
                    requestFetcher:fetcher
                    receiptFetcher:receiptFetcher
                attributionFetcher:attributionFetcher
                           backend:backend
                   storeKitWrapper:storeKitWrapper
                notificationCenter:[NSNotificationCenter defaultCenter]
                      userDefaults:userDefaults
                        systemInfo:systemInfo
                  offeringsFactory:offeringsFactory
                       deviceCache:deviceCache
                   identityManager:identityManager
       subscriberAttributesManager:subscriberAttributesManager
               operationDispatcher:operationDispatcher];
}

- (instancetype)initWithAppUserID:(nullable NSString *)appUserID
                   requestFetcher:(RCStoreKitRequestFetcher *)requestFetcher
                   receiptFetcher:(RCReceiptFetcher *)receiptFetcher
               attributionFetcher:(RCAttributionFetcher *)attributionFetcher
                          backend:(RCBackend *)backend
                  storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
               notificationCenter:(NSNotificationCenter *)notificationCenter
                     userDefaults:(NSUserDefaults *)userDefaults
                       systemInfo:systemInfo
                 offeringsFactory:(RCOfferingsFactory *)offeringsFactory
                      deviceCache:(RCDeviceCache *)deviceCache
                  identityManager:(RCIdentityManager *)identityManager
      subscriberAttributesManager:(RCSubscriberAttributesManager *)subscriberAttributesManager
              operationDispatcher:(RCOperationDispatcher *)operationDispatcher {
    
    if (self = [super init]) {
        RCDebugLog(@"Debug logging enabled.");
        RCDebugLog(@"SDK Version - %@", self.class.frameworkVersion);
        RCDebugLog(@"Initial App User ID - %@", appUserID);

        self.requestFetcher = requestFetcher;
        self.receiptFetcher = receiptFetcher;
        self.attributionFetcher = attributionFetcher;
        self.backend = backend;
        self.storeKitWrapper = storeKitWrapper;
        self.offeringsFactory = offeringsFactory;
        self.deviceCache = deviceCache;
        self.identityManager = identityManager;

        self.notificationCenter = notificationCenter;
        self.userDefaults = userDefaults;

        self.productsByIdentifier = [NSMutableDictionary new];
        self.presentedOfferingsByProductIdentifier = [NSMutableDictionary new];
        self.purchaseCompleteCallbacks = [NSMutableDictionary new];

        self.systemInfo = systemInfo;
        self.subscriberAttributesManager = subscriberAttributesManager;
        self.operationDispatcher = operationDispatcher;

        RCReceivePurchaserInfoBlock callDelegate = ^void(RCPurchaserInfo *info, NSError *error) {
            if (info) {
                [self sendUpdatedPurchaserInfoToDelegateIfChanged:info];
            }
        };

        [self.identityManager configureWithAppUserID:appUserID];

        [self.systemInfo isApplicationBackgroundedWithCompletion:^(BOOL isBackgrounded) {
            if (!isBackgrounded) {
                [self.operationDispatcher dispatchOnWorkerThread:^{
                    [self updateAllCachesWithCompletionBlock:callDelegate];
                }];
            } else {
                [self sendCachedPurchaserInfoIfAvailable];
            }
        }];

        [self configureSubscriberAttributesManager];

        self.storeKitWrapper.delegate = self;
        [self.notificationCenter addObserver:self
                                    selector:@selector(applicationDidBecomeActive:)
                                        name:APP_DID_BECOME_ACTIVE_NOTIFICATION_NAME object:nil];

        if (postponedAttributionData) {
            for (RCAttributionData *attributionData in postponedAttributionData) {
                [self postAttributionData:attributionData.data fromNetwork:attributionData.network forNetworkUserId:attributionData.networkUserId];
            }
        }

        postponedAttributionData = nil;

        if (_automaticAppleSearchAdsAttributionCollection) {
            NSString *latestNetworkIdAndAdvertisingIdSentToAppleSearchAds = [self latestNetworkIdAndAdvertisingIdentifierSentForNetwork:RCAttributionNetworkAppleSearchAds];
            if (latestNetworkIdAndAdvertisingIdSentToAppleSearchAds == nil) {
                [attributionFetcher adClientAttributionDetailsWithCompletionBlock:^(NSDictionary<NSString *, NSObject *> *_Nullable attributionDetails, NSError *_Nullable error) {
                    NSArray *values = [attributionDetails allValues];

                    bool hasIadAttribution = values.count != 0 && [values[0][@"iad-attribution"] boolValue];
                    if (hasIadAttribution) {
                        [self postAttributionData:attributionDetails fromNetwork:RCAttributionNetworkAppleSearchAds forNetworkUserId:nil];
                    }
                }];
            }
        }
    }

    return self;
}

- (void)dealloc {
    self.storeKitWrapper.delegate = nil;
    [self.notificationCenter removeObserver:self];
    self.delegate = nil;
}

@synthesize delegate = _delegate;

- (void)setDelegate:(id <RCPurchasesDelegate>)delegate {
    _delegate = delegate;
    RCDebugLog(@"Delegate set");

    [self sendCachedPurchaserInfoIfAvailable];
}

#pragma mark - Public Methods

#pragma mark Attribution

- (void)postAttributionData:(NSDictionary *)data
                fromNetwork:(RCAttributionNetwork)network
           forNetworkUserId:(nullable NSString *)networkUserId {
    if (data[@"rc_appsflyer_id"]) {
        RCErrorLog(@"⚠️ The parameter key rc_appsflyer_id is deprecated. Pass networkUserId to addAttribution instead. ⚠️");
    }
    if (network == RCAttributionNetworkAppsFlyer && networkUserId == nil) {
        RCErrorLog(@"⚠️ The parameter networkUserId is REQUIRED for AppsFlyer. ⚠️");
    }
    NSString *networkKey = [NSString stringWithFormat:@"%ld",(long)network];
    NSString *identifierForAdvertisers = [self.attributionFetcher identifierForAdvertisers];
    NSString *cacheKey = [self attributionDataUserDefaultCacheKeyForAppUserID:self.identityManager.currentAppUserID];
    NSDictionary *dictOfLatestNetworkIdsAndAdvertisingIdsSentToNetworks = [self.userDefaults objectForKey:cacheKey];
    NSString *latestSentToNetwork = dictOfLatestNetworkIdsAndAdvertisingIdsSentToNetworks[networkKey];
    NSString *newValueForNetwork = [NSString stringWithFormat:@"%@_%@", identifierForAdvertisers, networkUserId];

    if ([latestSentToNetwork isEqualToString:newValueForNetwork]) {
        RCDebugLog(@"Attribution data is the same as latest. Skipping.");
    } else {
        NSMutableDictionary<NSString *, NSString *> *newDictToCache = [NSMutableDictionary dictionaryWithDictionary:dictOfLatestNetworkIdsAndAdvertisingIdsSentToNetworks];
        newDictToCache[networkKey] = newValueForNetwork;

        NSMutableDictionary *newData = [NSMutableDictionary dictionaryWithDictionary:data];
        newData[@"rc_idfa"] = identifierForAdvertisers;
        newData[@"rc_idfv"] = [self.attributionFetcher identifierForVendor];
        newData[@"rc_attribution_network_id"] = networkUserId;

        if (newData.count > 0) {
            [self.backend postAttributionData:newData
                                  fromNetwork:network
                                 forAppUserID:self.identityManager.currentAppUserID
                                   completion:^(NSError * _Nullable error) {
                                       if (error == nil) {
                                           [self.userDefaults setObject:newDictToCache
                                                                 forKey:cacheKey];
                                       }
                                   }];
        }
    }
}

+ (void)addAttributionData:(NSDictionary *)data
               fromNetwork:(RCAttributionNetwork)network {
    [self addAttributionData:data fromNetwork:network forNetworkUserId:nil];
}

+ (void)addAttributionData:(NSDictionary *)data
               fromNetwork:(RCAttributionNetwork)network
          forNetworkUserId:(nullable NSString *)networkUserId {
    if (_sharedPurchases) {
        RCLog(@"There is an instance configured, posting attribution.");
        [_sharedPurchases postAttributionData:data fromNetwork:network forNetworkUserId:networkUserId];
    } else {
        RCLog(@"There is no instance configured, caching attribution.");
        if (postponedAttributionData == nil) {
            postponedAttributionData = [NSMutableArray array];
        }
        [postponedAttributionData addObject:[[RCAttributionData alloc] initWithData:data fromNetwork:network forNetworkUserId:networkUserId]];
    }
}

#pragma mark Identity

- (NSString *)appUserID {
    return [self.identityManager currentAppUserID];
}

- (BOOL)isAnonymous {
    return [self.identityManager currentUserIsAnonymous];
}

- (void)createAlias:(NSString *)alias completionBlock:(nullable RCReceivePurchaserInfoBlock)completion {
    if ([alias isEqualToString:self.identityManager.currentAppUserID]) {
        [self purchaserInfoWithCompletionBlock:completion];
    } else {
        [self.identityManager createAlias:alias withCompletionBlock:^(NSError * _Nullable error) {
            if (error == nil) {
                [self updateAllCachesWithCompletionBlock:completion];
            } else {
                if (completion) {
                    [self.operationDispatcher dispatchOnMainThread: ^{
                        completion(nil, error);
                    }];
                }
            }
        }];
    }
}

- (void)identify:(NSString *)appUserID completionBlock:(nullable RCReceivePurchaserInfoBlock)completion {
    if ([appUserID isEqualToString:self.identityManager.currentAppUserID]) {
        [self purchaserInfoWithCompletionBlock:completion];
    } else {
        [self.identityManager identifyAppUserID:appUserID withCompletionBlock:^(NSError *error) {
            if (error == nil) {
                [self updateAllCachesWithCompletionBlock:completion];
            } else {
                if (completion) {
                    [self.operationDispatcher dispatchOnMainThread: ^{
                        completion(nil, error);
                    }];
                }
            }
        }];

    }
}

- (void)resetWithCompletionBlock:(nullable RCReceivePurchaserInfoBlock)completion {
    [self.userDefaults removeObjectForKey:[self attributionDataUserDefaultCacheKeyForAppUserID:self.appUserID]];
    [self.identityManager resetAppUserID];
    [self updateAllCachesWithCompletionBlock:completion];
}

- (void)purchaserInfoWithCompletionBlock:(RCReceivePurchaserInfoBlock)completion {
    RCPurchaserInfo *infoFromCache = [self readPurchaserInfoFromCache];
    if (infoFromCache) {
        RCDebugLog(@"Vending purchaserInfo from cache");
        if (completion) {
            [self.operationDispatcher dispatchOnMainThread: ^{
                completion(infoFromCache, nil);
            }];
        }
        if ([self.deviceCache isPurchaserInfoCacheStale]) {
            RCDebugLog(@"Cache is stale, updating caches");
            [self fetchAndCachePurchaserInfoWithCompletion:nil];
        }
    } else {
        RCDebugLog(@"No cached purchaser info, fetching");
        [self fetchAndCachePurchaserInfoWithCompletion:completion];
    }
}

#pragma mark Purchasing

- (void)productsWithIdentifiers:(NSArray<NSString *> *)productIdentifiers
                completionBlock:(RCReceiveProductsBlock)completion {
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
                for (SKProduct *p in newProducts) {
                    if (p.productIdentifier) {
                        self.productsByIdentifier[p.productIdentifier] = p;
                    }
                }
            }
            if (completion) {
                [self.operationDispatcher dispatchOnMainThread: ^{
                    completion([products arrayByAddingObjectsFromArray:newProducts]);
                }];
            }
        }];
    } else {
        if (completion) {
            [self.operationDispatcher dispatchOnMainThread:^ {
                completion(products);
            }];
        }
    }
}

- (void)purchaseProduct:(SKProduct *)product
    withCompletionBlock:(RCPurchaseCompletedBlock)completion {
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    [self purchaseProduct:product withPayment:payment withPresentedOfferingIdentifier:nil completion:completion];
}

- (void)purchasePackage:(RCPackage *)package
    withCompletionBlock:(RCPurchaseCompletedBlock)completion {
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:package.product];
    [self purchaseProduct:package.product withPayment:payment withPresentedOfferingIdentifier:package.offeringIdentifier completion:completion];
}

- (void)purchaseProduct:(SKProduct *)product
           withDiscount:(SKPaymentDiscount *)discount
        completionBlock:(RCPurchaseCompletedBlock)completion {
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    payment.paymentDiscount = discount;
    [self purchaseProduct:product withPayment:payment withPresentedOfferingIdentifier:nil completion:completion];
}

- (void)purchasePackage:(RCPackage *)package
           withDiscount:(SKPaymentDiscount *)discount
        completionBlock:(RCPurchaseCompletedBlock)completion {
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:package.product];
    payment.paymentDiscount = discount;
    [self purchaseProduct:package.product withPayment:payment withPresentedOfferingIdentifier:package.offeringIdentifier completion:completion];
}

- (void)        purchaseProduct:(SKProduct *)product
                    withPayment:(SKMutablePayment *)payment
withPresentedOfferingIdentifier:(nullable NSString *)presentedOfferingIdentifier
                     completion:(RCPurchaseCompletedBlock)completion {
    RCDebugLog(@"makePurchase");

    if (!product || !payment) {
        RCLog(@"makePurchase - Could not purchase SKProduct.");
        RCLog(@"makePurchase - Ensure your products are correctly configured in App Store Connect");
        RCLog(@"makePurchase - See https://www.revenuecat.com/2018/10/11/configuring-in-app-products-is-hard");
        completion(nil, nil, [NSError errorWithDomain:RCPurchasesErrorDomain
                                                 code:RCProductNotAvailableForPurchaseError
                                             userInfo:@{
                                                     NSLocalizedDescriptionKey: @"There was problem purchasing the product."
                                             }], false);
        return;
    }

    NSString *productIdentifier;
    if (product.productIdentifier) {
        productIdentifier = product.productIdentifier;
    } else if (payment.productIdentifier) {
        productIdentifier = payment.productIdentifier;
    } else {
        RCLog(@"makePurchase - Could not purchase SKProduct. Couldn't find its product identifier. This is possibly an App Store quirk.");
        completion(nil, nil, [NSError errorWithDomain:RCPurchasesErrorDomain
                                                 code:RCUnknownError
                                             userInfo:@{
                                                     NSLocalizedDescriptionKey: @"There was problem purchasing the product."
                                             }], false);
        return;
    }

    if (!self.finishTransactions) {
        RCDebugLog(@"makePurchase - Observer mode is active (finishTransactions is set to false) and makePurchase has been called. Are you sure you want to do this?");
    }
    payment.applicationUsername = self.appUserID;

    // This is to prevent the UIApplicationDidBecomeActive call from the purchase popup
    // from triggering a refresh.
    [self.deviceCache setPurchaserInfoCacheTimestampToNow];
    [self.deviceCache setOfferingsCacheTimestampToNow];

    if (presentedOfferingIdentifier) {
        RCDebugLog(@"makePurchase - %@ - Offering: %@", productIdentifier, presentedOfferingIdentifier);
    } else {
        RCDebugLog(@"makePurchase - %@", productIdentifier);
    }

    @synchronized (self) {
        self.productsByIdentifier[productIdentifier] = product;
    }

    @synchronized (self) {
        self.presentedOfferingsByProductIdentifier[productIdentifier] = presentedOfferingIdentifier;
    }

    @synchronized (self) {
        if (self.purchaseCompleteCallbacks[productIdentifier]) {
            completion(nil, nil, [NSError errorWithDomain:RCPurchasesErrorDomain
                                                     code:RCOperationAlreadyInProgressError
                                                 userInfo:@{
                                                         NSLocalizedDescriptionKey: @"Purchase already in progress for this product."
                                                 }], false);
            return;
        }
        self.purchaseCompleteCallbacks[productIdentifier] = [completion copy];
    }

    [self.storeKitWrapper addPayment:[payment copy]];
}


- (void)restoreTransactionsWithCompletionBlock:(nullable RCReceivePurchaserInfoBlock)completion {
    if (!self.allowSharingAppStoreAccount) {
        RCDebugLog(@"allowSharingAppStoreAccount is set to false and restoreTransactions has been called. Are you sure you want to do this?");
    }
    // Refresh the receipt and post to backend, this will allow the transactions to be transferred.
    // https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/Restoring.html
    [self receiptDataWithForceRefresh:YES completion:^(NSData * _Nonnull data) {
        if (data.length == 0) {
            if (RCSystemInfo.isSandbox) {
                RCLog(@"App running on sandbox without a receipt file. Restoring transactions won't work unless you've purchased before and there is a receipt available.");
            }
            if (completion) {
                [self.operationDispatcher dispatchOnMainThread: ^{
                    completion(nil, RCPurchasesErrorUtils.missingReceiptFileError);
                }];
            }
            return;
        }
        RCSubscriberAttributeDict subscriberAttributes = self.unsyncedAttributesByKey;
        [self.backend postReceiptData:data
                            appUserID:self.appUserID
                            isRestore:YES
                          productInfo:nil
          presentedOfferingIdentifier:nil
                         observerMode:!self.finishTransactions
                 subscriberAttributes:subscriberAttributes
                           completion:^(RCPurchaserInfo *_Nullable info, NSError *_Nullable error) {
                               [self handleRestoreReceiptPostWithInfo:info
                                                                error:error
                                                 subscriberAttributes:subscriberAttributes
                                                           completion:completion];
                           }];
    }];
}

- (void)handleRestoreReceiptPostWithInfo:(RCPurchaserInfo *)info
                                   error:(NSError *)error
                    subscriberAttributes:(RCSubscriberAttributeDict)subscriberAttributes
                              completion:(RCReceivePurchaserInfoBlock)completion {
    [self.operationDispatcher dispatchOnMainThread:^{
        if (error) {
            [self markAttributesAsSyncedIfNeeded:subscriberAttributes
                                       appUserID:self.appUserID
                                           error:error];
            if (completion) {
                [self.operationDispatcher dispatchOnMainThread:^ {
                    completion(nil, error);
                }];
            }
        } else if (info) {
            [self cachePurchaserInfo:info forAppUserID:self.appUserID];
            [self sendUpdatedPurchaserInfoToDelegateIfChanged:info];
            [self markAttributesAsSyncedIfNeeded:subscriberAttributes
                                       appUserID:self.appUserID
                                           error:nil];
            if (completion) {
                [self.operationDispatcher dispatchOnMainThread:^ {
                    completion(info, nil);
                }];
            }
        }
    }];
}

- (void)checkTrialOrIntroductoryPriceEligibility:(NSArray<NSString *> *)productIdentifiers
                                 completionBlock:(RCReceiveIntroEligibilityBlock)receiveEligibility {
    [self receiptData:^(NSData * _Nonnull data) {
        RCLocalReceiptParser *receiptParser = [[RCLocalReceiptParser alloc] init];
        [receiptParser checkTrialOrIntroductoryPriceEligibilityWithData:data
                                                     productIdentifiers:productIdentifiers
                                                             completion:^(NSDictionary<NSString *, NSNumber *> * _Nonnull receivedEligibility,
                                                                          NSError * _Nullable error) {
            if (!error) {
                NSMutableDictionary<NSString *, RCIntroEligibility *> *convertedEligibility = [[NSMutableDictionary alloc] init];
                
                for (NSString *key in receivedEligibility.allKeys) {
                    convertedEligibility[key] = [[RCIntroEligibility alloc] initWithEligibilityStatusCode:receivedEligibility[key]];
                }
                
                if (receiveEligibility) {
                    [self.operationDispatcher dispatchOnMainThread:^ {
                        receiveEligibility(convertedEligibility);
                    }];
                }
            } else {
                NSLog(@"There was an error when trying to parse the receipt locally, details: %@", error.localizedDescription);
                [self.backend getIntroEligibilityForAppUserID:self.appUserID
                                                  receiptData:data
                                           productIdentifiers:productIdentifiers
                                                   completion:^(NSDictionary<NSString *,RCIntroEligibility *> * _Nonnull result) {
                    if (receiveEligibility) {
                            [self.operationDispatcher dispatchOnMainThread:^ {
                            receiveEligibility(result);
                        }];
                    }
                }];
            }
        }];
        
    }];
}

- (void)paymentDiscountForProductDiscount:(SKProductDiscount *)discount
                                  product:(SKProduct *)product
                               completion:(RCPaymentDiscountBlock)completion {
    [self receiptData:^(NSData *data) {
        [self.backend postOfferForSigning:discount.identifier
                    withProductIdentifier:product.productIdentifier
                        subscriptionGroup:product.subscriptionGroupIdentifier
                              receiptData:data
                                appUserID:self.appUserID
                               completion:^(NSString *_Nullable signature,
                                       NSString *_Nullable keyIdentifier,
                                       NSUUID *_Nullable nonce,
                                       NSNumber *_Nullable timestamp,
                                       NSError *_Nullable error) {
                                   SKPaymentDiscount *paymentDiscount = [[SKPaymentDiscount alloc] initWithIdentifier:discount.identifier
                                                                                                        keyIdentifier:keyIdentifier
                                                                                                                nonce:nonce
                                                                                                            signature:signature
                                                                                                            timestamp:timestamp];
                                   completion(paymentDiscount, error);
                               }];
    }];
}

- (void)invalidatePurchaserInfoCache {
    RCDebugLog(@"Purchaser info cache is invalidated");
    [self.deviceCache clearPurchaserInfoCacheTimestamp];
}

#pragma mark Subcriber Attributes

- (void)setAttributes:(NSDictionary<NSString *, NSString *> *)attributes {
    [self _setAttributes:attributes];
}

- (void)setEmail:(nullable NSString *)email {
    [self _setEmail:email];
}

- (void)setPhoneNumber:(nullable NSString *)phoneNumber {
    [self _setPhoneNumber:phoneNumber];
}

- (void)setDisplayName:(nullable NSString *)displayName {
    [self _setDisplayName:displayName];
}

- (void)setPushToken:(nullable NSData *)pushToken {
    [self _setPushToken:pushToken];
}

#pragma mark - Private Methods

- (void)applicationDidBecomeActive:(__unused NSNotification *)notif {
    [self updateAllCachesIfNeeded];
}

- (void)sendCachedPurchaserInfoIfAvailable {
    RCPurchaserInfo *infoFromCache = [self readPurchaserInfoFromCache];
    if (infoFromCache) {
        [self sendUpdatedPurchaserInfoToDelegateIfChanged:infoFromCache];
    }
}

- (void)updateAllCachesIfNeeded {
    RCDebugLog(@"applicationDidBecomeActive");
    if ([self.deviceCache isPurchaserInfoCacheStale]) {
        RCDebugLog(@"PurchaserInfo cache is stale, updating caches");
        [self fetchAndCachePurchaserInfoWithCompletion:nil];
    }
    if ([self.deviceCache isOfferingsCacheStale]) {
        RCDebugLog(@"Offerings cache is stale, updating caches");
        [self updateOfferingsCache:nil];
    }
}

- (RCPurchaserInfo *)readPurchaserInfoFromCache {
    NSData *purchaserInfoData = [self.deviceCache cachedPurchaserInfoDataForAppUserID:self.appUserID];
    if (purchaserInfoData) {
        NSError *jsonError;
        NSDictionary *infoDict = [NSJSONSerialization JSONObjectWithData:purchaserInfoData options:0 error:&jsonError];
        if (jsonError == nil && infoDict != nil) {
            RCPurchaserInfo *info = [[RCPurchaserInfo alloc] initWithData:infoDict];
            if (info.schemaVersion != nil && [info.schemaVersion isEqual:[RCPurchaserInfo currentSchemaVersion]]) {
                return info;
            }
        }
    }
    return nil;
}

- (void)cachePurchaserInfo:(RCPurchaserInfo *)info forAppUserID:(NSString *)appUserID {
    if (info) {
        [self.operationDispatcher dispatchOnMainThread:^{
            if (info.JSONObject) {
                NSError *jsonError = nil;
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:info.JSONObject
                                                                   options:0
                                                                     error:&jsonError];
                if (jsonError == nil) {
                    [self.deviceCache cachePurchaserInfo:jsonData forAppUserID:appUserID];
                }
            }
        }];
    }
}

- (void)updateAllCaches {
    [self updateAllCachesWithCompletionBlock:nil];
}

- (void)updateAllCachesWithCompletionBlock:(nullable RCReceivePurchaserInfoBlock)completion {
    [self fetchAndCachePurchaserInfoWithCompletion:completion];
    [self updateOfferingsCache:nil];
}

- (void)fetchAndCachePurchaserInfoWithCompletion:(nullable RCReceivePurchaserInfoBlock)completion {
    [self.deviceCache setPurchaserInfoCacheTimestampToNow];
    NSString *appUserID = self.identityManager.currentAppUserID;
    [self.backend getSubscriberDataWithAppUserID:appUserID
                                      completion:^(RCPurchaserInfo * _Nullable info,
                                                   NSError * _Nullable error) {
        if (error == nil) {
            [self cachePurchaserInfo:info forAppUserID:appUserID];
            [self sendUpdatedPurchaserInfoToDelegateIfChanged:info];
        } else {
            [self.deviceCache clearPurchaserInfoCacheTimestamp];
        }
        
        if (completion) {
            [self.operationDispatcher dispatchOnMainThread:^ {
                completion(info, error);
            }];
        }
    }];
}

- (void)performOnEachProductIdentifierInOfferings:(NSDictionary *)offeringsData
                                            block:(void (^)(NSString *productIdentifier))block {
    for (NSDictionary *offering in offeringsData[@"offerings"]) {
        for (NSDictionary *package in offering[@"packages"]) {
            block(package[@"platform_product_identifier"]);
        }
    }
}

- (void)offeringsWithCompletionBlock:(RCReceiveOfferingsBlock)completion {
    if (self.deviceCache.cachedOfferings) {
        RCDebugLog(@"Vending offerings from cache");
        if (completion) {
            [self.operationDispatcher dispatchOnMainThread:^ {
                completion(self.deviceCache.cachedOfferings, nil);
            }];
        }
        if (self.deviceCache.isOfferingsCacheStale) {
            RCDebugLog(@"Offerings cache is stale, updating cache");
            [self updateOfferingsCache:nil];
        }
    } else {
        RCDebugLog(@"No cached offerings, fetching");
        [self updateOfferingsCache:completion];
    }
}

- (void)updateOfferingsCache:(nullable RCReceiveOfferingsBlock)completion {
    [self.deviceCache setOfferingsCacheTimestampToNow];
    __weak typeof(self) weakSelf = self;
    [self.backend getOfferingsForAppUserID:self.appUserID
                                completion:^(NSDictionary *data, NSError *error) {
                                    __strong typeof(self) strongSelf = weakSelf;
                                    if (error != nil) {
                                        [strongSelf handleOfferingsUpdateError:error completion:completion];
                                        return;
                                    }
                                    [strongSelf handleOfferingsBackendResultWithData:data completion:completion];
                                }];
}

- (void)handleOfferingsBackendResultWithData:(NSDictionary *)data completion:(RCReceiveOfferingsBlock)completion {
    NSMutableSet *productIdentifiers = [NSMutableSet new];
    [self performOnEachProductIdentifierInOfferings:data block:^(NSString *productIdentifier) {
        [productIdentifiers addObject:productIdentifier];
    }];

    [self productsWithIdentifiers:productIdentifiers.allObjects completionBlock:^(NSArray<SKProduct *> *_Nonnull products) {

        NSMutableDictionary *productsById = [NSMutableDictionary new];
        for (SKProduct *p in products) {
            productsById[p.productIdentifier] = p;
        }
        RCOfferings *offerings = [self.offeringsFactory createOfferingsWithProducts:productsById data:data];
        if (offerings) {
            NSMutableArray *missingProducts = [NSMutableArray new];
            [self performOnEachProductIdentifierInOfferings:data block:^(NSString *productIdentifier) {
                SKProduct *product = productsById[productIdentifier];

                if (product == nil) {
                    [missingProducts addObject:productIdentifier];
                }
            }];

            if (missingProducts.count > 0) {
                RCLog(@"Could not find SKProduct for %@", missingProducts);
                RCLog(@"Ensure your products are correctly configured in App Store Connect");
                RCLog(@"See https://www.revenuecat.com/2018/10/11/configuring-in-app-products-is-hard");
            }
            [self.deviceCache cacheOfferings:offerings];

            if (completion) {
                [self.operationDispatcher dispatchOnMainThread:^ {
                    completion(offerings, nil);
                }];
            }
            
        } else {
            [self handleOfferingsUpdateError:RCPurchasesErrorUtils.unexpectedBackendResponseError completion:completion];
        }
    }];
}

- (void)handleOfferingsUpdateError:(NSError *)error completion:(RCReceiveOfferingsBlock)completion {
    RCLog(@"Error fetching offerings - %@", error);
    [self.deviceCache clearOfferingsCacheTimestamp];
    if (completion) {
        [self.operationDispatcher dispatchOnMainThread:^ {
            completion(nil, error);
        }];
    }
}

- (void)receiptData:(RCReceiveReceiptDataBlock)completion {
    [self receiptDataWithForceRefresh:NO completion:completion];
}

- (void)receiptDataWithForceRefresh:(BOOL)forceRefresh completion:(RCReceiveReceiptDataBlock)completion {
    if (forceRefresh) {
        RCDebugLog(@"Forced receipt refresh");
        [self refreshReceipt:completion];
        return;
    }
    NSData *receiptData = [self.receiptFetcher receiptData];
    if (receiptData == nil || receiptData.length == 0) {
        RCDebugLog(@"Receipt empty, fetching");
        [self refreshReceipt:completion];
    } else {
        completion(receiptData);
    }
}

- (void)refreshReceipt:(RCReceiveReceiptDataBlock)completion {
    [self.requestFetcher fetchReceiptData:^{
        NSData *newReceiptData = [self.receiptFetcher receiptData];
        if (newReceiptData == nil || newReceiptData.length == 0) {
            RCLog(@"Unable to load receipt, ensure you are logged in to the correct iTunes account.");
        }
        completion(newReceiptData ?: [NSData data]);
    }];
}

- (void)handleReceiptPostWithTransaction:(SKPaymentTransaction *)transaction
                           purchaserInfo:(nullable RCPurchaserInfo *)info
                    subscriberAttributes:(nullable RCSubscriberAttributeDict)subscriberAttributes
                                   error:(nullable NSError *)error {
    [self.operationDispatcher dispatchOnMainThread:^{
        [self markAttributesAsSyncedIfNeeded:subscriberAttributes appUserID:self.appUserID error:error];

        RCPurchaseCompletedBlock _Nullable completion = [self getAndRemovePurchaseCompletedBlockFor:transaction];
        if (info) {
            [self cachePurchaserInfo:info forAppUserID:self.appUserID];

            [self sendUpdatedPurchaserInfoToDelegateIfChanged:info];
            if (completion) {
                completion(transaction, info, nil, false);
            }
            
            if (self.finishTransactions) {
                [self.storeKitWrapper finishTransaction:transaction];
            }
        } else if ([error.userInfo[RCFinishableKey] boolValue]) {
            if (completion) {
                completion(transaction, nil, error, false);
            }
            if (self.finishTransactions) {
                [self.storeKitWrapper finishTransaction:transaction];
            }
        } else if (![error.userInfo[RCFinishableKey] boolValue]) {
            if (completion) {
                completion(transaction, nil, error, false);
            }
        } else {
            RCLog(@"Unexpected error from backend");
            if (completion) {
                completion(transaction, nil, error, false);
            }
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
                [self.operationDispatcher dispatchOnMainThread:^{
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
     updatedTransaction:(SKPaymentTransaction *)transaction {
    switch (transaction.transactionState) {
        case SKPaymentTransactionStateRestored: // For observer mode
        case SKPaymentTransactionStatePurchased: {
            [self handlePurchasedTransaction:transaction];
            break;
        }
        case SKPaymentTransactionStateFailed: {
            _Nullable RCPurchaseCompletedBlock completion = [self getAndRemovePurchaseCompletedBlockFor:transaction];
            
            if (completion) {
                [self.operationDispatcher dispatchOnMainThread:^ {
                    BOOL wasCancelled = transaction.error.code == SKErrorPaymentCancelled;
                    NSError *error = [RCPurchasesErrorUtils purchasesErrorWithSKError:transaction.error];
                    completion(transaction, nil, error, wasCancelled);
                }];
            }
            
            if (self.finishTransactions) {
                [self.storeKitWrapper finishTransaction:transaction];
            }
            break;
        }
        case SKPaymentTransactionStateDeferred: {
            _Nullable RCPurchaseCompletedBlock completion = [self getAndRemovePurchaseCompletedBlockFor:transaction];

            if (completion) {
                [self.operationDispatcher dispatchOnMainThread:^ {
                    BOOL wasCancelled = transaction.error.code == SKErrorPaymentCancelled;
                    NSError *error = RCPurchasesErrorUtils.paymentDeferredError;
                    completion(transaction, nil, error, wasCancelled);
                }];
            }
            break;
        }
        case SKPaymentTransactionStatePurchasing:
            break;
    }
}

- (nullable RCPurchaseCompletedBlock)getAndRemovePurchaseCompletedBlockFor:(SKPaymentTransaction *)transaction {
    RCPurchaseCompletedBlock completion = nil;
    NSString * _Nullable productIdentifier = [self productIdentifierFrom:transaction];
    if (productIdentifier) {
        @synchronized (self) {
            completion = self.purchaseCompleteCallbacks[productIdentifier];
            self.purchaseCompleteCallbacks[productIdentifier] = nil;
        }
    }
    return completion;
}

- (void)storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
     removedTransaction:(SKPaymentTransaction *)transaction {
}

- (BOOL)storeKitWrapper:(nonnull RCStoreKitWrapper *)storeKitWrapper shouldAddStorePayment:(nonnull SKPayment *)payment forProduct:(nonnull SKProduct *)product {
    @synchronized(self) {
        self.productsByIdentifier[product.productIdentifier] = product;
    }

    if ([self.delegate respondsToSelector:@selector(purchases:shouldPurchasePromoProduct:defermentBlock:)]) {
        [self.delegate purchases:self
      shouldPurchasePromoProduct:product
                  defermentBlock:^(RCPurchaseCompletedBlock completion) {
                      self.purchaseCompleteCallbacks[product.productIdentifier] = [completion copy];
                      [self.storeKitWrapper addPayment:payment];
                  }];
    }

    return NO;
}

- (NSString *)latestNetworkIdAndAdvertisingIdentifierSentForNetwork:(RCAttributionNetwork)network {
    NSString *cacheKey = [NSString stringWithFormat:@"%ld", (long)network];
    NSDictionary *cachedDict = [self.userDefaults objectForKey:[self attributionDataUserDefaultCacheKeyForAppUserID:self.appUserID]];
    return cachedDict[cacheKey];
}

- (NSString *)attributionDataUserDefaultCacheKeyForAppUserID:(NSString *)appUserID {
    return [RCAttributionDataDefaultsKeyBase stringByAppendingString:appUserID];
}

- (void)handlePurchasedTransaction:(SKPaymentTransaction *)transaction {
    [self receiptData:^(NSData * _Nonnull data) {
        if (data.length == 0) {
            [self handleReceiptPostWithTransaction:transaction
                                     purchaserInfo:nil
                              subscriberAttributes:nil
                                             error:RCPurchasesErrorUtils.missingReceiptFileError];
        } else {
            [self fetchProductsAndPostReceiptWithTransaction:transaction data:data];
        }
    }];
}

- (void)fetchProductsAndPostReceiptWithTransaction:(SKPaymentTransaction *)transaction data:(NSData *)data {
    if ([self productIdentifierFrom:transaction]) {
        [self productsWithIdentifiers:@[[self productIdentifierFrom:transaction]]
                      completionBlock:^(NSArray<SKProduct *> *products) {
                          [self postReceiptWithTransaction:transaction data:data products:products];
                      }];
    } else {
        [self handleReceiptPostWithTransaction:transaction
                                 purchaserInfo:nil
                          subscriberAttributes:nil
                                         error:RCPurchasesErrorUtils.unknownError];
    }
}

- (void)postReceiptWithTransaction:(SKPaymentTransaction *)transaction
                              data:(NSData *)data
                          products:(NSArray<SKProduct *> *)products {
    SKProduct *product = products.lastObject;
    RCSubscriberAttributeDict subscriberAttributes = self.unsyncedAttributesByKey;
    RCProductInfo *productInfo = nil;
    NSString *presentedOffering = nil;
    if (product) {
        RCProductInfoExtractor *productInfoExtractor = [[RCProductInfoExtractor alloc] init];
        productInfo = [productInfoExtractor extractInfoFromProduct:product];

        @synchronized (self) {
            presentedOffering = self.presentedOfferingsByProductIdentifier[productInfo.productIdentifier];
            [self.presentedOfferingsByProductIdentifier removeObjectForKey:productInfo.productIdentifier];
        }
    }
    [self.backend postReceiptData:data
                        appUserID:self.appUserID
                        isRestore:self.allowSharingAppStoreAccount
                      productInfo:productInfo
      presentedOfferingIdentifier:presentedOffering
                     observerMode:!self.finishTransactions
             subscriberAttributes:subscriberAttributes
                       completion:^(RCPurchaserInfo *_Nullable info,
                               NSError *_Nullable error) {
                           [self handleReceiptPostWithTransaction:transaction
                                                    purchaserInfo:info
                                             subscriberAttributes:subscriberAttributes
                                                            error:error];
                       }];
}

- (nullable NSString *)productIdentifierFrom:(SKPaymentTransaction *)transaction {
    if (transaction.payment == nil) {
        RCLog(@"There is a problem with the payment. Couldn't find the payment. This is possibly an App Store quirk.");
    } else if (transaction.payment.productIdentifier == nil) {
        RCLog(@"There is a problem with the payment. Couldn't find its product identifier. This is possibly an App Store quirk.");
    }
    return transaction.payment.productIdentifier;
}

@end

