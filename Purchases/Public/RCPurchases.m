//
//  RCPurchases.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

@import PurchasesCoreSwift;

#import "RCAttributionPoster.h"
#import "RCIdentityManager.h"
#import "RCPurchases+Protected.h"
#import "RCPurchases+SubscriberAttributes.h"
#import "RCPurchases.h"
#import "RCSubscriberAttributesManager.h"

// TODO: simply replace with OperationDispatcher when migrating
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
@property (nonatomic) RCProductsManager *productsManager;
@property (nonatomic) RCReceiptFetcher *receiptFetcher;
@property (nonatomic) RCBackend *backend;
@property (nonatomic) RCStoreKitWrapper *storeKitWrapper;
@property (nonatomic) NSNotificationCenter *notificationCenter;

// TODO: move to new class PurchasesManager, possibly rename to a name that describes intent?
@property (nonatomic) NSMutableDictionary<NSString *, NSString *> *presentedOfferingsByProductIdentifier;
// TODO: move to new class PurchasesManager
@property (nonatomic) NSMutableDictionary<NSString *, RCPurchaseCompletedBlock> *purchaseCompleteCallbacks;

@property (nonatomic) RCAttributionFetcher *attributionFetcher;
@property (nonatomic) RCAttributionPoster *attributionPoster;
@property (nonatomic) RCOfferingsFactory *offeringsFactory;
@property (nonatomic) RCDeviceCache *deviceCache;
@property (nonatomic) RCIdentityManager *identityManager;
@property (nonatomic) RCSystemInfo *systemInfo;
@property (nonatomic) RCIntroEligibilityCalculator *introEligibilityCalculator;
@property (nonatomic) RCReceiptParser *receiptParser;
@property (nonatomic) RCPurchaserInfoManager *purchaserInfoManager;
@property (nonatomic) RCOfferingsManager *offeringsManager;

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
    RCLogLevel level = enabled ? RCLogLevelDebug : RCLogLevelInfo;
    [self setLogLevel:level];
}

+ (BOOL)debugLogsEnabled {
    return self.logLevel <= RCLogLevelDebug;
}

+ (void)setLogHandler:(void(^)(RCLogLevel, NSString * _Nonnull))logHandler {
    RCLog.logHandler = logHandler;
}

+ (RCLogLevel)logLevel {
    return RCLog.logLevel;
}

+ (void)setLogLevel:(RCLogLevel)logLevel {
    RCLog.logLevel = logLevel;
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

+ (BOOL)isConfigured {
    return _sharedPurchases != nil;
}

+ (instancetype)sharedPurchases {
    NSCAssert(_sharedPurchases, RCStrings.configure.no_singleton_instance);
    return _sharedPurchases;
}

+ (void)setDefaultInstance:(RCPurchases *)instance {
    @synchronized([RCPurchases class]) {
        if (_sharedPurchases) {
            [RCLog info:[NSString stringWithFormat:@"%@", RCStrings.configure.purchase_instance_already_set]];
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

// TODO: if possible, move to new DI manager class
- (instancetype)initWithAPIKey:(NSString *)APIKey
                     appUserID:(nullable NSString *)appUserID
                  userDefaults:(nullable NSUserDefaults *)userDefaults
                  observerMode:(BOOL)observerMode
                platformFlavor:(nullable NSString *)platformFlavor
         platformFlavorVersion:(nullable NSString *)platformFlavorVersion {
    RCOperationDispatcher *operationDispatcher = [[RCOperationDispatcher alloc] init];
    RCReceiptRefreshRequestFactory *receiptRefreshRequestFactory = [[RCReceiptRefreshRequestFactory alloc] init];
    RCStoreKitRequestFetcher *fetcher = [[RCStoreKitRequestFetcher alloc]
                                         initWithRequestFactory:receiptRefreshRequestFactory
                                         operationDispatcher:operationDispatcher];
    RCReceiptFetcher *receiptFetcher = [[RCReceiptFetcher alloc] initWithRequestFetcher:fetcher];
    NSError *error = nil;
    RCSystemInfo *systemInfo = [[RCSystemInfo alloc] initWithPlatformFlavor:platformFlavor
                                                      platformFlavorVersion:platformFlavorVersion
                                                         finishTransactions:!observerMode
                                                                      error:&error];
    NSAssert(systemInfo, error.localizedDescription);

    RCETagManager *eTagManager = [[RCETagManager alloc] init];

    RCBackend *backend = [[RCBackend alloc] initWithAPIKey:APIKey
                                                systemInfo:systemInfo
                                               eTagManager:eTagManager
                                       operationDispatcher:operationDispatcher];
    RCStoreKitWrapper *storeKitWrapper = [[RCStoreKitWrapper alloc] init];
    RCOfferingsFactory *offeringsFactory = [[RCOfferingsFactory alloc] init];

    if (userDefaults == nil) {
        userDefaults = [NSUserDefaults standardUserDefaults];
    }

    RCDeviceCache *deviceCache = [[RCDeviceCache alloc] initWithUserDefaults:userDefaults];
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
                                                initWithAttributionFactory:attributionTypeFactory
                                                systemInfo:systemInfo];
    RCAttributionDataMigrator *attributionDataMigrator = [[RCAttributionDataMigrator alloc] init];
    RCSubscriberAttributesManager *subscriberAttributesManager =
            [[RCSubscriberAttributesManager alloc] initWithBackend:backend
                                                       deviceCache:deviceCache
                                                attributionFetcher:attributionFetcher
                                           attributionDataMigrator:attributionDataMigrator];

    RCAttributionPoster *attributionPoster = [[RCAttributionPoster alloc] initWithDeviceCache:deviceCache
                                                                              identityManager:identityManager
                                                                                      backend:backend
                                                                                   systemInfo:systemInfo
                                                                           attributionFetcher:attributionFetcher
                                                                  subscriberAttributesManager:subscriberAttributesManager];

    RCProductsRequestFactory *productsRequestFactory = [[RCProductsRequestFactory alloc] init];
    RCProductsManager *productsManager = [[RCProductsManager alloc] initWithProductsRequestFactory:productsRequestFactory];
    RCOfferingsManager *offeringsManager = [[RCOfferingsManager alloc] initWithDeviceCache:deviceCache
                                                                       operationDispatcher:operationDispatcher
                                                                                systemInfo:systemInfo
                                                                                   backend:backend
                                                                          offeringsFactory:offeringsFactory
                                                                           productsManager:productsManager];
    return [self initWithAppUserID:appUserID
                    requestFetcher:fetcher
                    receiptFetcher:receiptFetcher
                attributionFetcher:attributionFetcher
                 attributionPoster:attributionPoster
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
              purchaserInfoManager:purchaserInfoManager
                   productsManager:productsManager
                  offeringsManager:offeringsManager];
}

- (instancetype)initWithAppUserID:(nullable NSString *)appUserID
                   requestFetcher:(RCStoreKitRequestFetcher *)requestFetcher
                   receiptFetcher:(RCReceiptFetcher *)receiptFetcher
               attributionFetcher:(RCAttributionFetcher *)attributionFetcher
                attributionPoster:(RCAttributionPoster *)attributionPoster
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
             purchaserInfoManager:(RCPurchaserInfoManager *)purchaserInfoManager
                  productsManager:(RCProductsManager *)productsManager
                 offeringsManager:(RCOfferingsManager *)offeringsManager {
    if (self = [super init]) {
        [RCLog debug:[NSString stringWithFormat:@"%@", RCStrings.configure.debug_enabled]];
        [RCLog debug:[NSString stringWithFormat:RCStrings.configure.sdk_version, self.class.frameworkVersion]];
        [RCLog user:[NSString stringWithFormat:RCStrings.configure.initial_app_user_id, appUserID]];

        self.requestFetcher = requestFetcher;
        self.receiptFetcher = receiptFetcher;
        self.attributionFetcher = attributionFetcher;
        self.attributionPoster = attributionPoster;
        self.backend = backend;
        self.storeKitWrapper = storeKitWrapper;
        self.offeringsFactory = offeringsFactory;
        self.deviceCache = deviceCache;
        self.identityManager = identityManager;

        self.notificationCenter = notificationCenter;

        self.presentedOfferingsByProductIdentifier = [NSMutableDictionary new];
        self.purchaseCompleteCallbacks = [NSMutableDictionary new];

        self.systemInfo = systemInfo;
        self.subscriberAttributesManager = subscriberAttributesManager;
        self.operationDispatcher = operationDispatcher;
        self.introEligibilityCalculator = introEligibilityCalculator;
        self.receiptParser = receiptParser;
        self.purchaserInfoManager = purchaserInfoManager;
        self.productsManager = productsManager;
        self.offeringsManager = offeringsManager;

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

        [self.attributionPoster postPostponedAttributionDataIfNeeded];
        [self postAppleSearchAddsAttributionCollectionIfNeeded];
    }

    return self;
}

- (void)subscribeToAppStateNotifications {
    [self.notificationCenter addObserver:self
                                selector:@selector(applicationDidBecomeActive:)
                                    name:RCSystemInfo.applicationDidBecomeActiveNotification
                                  object:nil];
    [self.notificationCenter addObserver:self
                                selector:@selector(applicationWillResignActive:)
                                    name:RCSystemInfo.applicationWillResignActiveNotification
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
    [RCLog debug:[NSString stringWithFormat:@"%@", RCStrings.configure.delegate_set]];
}

#pragma mark - Public Methods

#pragma mark Attribution

- (void)postAttributionData:(NSDictionary *)data
                fromNetwork:(RCAttributionNetwork)network
           forNetworkUserId:(nullable NSString *)networkUserId {
    [self.attributionPoster postAttributionData:data
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
    if (self.isConfigured) {
        [_sharedPurchases postAttributionData:data fromNetwork:network forNetworkUserId:networkUserId];
    } else {
        [RCAttributionPoster storePostponedAttributionData:data
                                               fromNetwork:network
                                          forNetworkUserId:networkUserId];
    }
}

- (void)postAppleSearchAddsAttributionCollectionIfNeeded {
    if (_automaticAppleSearchAdsAttributionCollection) {
        [self.attributionPoster postAppleSearchAdsAttributionIfNeeded];
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
                [self.offeringsManager updateOfferingsCacheWithAppUserID:self.appUserID
                                                       isAppBackgrounded:isAppBackgrounded
                                                              completion:nil];
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
    NSSet<NSString *> *productIdentifiersSet = [[NSSet alloc] initWithArray:productIdentifiers];
    if (productIdentifiersSet.count > 0) {
        [self.productsManager productsWithIdentifiers:productIdentifiersSet
                                           completion:^(NSSet<SKProduct *> * _Nonnull products) {
            CALL_IF_SET_ON_MAIN_THREAD(completion, products.allObjects);
        }];
    } else {
        CALL_IF_SET_ON_MAIN_THREAD(completion, @[]);
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
    // todo: move log to relevant class
    [RCLog debug:[NSString stringWithFormat:@"makePurchase"]];

    if (!product || !payment) {
        [RCLog appleWarning:[NSString stringWithFormat:@"%@",
                             RCStrings.purchase.cannot_purchase_product_appstore_configuration_error]];
        completion(nil, nil, [NSError errorWithDomain:RCPurchasesErrorCodeDomain
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
        [RCLog info:[NSString stringWithFormat:@"%@", RCStrings.purchase.could_not_purchase_product_id_not_found]];
        completion(nil, nil, [NSError errorWithDomain:RCPurchasesErrorCodeDomain
                                                 code:RCUnknownError
                                             userInfo:@{
                                                     NSLocalizedDescriptionKey: @"There was problem purchasing the product."
                                             }], false);
        return;
    }

    if (!self.finishTransactions) {
        [RCLog warn:[NSString stringWithFormat:@"%@",
                     RCStrings.purchase.purchasing_with_observer_mode_and_finish_transactions_false_warning]];
    }
    NSString *appUserID = self.appUserID;
    payment.applicationUsername = appUserID;

    // This is to prevent the UIApplicationDidBecomeActive call from the purchase popup
    // from triggering a refresh.
    [self.deviceCache setPurchaserInfoCacheTimestampToNowForAppUserID:appUserID];
    [self.deviceCache setOfferingsCacheTimestampToNow];

    if (presentedOfferingIdentifier) {
        [RCLog purchase:[NSString stringWithFormat:RCStrings.purchase.purchasing_product_from_package,
                          productIdentifier, presentedOfferingIdentifier]];
    } else {
        [RCLog purchase:[NSString stringWithFormat:RCStrings.purchase.purchasing_product, productIdentifier]];
    }

    [self.productsManager cacheProduct:product];

    @synchronized (self) {
        self.presentedOfferingsByProductIdentifier[productIdentifier] = presentedOfferingIdentifier;
    }

    @synchronized (self) {
        if (self.purchaseCompleteCallbacks[productIdentifier]) {
            completion(nil, nil, [NSError errorWithDomain:RCPurchasesErrorCodeDomain
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
        [RCLog warn:[NSString stringWithFormat:@"%@",
                     RCStrings.restore.restoretransactions_called_with_allow_sharing_appstore_account_false_warning]];
    }
    // Refresh the receipt and post to backend, this will allow the transactions to be transferred.
    // https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/Restoring.html
    [self.receiptFetcher receiptDataWithRefreshPolicy:refreshPolicy
                                           completion:^(NSData *_Nonnull data) {
        if (data.length == 0) {
            if (RCSystemInfo.isSandbox) {
                [RCLog appleWarning:[NSString stringWithFormat:@"%@", RCStrings.receipt.no_sandbox_receipt_restore]];
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

// TODO: simplify logic, move to separate class
- (void)checkTrialOrIntroductoryPriceEligibility:(NSArray<NSString *> *)productIdentifiers
                                 completionBlock:(RCReceiveIntroEligibilityBlock)receiveEligibility
{
    [self.receiptFetcher receiptDataWithRefreshPolicy:RCReceiptRefreshPolicyOnlyIfEmpty
                                           completion:^(NSData * _Nullable data) {
        if (data != nil && data.length > 0) {
            if (@available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *)) {
                NSSet *productIdentifiersSet = [[NSSet alloc] initWithArray:productIdentifiers];
                [self.introEligibilityCalculator checkTrialOrIntroductoryPriceEligibilityWith:data
                                                                           productIdentifiers:productIdentifiersSet
                                                                                   completion:^(NSDictionary<NSString *, NSNumber *> * _Nonnull receivedEligibility,
                                                                                                NSError * _Nullable error) {
                    if (!error) {
                        NSMutableDictionary<NSString *, RCIntroEligibility *> *convertedEligibility = [[NSMutableDictionary alloc] init];

                        // TODO: remove enum conversion once this is moved to swift
                        for (NSString *key in receivedEligibility.allKeys) {
                            NSError *error = nil;
                            RCIntroEligibility *eligibility = [[RCIntroEligibility alloc] initWithEligibilityStatusCode:receivedEligibility[key] error:&error];
                            if (!eligibility) {
                                [RCLog error:[NSString stringWithFormat:@"Unable to create an RCIntroEligibility: %@",
                                              error.localizedDescription]];
                            } else {
                                convertedEligibility[key] = eligibility;
                            }
                        }

                        CALL_IF_SET_ON_MAIN_THREAD(receiveEligibility, convertedEligibility);
                    } else {
                        // todo: unify all of these `else`s
                        [RCLog error:[NSString stringWithFormat:RCStrings.receipt.parse_receipt_locally_error,
                                      error.localizedDescription]];
                        [self.backend getIntroEligibilityForAppUserID:self.appUserID
                                                          receiptData:data
                                                   productIdentifiers:productIdentifiers
                                                           completion:^(NSDictionary<NSString *,RCIntroEligibility *> * _Nonnull result, NSError * _Nullable error) {
                            [RCLog error:[NSString stringWithFormat:@"Unable to getIntroEligibilityForAppUserID: %@",
                                          error.localizedDescription]];
                            CALL_IF_SET_ON_MAIN_THREAD(receiveEligibility, result);
                        }];
                    }
                }];
            } else {
                [self.backend getIntroEligibilityForAppUserID:self.appUserID
                                                  receiptData:data
                                           productIdentifiers:productIdentifiers
                                                   completion:^(NSDictionary<NSString *, RCIntroEligibility *> *_Nonnull result, NSError * _Nullable error) {
                    [RCLog error:[NSString stringWithFormat:@"Unable to getIntroEligibilityForAppUserID: %@",
                                  error.localizedDescription]];
                    CALL_IF_SET_ON_MAIN_THREAD(receiveEligibility, result);
                }];
            }
        } else {
            [self.backend getIntroEligibilityForAppUserID:self.appUserID
                                              receiptData:data
                                       productIdentifiers:productIdentifiers
                                               completion:^(NSDictionary<NSString *,RCIntroEligibility *> * _Nonnull result, NSError * _Nullable error) {
                [RCLog error:[NSString stringWithFormat:@"Unable to getIntroEligibilityForAppUserID: %@",
                              error.localizedDescription]];
                CALL_IF_SET_ON_MAIN_THREAD(receiveEligibility, result);
            }];
        }
    }];
}

// TODO: add API availability check here, match headers
- (void)paymentDiscountForProductDiscount:(SKProductDiscount *)discount
                                  product:(SKProduct *)product
                               completion:(RCPaymentDiscountBlock)completion {
    [self.receiptFetcher receiptDataWithRefreshPolicy:RCReceiptRefreshPolicyOnlyIfEmpty
                                           completion:^(NSData * _Nullable data) {
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
    [self.purchaserInfoManager clearPurchaserInfoCacheForAppUserID:self.appUserID];
}

- (void)presentCodeRedemptionSheet API_AVAILABLE(ios(14.0)) API_UNAVAILABLE(tvos, macos, watchos) {
    [self.storeKitWrapper presentCodeRedemptionSheet];
}

#pragma mark Subcriber Attributes

- (void)setAttributes:(NSDictionary<NSString *, NSString *> *)attributes {
    [self.subscriberAttributesManager setAttributes:attributes appUserID:self.appUserID];
}

- (void)setEmail:(nullable NSString *)email {
    [self.subscriberAttributesManager setEmail:email appUserID:self.appUserID];
}

- (void)setPhoneNumber:(nullable NSString *)phoneNumber {
    [self.subscriberAttributesManager setPhoneNumber:phoneNumber appUserID:self.appUserID];
}

- (void)setDisplayName:(nullable NSString *)displayName {
    [self.subscriberAttributesManager setDisplayName:displayName appUserID:self.appUserID];
}

- (void)setPushToken:(nullable NSData *)pushToken {
    [self.subscriberAttributesManager setPushToken:pushToken appUserID:self.appUserID];
}

- (void)_setPushTokenString:(nullable NSString *)pushToken {
    [self.subscriberAttributesManager setPushTokenString:pushToken appUserID:self.appUserID];
}

- (void)setAdjustID:(nullable NSString *)adjustID {
    [self.subscriberAttributesManager setAdjustID:adjustID appUserID:self.appUserID];
}

- (void)setAppsflyerID:(nullable NSString *)appsflyerID {
    [self.subscriberAttributesManager setAppsflyerID:appsflyerID appUserID:self.appUserID];
}

- (void)setFBAnonymousID:(nullable NSString *)fbAnonymousID {
    [self.subscriberAttributesManager setFBAnonymousID:fbAnonymousID appUserID:self.appUserID];
}

- (void)setMparticleID:(nullable NSString *)mparticleID {
    [self.subscriberAttributesManager setMparticleID:mparticleID appUserID:self.appUserID];
}

- (void)setOnesignalID:(nullable NSString *)onesignalID {
    [self.subscriberAttributesManager setOnesignalID:onesignalID appUserID:self.appUserID];
}

- (void)setMediaSource:(nullable NSString *)mediaSource {
    [self.subscriberAttributesManager setMediaSource:mediaSource appUserID:self.appUserID];
}

- (void)setCampaign:(nullable NSString *)campaign {
    [self.subscriberAttributesManager setCampaign:campaign appUserID:self.appUserID];
}

- (void)setAdGroup:(nullable NSString *)adGroup {
    [self.subscriberAttributesManager setAdGroup:adGroup appUserID:self.appUserID];
}

- (void)setAd:(nullable NSString *)ad {
    [self.subscriberAttributesManager setAd:ad appUserID:self.appUserID];
}

- (void)setKeyword:(nullable NSString *)keyword {
    [self.subscriberAttributesManager setKeyword:keyword appUserID:self.appUserID];
}

- (void)setCreative:(nullable NSString *)creative {
    [self.subscriberAttributesManager setCreative:creative appUserID:self.appUserID];
}

- (void)collectDeviceIdentifiers {
    [self.subscriberAttributesManager collectDeviceIdentifiersForAppUserID:self.appUserID];
}

#pragma mark - Private Methods

- (void)applicationDidBecomeActive:(__unused NSNotification *)notif {
    [RCLog debug:[NSString stringWithFormat:@"%@", RCStrings.configure.application_active]];
    [self updateAllCachesIfNeeded];
    [self syncSubscriberAttributesIfNeeded];
    [self postAppleSearchAddsAttributionCollectionIfNeeded];
}

- (void)applicationWillResignActive:(__unused NSNotification *)notif {
    [self syncSubscriberAttributesIfNeeded];
}

- (void)updateAllCachesIfNeeded {
    [self.systemInfo isApplicationBackgroundedWithCompletion:^(BOOL isAppBackgrounded) {
        [self.purchaserInfoManager fetchAndCachePurchaserInfoIfStaleWithAppUserID:self.appUserID
                                                                isAppBackgrounded:isAppBackgrounded
                                                                       completion:nil];
        if ([self.deviceCache isOfferingsCacheStaleWithIsAppBackgrounded:isAppBackgrounded]) {
            [RCLog debug:[NSString stringWithFormat:@"Offerings cache is stale, updating caches"]];
            [self.offeringsManager updateOfferingsCacheWithAppUserID:self.appUserID
                                                   isAppBackgrounded:isAppBackgrounded
                                                          completion:nil];
        }
    }];
}

- (void)updateAllCachesWithCompletionBlock:(nullable RCReceivePurchaserInfoBlock)completion {
    [self.systemInfo isApplicationBackgroundedWithCompletion:^(BOOL isAppBackgrounded) {
        [self.purchaserInfoManager fetchAndCachePurchaserInfoWithAppUserID:self.appUserID
                                                         isAppBackgrounded:isAppBackgrounded
                                                                completion:completion];
        [self.offeringsManager updateOfferingsCacheWithAppUserID:self.appUserID
                                               isAppBackgrounded:isAppBackgrounded
                                                      completion:nil];
    }];
}

- (void)offeringsWithCompletionBlock:(RCReceiveOfferingsBlock)completion {
    [self.offeringsManager offeringsWithAppUserID:self.appUserID
                                  completionBlock:completion];
}

// todo: move to PurchasesManager
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
        } else if ([error.userInfo[RCErrorDetails.RCFinishableKey] boolValue]) {
            CALL_IF_SET_ON_SAME_THREAD(completion, transaction, nil, error, false);
            if (self.finishTransactions) {
                [self.storeKitWrapper finishTransaction:transaction];
            }
        } else if (![error.userInfo[RCErrorDetails.RCFinishableKey] boolValue]) {
            CALL_IF_SET_ON_SAME_THREAD(completion, transaction, nil, error, false);
        } else {
            [RCLog error:[NSString stringWithFormat:@"%@", RCStrings.receipt.unknown_backend_error]];
            CALL_IF_SET_ON_SAME_THREAD(completion, transaction, nil, error, false);
        }
    }];
}

// todo: move to PurchasesManager if viable, new class otherwise
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

// TODO: move to new class PurchasesManager
- (nullable RCPurchaseCompletedBlock)getAndRemovePurchaseCompletedBlockFor:(SKPaymentTransaction *)transaction {
    RCPurchaseCompletedBlock completion = nil;
    NSString * _Nullable productIdentifier = transaction.rc_productIdentifier;
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
    // todo: remove it from the protocol if it's entirely unused
}

- (BOOL)storeKitWrapper:(nonnull RCStoreKitWrapper *)storeKitWrapper
  shouldAddStorePayment:(nonnull SKPayment *)payment
             forProduct:(nonnull SKProduct *)product {
    [self.productsManager cacheProduct:product];

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

// todo: move to PurchasesManager (or find better name, since this is the exact opposite of a purchase)
- (void)                   storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
didRevokeEntitlementsForProductIdentifiers:(NSArray<NSString *> *)productIdentifiers
API_AVAILABLE(ios(14.0), macos(11.0), tvos(14.0), watchos(7.0)) {
    [RCLog debug:[NSString stringWithFormat:RCStrings.purchase.entitlements_revoked_syncing_purchases,
                  productIdentifiers]];
    [self syncPurchasesWithCompletionBlock:^(RCPurchaserInfo * _Nullable purchaserInfo, NSError * _Nullable error) {
        [RCLog debug:[NSString stringWithFormat:@"%@", RCStrings.purchase.purchases_synced]];
    }];
}

// todo: move to PurchasesManager (or find better name, since this is the exact opposite of a purchase)
- (void)handlePurchasedTransaction:(SKPaymentTransaction *)transaction {
    [self.receiptFetcher receiptDataWithRefreshPolicy:RCReceiptRefreshPolicyOnlyIfEmpty
                                           completion:^(NSData * _Nullable data) {
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

// todo: move to PurchasesManager (or find better name, since this is the exact opposite of a purchase)
- (void)fetchProductsAndPostReceiptWithTransaction:(SKPaymentTransaction *)transaction data:(NSData *)data {
    NSString * _Nullable productIdentifier = transaction.rc_productIdentifier;
    if (productIdentifier) {
        [self productsWithIdentifiers:@[productIdentifier]
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

// todo: move to PurchasesManager
- (void)postReceiptWithTransaction:(SKPaymentTransaction *)transaction
                              data:(NSData *)data
                          products:(NSArray<SKProduct *> *)products {
    SKProduct *product = products.lastObject;
    RCSubscriberAttributeDict subscriberAttributes = self.unsyncedAttributesByKey;
    RCProductInfo *productInfo = nil;
    NSString *presentedOffering = nil;
    if (product) {
        RCProductInfoExtractor *productInfoExtractor = [[RCProductInfoExtractor alloc] init];
        productInfo = [productInfoExtractor extractInfoFromSKProduct:product];

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

#pragma MARK: RCPurchaserInfoManagerDelegate
- (void)purchaserInfoManagerDidReceiveUpdatedPurchaserInfo:(RCPurchaserInfo *)purchaserInfo {
    if (self.delegate && [self.delegate respondsToSelector:@selector(purchases:didReceiveUpdatedPurchaserInfo:)]) {
        [self.delegate purchases:self didReceiveUpdatedPurchaserInfo:purchaserInfo];
    }
}

@end

