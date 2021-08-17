//
//  RCPurchases.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

@import PurchasesCoreSwift;

#import "RCPurchases+Protected.h"
#import "RCPurchases.h"

@interface RCPurchases () <RCPurchaserInfoManagerDelegate, RCPurchasesOrchestratorDelegate>

/**
 * Completion block for calls that send back receipt data
 */
typedef void (^RCReceiveReceiptDataBlock)(NSData *);

typedef NSDictionary<NSString *, RCSubscriberAttribute *> *RCSubscriberAttributeDict;

@property (nonatomic) RCStoreKitRequestFetcher *requestFetcher;
@property (nonatomic) RCProductsManager *productsManager;
@property (nonatomic) RCReceiptFetcher *receiptFetcher;
@property (nonatomic) RCBackend *backend;
@property (nonatomic) RCStoreKitWrapper *storeKitWrapper;
@property (nonatomic) NSNotificationCenter *notificationCenter;
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
@property (nonatomic) RCPurchasesOrchestrator *purchasesOrchestrator;

@end

static RCPurchases *_sharedPurchases = nil;

@implementation RCPurchases

#pragma mark - Configuration

- (BOOL)allowSharingAppStoreAccount {
    return self.purchasesOrchestrator.allowSharingAppStoreAccount;
}

- (void)setAllowSharingAppStoreAccount:(BOOL)allow {
    self.purchasesOrchestrator.allowSharingAppStoreAccount = allow;
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
    RCIdentityManager *identityManager = [[RCIdentityManager alloc] initWithDeviceCache:deviceCache
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
    RCPurchasesOrchestrator *purchasesOrchestrator = [[RCPurchasesOrchestrator alloc]
                                                      initWithProductsManager:productsManager
                                                      storeKitWrapper:storeKitWrapper
                                                      systemInfo:systemInfo
                                                      subscriberAttributesManager:subscriberAttributesManager
                                                      operationDispatcher:operationDispatcher
                                                      receiptFetcher:receiptFetcher
                                                      purchaserInfoManager:purchaserInfoManager
                                                      backend:backend
                                                      identityManager:identityManager
                                                      receiptParser:receiptParser
                                                      deviceCache:deviceCache];
    purchasesOrchestrator.maybeDelegate = self;
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
                  offeringsManager:offeringsManager
             purchasesOrchestrator:purchasesOrchestrator];
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
                 offeringsManager:(RCOfferingsManager *)offeringsManager
            purchasesOrchestrator:(RCPurchasesOrchestrator *)purchasesOrchestrator {
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

        self.systemInfo = systemInfo;
        self.subscriberAttributesManager = subscriberAttributesManager;
        self.operationDispatcher = operationDispatcher;
        self.introEligibilityCalculator = introEligibilityCalculator;
        self.receiptParser = receiptParser;
        self.purchaserInfoManager = purchaserInfoManager;
        self.productsManager = productsManager;
        self.offeringsManager = offeringsManager;
        self.purchasesOrchestrator = purchasesOrchestrator;

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
        self.storeKitWrapper.delegate = purchasesOrchestrator;

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
    return [self.identityManager maybeCurrentAppUserID];
}

- (BOOL)isAnonymous {
    return [self.identityManager currentUserIsAnonymous];
}

- (void)createAlias:(NSString *)alias completionBlock:(nullable RCReceivePurchaserInfoBlock)completion {
    if ([alias isEqualToString:self.identityManager.maybeCurrentAppUserID]) {
        [self purchaserInfoWithCompletionBlock:completion];
    } else {
        [self.identityManager createAliasForAppUserID:alias completion:^(NSError *_Nullable error) {
            if (error == nil) {
                [self updateAllCachesWithCompletionBlock:completion];
            } else {
                if (completion) {
                    [self.operationDispatcher dispatchOnMainThread:^{ completion(nil, error); }];
                }
            }
        }];
    }
}

- (void)identify:(NSString *)appUserID completionBlock:(nullable RCReceivePurchaserInfoBlock)completion {
    if ([appUserID isEqualToString:self.identityManager.maybeCurrentAppUserID]) {
        [self purchaserInfoWithCompletionBlock:completion];
    } else {
        [self.identityManager identifyAppUserID:appUserID completion:^(NSError *error) {
            if (error == nil) {
                [self updateAllCachesWithCompletionBlock:completion];
            } else {
                if (completion) {
                    [self.operationDispatcher dispatchOnMainThread:^{ completion(nil, error); }];
                }
            }
        }];

    }
}

- (void)  logIn:(NSString *)appUserID
completionBlock:(void (^)(RCPurchaserInfo * _Nullable purchaserInfo, BOOL created, NSError * _Nullable error))completion {
    [self.identityManager logInAppUserID:appUserID completion:^(RCPurchaserInfo *purchaserInfo,
                                                                    BOOL created,
                                                                    NSError * _Nullable error) {
        [self.operationDispatcher dispatchOnMainThread:^{ completion(purchaserInfo, created, error); }];

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
            if (completion) {
                [self.operationDispatcher dispatchOnMainThread:^{ completion(nil, error); }];
            }
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
    [self.purchasesOrchestrator productsWithIdentifiers:productIdentifiers completion:completion];
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
    [self.purchasesOrchestrator purchaseProduct:product
                                        payment:payment
                    presentedOfferingIdentifier:presentedOfferingIdentifier
                                     completion:completion];
}

- (void)syncPurchasesWithCompletionBlock:(nullable RCReceivePurchaserInfoBlock)completion {
    [self.purchasesOrchestrator syncPurchasesWithCompletion:completion];
}

- (void)restoreTransactionsWithCompletionBlock:(nullable RCReceivePurchaserInfoBlock)completion {
    [self.purchasesOrchestrator restoreTransactionsWithCompletion:completion];
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
                        [self.operationDispatcher dispatchOnMainThread:^{ receiveEligibility(convertedEligibility); }];
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
                            [self.operationDispatcher dispatchOnMainThread:^{ receiveEligibility(result); }];
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
                    [self.operationDispatcher dispatchOnMainThread:^{ receiveEligibility(result); }];
                }];
            }
        } else {
            [self.backend getIntroEligibilityForAppUserID:self.appUserID
                                              receiptData:data
                                       productIdentifiers:productIdentifiers
                                               completion:^(NSDictionary<NSString *,RCIntroEligibility *> * _Nonnull result, NSError * _Nullable error) {
                [RCLog error:[NSString stringWithFormat:@"Unable to getIntroEligibilityForAppUserID: %@",
                              error.localizedDescription]];
                [self.operationDispatcher dispatchOnMainThread:^{ receiveEligibility(result); }];
            }];
        }
    }];
}

- (void)paymentDiscountForProductDiscount:(SKProductDiscount *)discount
                                  product:(SKProduct *)product
                               completion:(RCPaymentDiscountBlock)completion
API_AVAILABLE(ios(12.2), macos(10.14.4), watchos(6.2), macCatalyst(13.0), tvos(12.2)) {
    [self.purchasesOrchestrator paymentDiscountForProductDiscount:discount product:product completion:completion];
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

- (void)syncSubscriberAttributesIfNeeded {
    [self.operationDispatcher dispatchOnWorkerThreadWithRandomDelay:NO block:^{
        [self.subscriberAttributesManager syncAttributesForAllUsersWithCurrentAppUserID:self.appUserID];
    }];
}

// TODO make private after swift migration
- (void)markAttributesAsSyncedIfNeeded:(nullable RCSubscriberAttributeDict)syncedAttributes
                             appUserID:(NSString *)appUserID
                                 error:(nullable NSError *)error {
    if (error && !error.rc_successfullySynced) {
        return;
    }

    if (error.rc_subscriberAttributesErrors) {
        [RCLog error:[NSString stringWithFormat:RCStrings.attribution.subscriber_attributes_error,
                      error.rc_subscriberAttributesErrors]];
    }
    [self.subscriberAttributesManager markAttributesAsSynced:syncedAttributes appUserID:appUserID];
}

#pragma MARK: RCPurchaserInfoManagerDelegate
- (void)purchaserInfoManagerDidReceiveUpdatedPurchaserInfo:(RCPurchaserInfo *)purchaserInfo {
    if (self.delegate && [self.delegate respondsToSelector:@selector(purchases:didReceiveUpdatedPurchaserInfo:)]) {
        [self.delegate purchases:self didReceiveUpdatedPurchaserInfo:purchaserInfo];
    }
}

#pragma MARK: RCPurchasesOrchestratorDelegate
- (void)shouldPurchasePromoProduct:(SKProduct * _Nonnull)product
                    defermentBlock:(void (^ _Nonnull)(void (^ _Nonnull)(SKPaymentTransaction * _Nullable, RCPurchaserInfo * _Nullable, NSError * _Nullable, BOOL)))defermentBlock {
    if (self.delegate && [self.delegate respondsToSelector:@selector(purchases:shouldPurchasePromoProduct:defermentBlock:)]) {
        [self.delegate purchases:self shouldPurchasePromoProduct:product defermentBlock:defermentBlock];
    }
}

@end
