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
#import "RCCrossPlatformSupport.h"
#import "RCPurchasesErrors.h"
#import "RCPurchasesErrorUtils.h"
#import "RCReceiptFetcher.h"
#import "RCAttributionFetcher.h"
#import "RCAttributionData.h"
#import "RCOfferingsFactory.h"
#import "RCPackage+Protected.h"
#import "RCDeviceCache.h"
#import "RCIdentityManager.h"
#import "RCSubscriberAttributesManager.h"
#import "RCSystemInfo.h"
#import "RCProductInfoExtractor.h"
#import "RCIntroEligibility+Protected.h"
#import "RCReceiptRefreshPolicy.h"
#import "RCPurchaserInfoManager.h"
@import PurchasesCoreSwift;


#define CALL_IF_SET_ON_MAIN_THREAD(completion, ...) if (completion) [self.operationDispatcher dispatchOnMainThread:^{ completion(__VA_ARGS__); }];
#define CALL_IF_SET_ON_SAME_THREAD(completion, ...) if (completion) completion(__VA_ARGS__);

@interface RCPurchases () <RCStoreKitWrapperDelegate, RCPurchaserInfoManagerDelegate> {
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

@property (nonatomic) NSMutableDictionary<NSString *, SKProduct *> *productsByIdentifier;
@property (nonatomic) NSMutableDictionary<NSString *, NSString *> *presentedOfferingsByProductIdentifier;
@property (nonatomic) NSMutableDictionary<NSString *, RCPurchaseCompletedBlock> *purchaseCompleteCallbacks;
@property (nonatomic) RCAttributionFetcher *attributionFetcher;
@property (nonatomic) RCOfferingsFactory *offeringsFactory;
@property (nonatomic) RCDeviceCache *deviceCache;
@property (nonatomic) RCIdentityManager *identityManager;
@property (nonatomic) RCSystemInfo *systemInfo;
@property (nonatomic) RCIntroEligibilityCalculator *introEligibilityCalculator;
@property (nonatomic) RCReceiptParser *receiptParser;
@property (nonatomic) RCPurchaserInfoManager *purchaserInfoManager;

@end

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

+ (BOOL)forceUniversalAppStore {
    return RCSystemInfo.forceUniversalAppStore;
}

+ (void)setForceUniversalAppStore:(BOOL)forceUniversalAppStore {
    RCSystemInfo.forceUniversalAppStore = forceUniversalAppStore;
}

+ (BOOL)simulatesAskToBuyInSandbox {
    return RCStoreKitWrapper.simulatesAskToBuyInSandbox;
}

+ (void)setSimulatesAskToBuyInSandbox:(BOOL)simulatesAskToBuyInSandbox {
    RCStoreKitWrapper.simulatesAskToBuyInSandbox = simulatesAskToBuyInSandbox;
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
        RCWarnLog(@"%@", RCStrings.configure.no_singleton_instance);
    }
    return _sharedPurchases;
}

+ (void)setDefaultInstance:(RCPurchases *)instance {
    @synchronized([RCPurchases class]) {
        if (_sharedPurchases) {
            RCLog(@"%@", RCStrings.configure.purchase_instance_already_set);
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
    RCOperationDispatcher *operationDispatcher = [[RCOperationDispatcher alloc] init];
    RCIntroEligibilityCalculator *introCalculator = [[RCIntroEligibilityCalculator alloc] init];
    RCReceiptParser *receiptParser = [[RCReceiptParser alloc] init];
    RCPurchaserInfoManager *purchaserInfoManager = [[RCPurchaserInfoManager alloc]
                                                                            initWithOperationDispatcher:operationDispatcher
                                                                                            deviceCache:deviceCache
                                                                                                backend:backend
                                                                                             systemInfo:systemInfo];
    RCIdentityManager *identityManager = [[RCIdentityManager alloc] initWith:deviceCache
                                                                     backend:backend
                                                        purchaserInfoManager:purchaserInfoManager];
    RCAttributionTypeFactory *attributionTypeFactory = [[RCAttributionTypeFactory alloc] init];
    RCAttributionFetcher *attributionFetcher = [[RCAttributionFetcher alloc]
                                                initWithDeviceCache:deviceCache
                                                identityManager:identityManager
                                                backend:backend
                                                attributionFactory:attributionTypeFactory
                                                systemInfo:systemInfo];
    RCSubscriberAttributesManager *subscriberAttributesManager =
            [[RCSubscriberAttributesManager alloc] initWithBackend:backend
                                                       deviceCache:deviceCache
                                                attributionFetcher:attributionFetcher];
    return [self initWithAppUserID:appUserID
                    requestFetcher:fetcher
                    receiptFetcher:receiptFetcher
                attributionFetcher:attributionFetcher
                           backend:backend
                   storeKitWrapper:storeKitWrapper
                notificationCenter:[NSNotificationCenter defaultCenter]
                        systemInfo:systemInfo
                  offeringsFactory:offeringsFactory
                       deviceCache:deviceCache
                   identityManager:identityManager
       subscriberAttributesManager:subscriberAttributesManager
               operationDispatcher:operationDispatcher
        introEligibilityCalculator:introCalculator
                     receiptParser:receiptParser
              purchaserInfoManager:purchaserInfoManager];
}

- (instancetype)initWithAppUserID:(nullable NSString *)appUserID
                   requestFetcher:(RCStoreKitRequestFetcher *)requestFetcher
                   receiptFetcher:(RCReceiptFetcher *)receiptFetcher
               attributionFetcher:(RCAttributionFetcher *)attributionFetcher
                          backend:(RCBackend *)backend
                  storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
               notificationCenter:(NSNotificationCenter *)notificationCenter
                       systemInfo:(RCSystemInfo *)systemInfo
                 offeringsFactory:(RCOfferingsFactory *)offeringsFactory
                      deviceCache:(RCDeviceCache *)deviceCache
                  identityManager:(RCIdentityManager *)identityManager
      subscriberAttributesManager:(RCSubscriberAttributesManager *)subscriberAttributesManager
              operationDispatcher:(RCOperationDispatcher *)operationDispatcher
       introEligibilityCalculator:(RCIntroEligibilityCalculator *)introEligibilityCalculator
                    receiptParser:(RCReceiptParser *)receiptParser
             purchaserInfoManager:(RCPurchaserInfoManager *)purchaserInfoManager {
    if (self = [super init]) {
        RCDebugLog(@"%@", RCStrings.configure.debug_enabled);
        RCDebugLog(RCStrings.configure.sdk_version, self.class.frameworkVersion);
        RCUserLog(RCStrings.configure.initial_app_user_id, appUserID);

        self.requestFetcher = requestFetcher;
        self.receiptFetcher = receiptFetcher;
        self.attributionFetcher = attributionFetcher;
        self.backend = backend;
        self.storeKitWrapper = storeKitWrapper;
        self.offeringsFactory = offeringsFactory;
        self.deviceCache = deviceCache;
        self.identityManager = identityManager;

        self.notificationCenter = notificationCenter;

        self.productsByIdentifier = [NSMutableDictionary new];
        self.presentedOfferingsByProductIdentifier = [NSMutableDictionary new];
        self.purchaseCompleteCallbacks = [NSMutableDictionary new];

        self.systemInfo = systemInfo;
        self.subscriberAttributesManager = subscriberAttributesManager;
        self.operationDispatcher = operationDispatcher;
        self.introEligibilityCalculator = introEligibilityCalculator;
        self.receiptParser = receiptParser;
        self.purchaserInfoManager = purchaserInfoManager;

        [self.identityManager configureWithAppUserID:appUserID];

        [self.systemInfo isApplicationBackgroundedWithCompletion:^(BOOL isBackgrounded) {
            if (!isBackgrounded) {
                [self.operationDispatcher dispatchOnWorkerThreadWithRandomDelay:NO block:^{
                    [self updateAllCachesWithCompletionBlock:nil];
                }];
            } else {
                [self.purchaserInfoManager sendCachedPurchaserInfoIfAvailableForAppUserID:self.appUserID];
            }
        }];
        self.storeKitWrapper.delegate = self;

        [self subscribeToAppStateNotifications];

        [self.attributionFetcher postPostponedAttributionDataIfNeeded];
        [self postAppleSearchAddsAttributionCollectionIfNeeded];
    }

    return self;
}

- (void)subscribeToAppStateNotifications {
    [self.notificationCenter addObserver:self
                                selector:@selector(applicationDidBecomeActive:)
                                    name:APP_DID_BECOME_ACTIVE_NOTIFICATION_NAME object:nil];
    [self.notificationCenter addObserver:self
                                selector:@selector(applicationWillResignActive:)
                                    name:APP_WILL_RESIGN_ACTIVE_NOTIFICATION_NAME
                                  object:nil];
}

- (void)dealloc {
    self.storeKitWrapper.delegate = nil;
    self.purchaserInfoManager.delegate = nil;
    [self.notificationCenter removeObserver:self];
    _delegate = nil;
}

@synthesize delegate = _delegate;

- (void)setDelegate:(id <RCPurchasesDelegate>)delegate {
    _delegate = delegate;
    self.purchaserInfoManager.delegate = self;
    [self.purchaserInfoManager sendCachedPurchaserInfoIfAvailableForAppUserID:self.appUserID];
    RCDebugLog(@"%@", RCStrings.configure.delegate_set);
}

#pragma mark - Public Methods

#pragma mark Attribution

- (void)postAttributionData:(NSDictionary *)data
                fromNetwork:(RCAttributionNetwork)network
           forNetworkUserId:(nullable NSString *)networkUserId {
    [self.attributionFetcher postAttributionData:data
                                     fromNetwork:network
                                forNetworkUserId:networkUserId];
}

+ (void)addAttributionData:(NSDictionary *)data
               fromNetwork:(RCAttributionNetwork)network {
    [self addAttributionData:data fromNetwork:network forNetworkUserId:nil];
}

+ (void)addAttributionData:(NSDictionary *)data
               fromNetwork:(RCAttributionNetwork)network
          forNetworkUserId:(nullable NSString *)networkUserId {
    if (_sharedPurchases) {
        RCDebugLog(@"%@", RCStrings.attribution.instance_configured_posting_attribution);
        [_sharedPurchases postAttributionData:data fromNetwork:network forNetworkUserId:networkUserId];
    } else {
        RCDebugLog(@"%@", RCStrings.attribution.no_instance_configured_caching_attribution);
        [RCAttributionFetcher storePostponedAttributionData:data
                                                fromNetwork:network
                                           forNetworkUserId:networkUserId];
    }
}

- (void)postAppleSearchAddsAttributionCollectionIfNeeded {
    if (_automaticAppleSearchAdsAttributionCollection) {
        [self.attributionFetcher postAppleSearchAdsAttributionIfNeeded];
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
        [self.identityManager createAliasForAppUserID:alias completion:^(NSError *_Nullable error) {
            if (error == nil) {
                [self updateAllCachesWithCompletionBlock:completion];
            } else {
                CALL_IF_SET_ON_MAIN_THREAD(completion, nil, error);
            }
        }];
    }
}

- (void)identify:(NSString *)appUserID completionBlock:(nullable RCReceivePurchaserInfoBlock)completion {
    if ([appUserID isEqualToString:self.identityManager.currentAppUserID]) {
        [self purchaserInfoWithCompletionBlock:completion];
    } else {
        [self.identityManager identifyAppUserID:appUserID completion:^(NSError *error) {
            if (error == nil) {
                [self updateAllCachesWithCompletionBlock:completion];
            } else {
                CALL_IF_SET_ON_MAIN_THREAD(completion, nil, error);
            }
        }];

    }
}

- (void)  logIn:(NSString *)appUserID
completionBlock:(void (^)(RCPurchaserInfo * _Nullable purchaserInfo, BOOL created, NSError * _Nullable error))completion {
    [self.identityManager logInWithAppUserID:appUserID completion:^(RCPurchaserInfo *purchaserInfo,
                                                                    BOOL created,
                                                                    NSError * _Nullable error) {
        CALL_IF_SET_ON_MAIN_THREAD(completion, purchaserInfo, created, error);

        if (error == nil) {
            [self.systemInfo isApplicationBackgroundedWithCompletion:^(BOOL isAppBackgrounded) {
                [self updateOfferingsCacheWithIsAppBackgrounded:isAppBackgrounded completion:nil];
            }];
        }
    }];
}

- (void)logOutWithCompletionBlock:(nullable RCReceivePurchaserInfoBlock)completion {
    [self.identityManager logOutWithCompletion:^(NSError *error) {
        if (error) {
            CALL_IF_SET_ON_MAIN_THREAD(completion, nil, error);
        } else {
            [self updateAllCachesWithCompletionBlock:completion];
        }
    }];
}

- (void)resetWithCompletionBlock:(nullable RCReceivePurchaserInfoBlock)completion {
    [self.identityManager resetAppUserID];
    [self updateAllCachesWithCompletionBlock:completion];
}

- (void)purchaserInfoWithCompletionBlock:(RCReceivePurchaserInfoBlock)completion {
    [self.purchaserInfoManager purchaserInfoWithAppUserID:self.appUserID
                                          completionBlock:completion];
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
                                    CALL_IF_SET_ON_MAIN_THREAD(completion, [products arrayByAddingObjectsFromArray:newProducts]);
                                }];
    } else {
        CALL_IF_SET_ON_MAIN_THREAD(completion, products);
    }
}

- (void)purchaseProduct:(SKProduct *)product
    withCompletionBlock:(RCPurchaseCompletedBlock)completion {
    SKMutablePayment *payment = [self.storeKitWrapper paymentWithProduct:product];
    [self purchaseProduct:product withPayment:payment withPresentedOfferingIdentifier:nil completion:completion];
}

- (void)purchasePackage:(RCPackage *)package
    withCompletionBlock:(RCPurchaseCompletedBlock)completion {
    SKMutablePayment *payment = [self.storeKitWrapper paymentWithProduct:package.product];
    [self purchaseProduct:package.product withPayment:payment withPresentedOfferingIdentifier:package.offeringIdentifier completion:completion];
}

- (void)purchaseProduct:(SKProduct *)product
           withDiscount:(SKPaymentDiscount *)discount
        completionBlock:(RCPurchaseCompletedBlock)completion {
    SKMutablePayment *payment = [self.storeKitWrapper paymentWithProduct:product discount:discount];
    [self purchaseProduct:product withPayment:payment withPresentedOfferingIdentifier:nil completion:completion];
}

- (void)purchasePackage:(RCPackage *)package
           withDiscount:(SKPaymentDiscount *)discount
        completionBlock:(RCPurchaseCompletedBlock)completion {
    SKMutablePayment *payment = [self.storeKitWrapper paymentWithProduct:package.product
                                                                discount:discount];
    [self purchaseProduct:package.product withPayment:payment withPresentedOfferingIdentifier:package.offeringIdentifier completion:completion];
}

- (void)        purchaseProduct:(SKProduct *)product
                    withPayment:(SKMutablePayment *)payment
withPresentedOfferingIdentifier:(nullable NSString *)presentedOfferingIdentifier
                     completion:(RCPurchaseCompletedBlock)completion {
    RCDebugLog(@"makePurchase");

    if (!product || !payment) {
        RCAppleWarningLog(@"%@", RCStrings.purchase.cannot_purchase_product_appstore_configuration_error);
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
        RCWarnLog(@"%@", RCStrings.purchase.purchasing_with_observer_mode_and_finish_transactions_false_warning);
    }
    NSString *appUserID = self.appUserID;
    payment.applicationUsername = appUserID;

    // This is to prevent the UIApplicationDidBecomeActive call from the purchase popup
    // from triggering a refresh.
    [self.deviceCache setPurchaserInfoCacheTimestampToNowForAppUserID:appUserID];
    [self.deviceCache setOfferingsCacheTimestampToNow];

    if (presentedOfferingIdentifier) {
        RCPurchaseLog(RCStrings.purchase.purchasing_product_from_package, productIdentifier, presentedOfferingIdentifier);
    } else {
        RCPurchaseLog(RCStrings.purchase.purchasing_product, productIdentifier);
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

- (void)syncPurchasesWithCompletionBlock:(nullable RCReceivePurchaserInfoBlock)completion {
    [self syncPurchasesWithReceiptRefreshPolicy:RCReceiptRefreshPolicyNever
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
                                      isRestore:self.allowSharingAppStoreAccount
#pragma GCC diagnostic pop
                                     completion:completion];
}

- (void)restoreTransactionsWithCompletionBlock:(nullable RCReceivePurchaserInfoBlock)completion {
    [self syncPurchasesWithReceiptRefreshPolicy:RCReceiptRefreshPolicyAlways
                                      isRestore:YES
                                     completion:completion];
}

- (void)syncPurchasesWithReceiptRefreshPolicy:(RCReceiptRefreshPolicy)refreshPolicy
                                    isRestore:(BOOL)isRestore
                                   completion:(nullable RCReceivePurchaserInfoBlock)completion {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    if (!self.allowSharingAppStoreAccount) {
#pragma GCC diagnostic pop
        RCWarnLog(@"%@", RCStrings.restore.restoretransactions_called_with_allow_sharing_appstore_account_false_warning);
    }
    // Refresh the receipt and post to backend, this will allow the transactions to be transferred.
    // https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/Restoring.html
    [self receiptDataWithReceiptRefreshPolicy:refreshPolicy completion:^(NSData *_Nonnull data) {
        if (data.length == 0) {
            if (RCSystemInfo.isSandbox) {
                RCAppleWarningLog(@"%@", RCStrings.receipt.no_sandbox_receipt_restore);
            }
            CALL_IF_SET_ON_MAIN_THREAD(completion, nil, [RCPurchasesErrorUtils missingReceiptFileError]);
            return;
        }

        RCPurchaserInfo * _Nullable cachedPurchaserInfo = [self.purchaserInfoManager
                                                           cachedPurchaserInfoForAppUserID:self.appUserID];
        BOOL hasOriginalPurchaseDate = cachedPurchaserInfo != nil && cachedPurchaserInfo.originalPurchaseDate != nil;
        BOOL receiptHasTransactions = [self.receiptParser receiptHasTransactionsWithReceiptData:data];
        if (!receiptHasTransactions && hasOriginalPurchaseDate) {
            CALL_IF_SET_ON_MAIN_THREAD(completion, cachedPurchaserInfo, nil);
            return;
        }

        RCSubscriberAttributeDict subscriberAttributes = self.unsyncedAttributesByKey;
        [self.backend postReceiptData:data
                            appUserID:self.appUserID
                            isRestore:isRestore
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
            CALL_IF_SET_ON_MAIN_THREAD(completion, nil, error);
        } else if (info) {
            [self.purchaserInfoManager cachePurchaserInfo:info forAppUserID:self.appUserID];
            [self markAttributesAsSyncedIfNeeded:subscriberAttributes
                                       appUserID:self.appUserID
                                           error:nil];
            CALL_IF_SET_ON_MAIN_THREAD(completion, info, nil);
        }
    }];
}

- (void)checkTrialOrIntroductoryPriceEligibility:(NSArray<NSString *> *)productIdentifiers
                                 completionBlock:(RCReceiveIntroEligibilityBlock)receiveEligibility
{
    [self receiptData:^(NSData *data) {
        if (data != nil && data.length > 0) {
            if (@available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *)) {
                NSSet *productIdentifiersSet = [[NSSet alloc] initWithArray:productIdentifiers];
                [self.introEligibilityCalculator checkTrialOrIntroductoryPriceEligibilityWith:data
                                                                           productIdentifiers:productIdentifiersSet
                                                                                   completion:^(NSDictionary<NSString *, NSNumber *> * _Nonnull receivedEligibility,
                                                                                                NSError * _Nullable error) {
                    if (!error) {
                        NSMutableDictionary<NSString *, RCIntroEligibility *> *convertedEligibility = [[NSMutableDictionary alloc] init];
                        
                        for (NSString *key in receivedEligibility.allKeys) {
                            convertedEligibility[key] = [[RCIntroEligibility alloc] initWithEligibilityStatusCode:receivedEligibility[key]];
                        }
                        
                        CALL_IF_SET_ON_MAIN_THREAD(receiveEligibility, convertedEligibility);
                    } else {
                        RCErrorLog(RCStrings.receipt.parse_receipt_locally_error,
                                   error.localizedDescription);
                        [self.backend getIntroEligibilityForAppUserID:self.appUserID
                                                          receiptData:data
                                                   productIdentifiers:productIdentifiers
                                                           completion:^(NSDictionary<NSString *,RCIntroEligibility *> * _Nonnull result) {
                            CALL_IF_SET_ON_MAIN_THREAD(receiveEligibility, result);
                        }];
                    }
                }];
            } else {
                [self.backend getIntroEligibilityForAppUserID:self.appUserID
                                                  receiptData:data
                                           productIdentifiers:productIdentifiers
                                                   completion:^(NSDictionary<NSString *, RCIntroEligibility *> *_Nonnull result) {
                                                       CALL_IF_SET_ON_MAIN_THREAD(receiveEligibility, result);
                                                   }];
            }
        } else {
            [self.backend getIntroEligibilityForAppUserID:self.appUserID
                                              receiptData:data
                                       productIdentifiers:productIdentifiers
                                               completion:^(NSDictionary<NSString *,RCIntroEligibility *> * _Nonnull result) {
                CALL_IF_SET_ON_MAIN_THREAD(receiveEligibility, result);
            }];
        }
    }];
}

- (void)paymentDiscountForProductDiscount:(SKProductDiscount *)discount
                                  product:(SKProduct *)product
                               completion:(RCPaymentDiscountBlock)completion {
    [self receiptData:^(NSData *data) {
        if (data == nil || data.length == 0) {
            completion(nil, RCPurchasesErrorUtils.missingReceiptFileError);
        } else {
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
        }
    }];
}

- (void)invalidatePurchaserInfoCache {
    RCDebugLog(@"%@", RCStrings.purchaserInfo.invalidating_purchaserinfo_cache);
    [self.purchaserInfoManager clearPurchaserInfoCacheForAppUserID:self.appUserID];
}

- (void)presentCodeRedemptionSheet API_AVAILABLE(ios(14.0)) API_UNAVAILABLE(tvos, macos, watchos) {
    RCDebugLog(@"%@", RCStrings.purchase.presenting_code_redemption_sheet);
    [self.storeKitWrapper presentCodeRedemptionSheet];
}

#pragma mark Subcriber Attributes

- (void)setAttributes:(NSDictionary<NSString *, NSString *> *)attributes {
    RCDebugLog(RCStrings.attribution.method_called, "setAttributes");
    [self.subscriberAttributesManager setAttributes:attributes appUserID:self.appUserID];
}

- (void)setEmail:(nullable NSString *)email {
    RCDebugLog(RCStrings.attribution.method_called, "setEmail");
    [self.subscriberAttributesManager setEmail:email appUserID:self.appUserID];
}

- (void)setPhoneNumber:(nullable NSString *)phoneNumber {
    RCDebugLog(RCStrings.attribution.method_called, "setPhoneNumber");
    [self.subscriberAttributesManager setPhoneNumber:phoneNumber appUserID:self.appUserID];
}

- (void)setDisplayName:(nullable NSString *)displayName {
    RCDebugLog(RCStrings.attribution.method_called, "setDisplayName");
    [self.subscriberAttributesManager setDisplayName:displayName appUserID:self.appUserID];
}

- (void)setPushToken:(nullable NSData *)pushToken {
    RCDebugLog(RCStrings.attribution.method_called, "setPushToken");
    [self.subscriberAttributesManager setPushToken:pushToken appUserID:self.appUserID];
}

- (void)_setPushTokenString:(nullable NSString *)pushToken {
    RCDebugLog(RCStrings.attribution.method_called, "setPushTokenString");
    [self.subscriberAttributesManager setPushTokenString:pushToken appUserID:self.appUserID];
}

- (void)setAdjustID:(nullable NSString *)adjustID {
    RCDebugLog(RCStrings.attribution.method_called, "setAdjustID");
    [self.subscriberAttributesManager setAdjustID:adjustID appUserID:self.appUserID];
}

- (void)setAppsflyerID:(nullable NSString *)appsflyerID {
    RCDebugLog(RCStrings.attribution.method_called, "setAppsflyerID");
    [self.subscriberAttributesManager setAppsflyerID:appsflyerID appUserID:self.appUserID];
}

- (void)setFBAnonymousID:(nullable NSString *)fbAnonymousID {
    RCDebugLog(RCStrings.attribution.method_called, "setFBAnonymousID");
    [self.subscriberAttributesManager setFBAnonymousID:fbAnonymousID appUserID:self.appUserID];
}

- (void)setMparticleID:(nullable NSString *)mparticleID {
    RCDebugLog(RCStrings.attribution.method_called, "setMparticleID");
    [self.subscriberAttributesManager setMparticleID:mparticleID appUserID:self.appUserID];
}

- (void)setOnesignalID:(nullable NSString *)onesignalID {
    RCDebugLog(RCStrings.attribution.method_called, "setOnesignalID");
    [self.subscriberAttributesManager setOnesignalID:onesignalID appUserID:self.appUserID];
}

- (void)setMediaSource:(nullable NSString *)mediaSource {
    RCDebugLog(RCStrings.attribution.method_called, "setMediaSource");
    [self.subscriberAttributesManager setMediaSource:mediaSource appUserID:self.appUserID];
}

- (void)setCampaign:(nullable NSString *)campaign {
    RCDebugLog(RCStrings.attribution.method_called, "setCampaign");
    [self.subscriberAttributesManager setCampaign:campaign appUserID:self.appUserID];
}

- (void)setAdGroup:(nullable NSString *)adGroup {
    RCDebugLog(RCStrings.attribution.method_called, "setAdGroup");
    [self.subscriberAttributesManager setAdGroup:adGroup appUserID:self.appUserID];
}

- (void)setAd:(nullable NSString *)ad {
    RCDebugLog(RCStrings.attribution.method_called, "setAd");
    [self.subscriberAttributesManager setAd:ad appUserID:self.appUserID];
}

- (void)setKeyword:(nullable NSString *)keyword {
    RCDebugLog(RCStrings.attribution.method_called, "setKeyword");
    [self.subscriberAttributesManager setKeyword:keyword appUserID:self.appUserID];
}

- (void)setCreative:(nullable NSString *)creative {
    RCDebugLog(RCStrings.attribution.method_called, "setCreative");
    [self.subscriberAttributesManager setCreative:creative appUserID:self.appUserID];
}

- (void)collectDeviceIdentifiers {
    RCDebugLog(@"collectDeviceIdentifiers called");
    RCDebugLog(RCStrings.attribution.method_called, "setAttributes");
    [self.subscriberAttributesManager collectDeviceIdentifiersForAppUserID:self.appUserID];
}

#pragma mark - Private Methods

- (void)applicationDidBecomeActive:(__unused NSNotification *)notif {
    [self updateAllCachesIfNeeded];
    [self syncSubscriberAttributesIfNeeded];
    [self postAppleSearchAddsAttributionCollectionIfNeeded];
}

- (void)applicationWillResignActive:(__unused NSNotification *)notif {
    [self syncSubscriberAttributesIfNeeded];
}

- (void)updateAllCachesIfNeeded {
    RCDebugLog(@"%@", RCStrings.configure.application_active);
    [self.systemInfo isApplicationBackgroundedWithCompletion:^(BOOL isAppBackgrounded) {
        [self.purchaserInfoManager fetchAndCachePurchaserInfoIfStaleWithAppUserID:self.appUserID
                                                                isAppBackgrounded:isAppBackgrounded
                                                                       completion:nil];
        if ([self.deviceCache isOfferingsCacheStaleWithIsAppBackgrounded:isAppBackgrounded]) {
            RCDebugLog(@"Offerings cache is stale, updating caches");
            [self updateOfferingsCacheWithIsAppBackgrounded:isAppBackgrounded completion:nil];
        }
    }];
}

- (void)updateAllCachesWithCompletionBlock:(nullable RCReceivePurchaserInfoBlock)completion {
    [self.systemInfo isApplicationBackgroundedWithCompletion:^(BOOL isAppBackgrounded) {
        [self.purchaserInfoManager fetchAndCachePurchaserInfoWithAppUserID:self.appUserID
                                                         isAppBackgrounded:isAppBackgrounded
                                                                completion:completion];
        [self updateOfferingsCacheWithIsAppBackgrounded:isAppBackgrounded completion:nil];
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
        RCDebugLog(@"%@", RCStrings.offering.vending_offerings_cache);
        CALL_IF_SET_ON_MAIN_THREAD(completion, self.deviceCache.cachedOfferings, nil);
        [self.systemInfo isApplicationBackgroundedWithCompletion:^(BOOL isAppBackgrounded) {
            if ([self.deviceCache isOfferingsCacheStaleWithIsAppBackgrounded:isAppBackgrounded]) {
                RCDebugLog(@"%@",
                           isAppBackgrounded
                           ? RCStrings.offering.offerings_stale_updating_in_background
                           : RCStrings.offering.offerings_stale_updating_in_foreground);
                [self updateOfferingsCacheWithIsAppBackgrounded:isAppBackgrounded completion:nil];
                RCSuccessLog(@"%@", RCStrings.offering.offerings_stale_updated_from_network);
            }
        }];
    } else {
        RCDebugLog(@"%@", RCStrings.offering.no_cached_offerings_fetching_from_network);
        [self.systemInfo isApplicationBackgroundedWithCompletion:^(BOOL isAppBackgrounded) {
            [self updateOfferingsCacheWithIsAppBackgrounded:isAppBackgrounded completion:completion];
        }];
    }
}

- (void)updateOfferingsCacheWithIsAppBackgrounded:(BOOL)isAppBackgrounded
                                       completion:(nullable RCReceiveOfferingsBlock)completion {
    [self.deviceCache setOfferingsCacheTimestampToNow];
    [self.operationDispatcher dispatchOnWorkerThreadWithRandomDelay:isAppBackgrounded block:^{
        [self.backend getOfferingsForAppUserID:self.appUserID
                                    completion:^(NSDictionary *data, NSError *error) {
                                        if (error != nil) {
                                            [self handleOfferingsUpdateError:error completion:completion];
                                            return;
                                        }
                                        [self handleOfferingsBackendResultWithData:data completion:completion];
                                    }];
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
                RCAppleWarningLog(RCStrings.offering.cannot_find_product_configuration_error, missingProducts);
            }
            [self.deviceCache cacheOfferings:offerings];

            CALL_IF_SET_ON_MAIN_THREAD(completion, offerings, nil);
        } else {
            [self handleOfferingsUpdateError:RCPurchasesErrorUtils.unexpectedBackendResponseError completion:completion];
        }
    }];
}

- (void)handleOfferingsUpdateError:(NSError *)error completion:(RCReceiveOfferingsBlock)completion {
    RCAppleErrorLog(RCStrings.offering.fetching_offerings_error, error);
    [self.deviceCache clearOfferingsCacheTimestamp];
    CALL_IF_SET_ON_MAIN_THREAD(completion, nil, error);
}

- (void)receiptData:(RCReceiveReceiptDataBlock)completion {
    [self receiptDataWithReceiptRefreshPolicy:RCReceiptRefreshPolicyOnlyIfEmpty
                                   completion:completion];
}

- (void)receiptDataWithReceiptRefreshPolicy:(RCReceiptRefreshPolicy)refreshPolicy
                                 completion:(RCReceiveReceiptDataBlock)completion {
    if (refreshPolicy == RCReceiptRefreshPolicyAlways) {
        RCDebugLog(@"%@", RCStrings.receipt.force_refreshing_receipt);
        [self refreshReceipt:completion];
        return;
    }
    NSData *receiptData = [self.receiptFetcher receiptData];
    BOOL receiptIsEmpty = receiptData == nil || receiptData.length == 0;
    if (receiptIsEmpty && refreshPolicy == RCReceiptRefreshPolicyOnlyIfEmpty) {
        RCDebugLog(@"%@", RCStrings.receipt.refreshing_empty_receipt);
        [self refreshReceipt:completion];
    } else {
        completion(receiptData);
    }
}

- (void)refreshReceipt:(RCReceiveReceiptDataBlock)completion {
    [self.requestFetcher fetchReceiptData:^{
        NSData *newReceiptData = [self.receiptFetcher receiptData];
        if (newReceiptData == nil || newReceiptData.length == 0) {
            RCAppleWarningLog(@"%@", RCStrings.receipt.unable_to_load_receipt);
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
            [self.purchaserInfoManager cachePurchaserInfo:info forAppUserID:self.appUserID];

            CALL_IF_SET_ON_SAME_THREAD(completion, transaction, info, nil, false);

            if (self.finishTransactions) {
                [self.storeKitWrapper finishTransaction:transaction];
            }
        } else if ([error.userInfo[RCFinishableKey] boolValue]) {
            CALL_IF_SET_ON_SAME_THREAD(completion, transaction, nil, error, false);
            if (self.finishTransactions) {
                [self.storeKitWrapper finishTransaction:transaction];
            }
        } else if (![error.userInfo[RCFinishableKey] boolValue]) {
            CALL_IF_SET_ON_SAME_THREAD(completion, transaction, nil, error, false);
        } else {
            RCErrorLog(@"%@", RCStrings.receipt.unknown_backend_error);
            CALL_IF_SET_ON_SAME_THREAD(completion, transaction, nil, error, false);
        }
    }];
}

#pragma MARK: RCStoreKitWrapperDelegate
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

            CALL_IF_SET_ON_MAIN_THREAD(
                    completion,
                    transaction,
                    nil,
                    [RCPurchasesErrorUtils purchasesErrorWithSKError:transaction.error],
                    transaction.error.code == SKErrorPaymentCancelled);

            if (self.finishTransactions) {
                [self.storeKitWrapper finishTransaction:transaction];
            }
            break;
        }
        case SKPaymentTransactionStateDeferred: {
            _Nullable RCPurchaseCompletedBlock completion = [self getAndRemovePurchaseCompletedBlockFor:transaction];

            NSError *pendingError = [RCPurchasesErrorUtils paymentDeferredError];
            CALL_IF_SET_ON_MAIN_THREAD(completion,
                                       transaction,
                                       nil,
                                       pendingError,
                                       transaction.error.code == SKErrorPaymentCancelled);
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
- (void)                   storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
didRevokeEntitlementsForProductIdentifiers:(NSArray<NSString *> *)productIdentifiers
API_AVAILABLE(ios(14.0), macos(11.0), tvos(14.0), watchos(7.0)) {
    RCDebugLog(RCStrings.purchase.entitlements_revoked_syncing_purchases, productIdentifiers);
    [self syncPurchasesWithCompletionBlock:^(RCPurchaserInfo * _Nullable purchaserInfo, NSError * _Nullable error) {
        RCDebugLog(@"%@", RCStrings.purchase.purchases_synced);
    }];
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
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
                        isRestore:self.allowSharingAppStoreAccount
#pragma GCC diagnostic pop
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
        RCAppleWarningLog(@"%@", RCStrings.purchase.skpayment_missing_from_skpaymenttransaction);
    } else if (transaction.payment.productIdentifier == nil) {
        RCAppleWarningLog(@"%@", RCStrings.purchase.skpayment_missing_product_identifier);
    }
    return transaction.payment.productIdentifier;
}

#pragma MARK: RCPurchaserInfoManagerDelegate
- (void)purchaserInfoManagerDidReceiveUpdatedPurchaserInfo:(RCPurchaserInfo *)purchaserInfo {
    if (self.delegate && [self.delegate respondsToSelector:@selector(purchases:didReceiveUpdatedPurchaserInfo:)]) {
        [self.delegate purchases:self didReceiveUpdatedPurchaserInfo:purchaserInfo];
    }
}

@end

