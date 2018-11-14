//
//  RCPurchases.h
//  Purchases
//
//  Created by Jacob Eiting on 9/29/17.
//  Copyright © 2018 RevenueCat, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKProduct, SKPayment, SKPaymentTransaction, RCPurchaserInfo, RCIntroEligibility, RCEntitlement;
@protocol RCPurchasesDelegate;

NS_ASSUME_NONNULL_BEGIN

typedef void (^RCDeferredPromotionalPurchaseBlock)(void);
typedef void (^RCReceiveIntroEligibilityBlock)(NSDictionary<NSString *, RCIntroEligibility *> *);
typedef void (^RCReceiveEntitlementsBlock)(NSDictionary<NSString *,RCEntitlement *> *);

/**
 @typedef RCAttributionNetwork
 @brief Enum of supported attribution networks
 @constant RCAttributionNetworkAppleSearchAds Apple's search ads
 @constant RCAttributionNetworkAppsFlyer AppsFlyer https://www.appsflyer.com/
 @constant RCAttributionNetworkAdjust Adjust https://www.adjust.com/
 */
typedef NS_ENUM(NSInteger, RCAttributionNetwork) {
    RCAttributionNetworkAppleSearchAds = 0,
    RCAttributionNetworkAdjust,
    RCAttributionNetworkAppsFlyer,
    RCAttributionNetworkBranch
};

/**
 `RCPurchases` is the entry point for Purchases.framework. It should be instantiated as soon as your app has a unique user id for your user. This can be when a user logs in if you have accounts or on launch if you can generate a random user identifier.

 @warning Only one instance of RCPurchases should be instantiated at a time! Use a configure method to let the framework handle the singleton instance for you.
 */
@interface RCPurchases : NSObject

/**
 Configures an instance of the Purchases SDK with a specified API key. The instance will be set as a singleton. You should access the singleton instance using [RCPurchases sharedPurchases]

 @note Use this initializer if your app does not have an account system. `RCPurchases` will generate a unique identifier for the current device and persist it to `NSUserDefaults`. This also affects the behavior of `restoreTransactionsForAppStoreAccount`.

 @param APIKey The API Key generated for your app from https://app.revenuecat.com/

 @return An instantiated `RCPurchases` object that has been set as a singleton.
 */
+ (instancetype)configureWithAPIKey:(NSString *)APIKey;

/**
 Configures an instance of the Purchases SDK with a specified API key and app user ID. The instance will be set as a singleton. You should access the singleton instance using [RCPurchases sharedPurchases]

 @note Best practice is to use a salted hash of your unique app user ids.

 @warning Use this initializer if you have your own user identifiers that you manage.

 @param APIKey The API Key generated for your app from https://app.revenuecat.com/

 @param appUserID The unique app user id for this user. This user id will allow users to share their purchases and subscriptions across devices. Pass nil if you want `RCPurchases` to generate this for you.

 @return An instantiated `RCPurchases` object that has been set as a singleton.
 */
+ (instancetype)configureWithAPIKey:(NSString *)APIKey appUserID:(NSString * _Nullable)appUserID;

/**
 Configures an instance of the Purchases SDK with object with a custom userDefaults. Use this constructor if you want to sync status across a shared container, such as between a host app and an extension. The instance of the Purchases SDK will be set as a singleton. You should access the singleton instance using [RCPurchases sharedPurchases]

 @param APIKey The API Key generated for your app from https://app.revenuecat.com/

 @param appUserID The unique app user id for this user. This user id will allow users to share their purchases and subscriptions across devices. Pass nil if you want `RCPurchases` to generate this for you.

 @param userDefaults Custom userDefaults to use

 @return An instantiated `RCPurchases` object that has been set as a singleton.
 */
+ (instancetype)configureWithAPIKey:(NSString *)APIKey
                          appUserID:(NSString * _Nullable)appUserID
                       userDefaults:(NSUserDefaults * _Nullable)userDefaults;

/**
 @return A singleton `RCPurchases` object. Call this after a configure method to access the singleton.
 */
+ (instancetype)sharedPurchases;

/**
 Sets an instance of the Purchases SDK as a singleton. The configure methods call this internally so it's preferably to set the default instance through a configure method. Use this method only if you want to override what the configure methods are doing.
 */
+ (void)setDefaultInstance:(RCPurchases *)instance;

/**
 Initializes an `RCPurchases` object with specified API key.

 @note Use this initializer if your app does not have an account system. `RCPurchases` will generate a unique identifier for the current device and persist it to `NSUserDefaults`. This also affects the behavior of `restoreTransactionsForAppStoreAccount`.

 @param APIKey The API Key generated for your app from https://app.revenuecat.com/

 @return An instantiated `RCPurchases` object
 */
- (instancetype)initWithAPIKey:(NSString *)APIKey;

/**
 Initializes an `RCPurchases` object with specified API key and app user ID.

 @note Best practice is to use a salted hash of your unique app user ids.

 @warning Use this initializer if you have your own user identifiers that you manage.

 @param APIKey The API Key generated for your app from https://app.revenuecat.com/

 @param appUserID The unique app user id for this user. This user id will allow users to share their purchases and subscriptions across devices. Pass nil if you want `RCPurchases` to generate this for you.

 @return An instantiated `RCPurchases` object
 */
- (instancetype)initWithAPIKey:(NSString *)APIKey
                     appUserID:(NSString * _Nullable)appUserID;

/**
 Initializes an `RCPurchases` object with a custom userDefaults. Use this constructor if you want to sync status across a shared container, such as between a host app and an extension.

 @param APIKey The API Key generated for your app from https://app.revenuecat.com/

 @param appUserID The unique app user id for this user. This user id will allow users to share their purchases and subscriptions across devices. Pass nil if you want `RCPurchases` to generate this for you.

 @param userDefaults Custom userDefaults to use

 @return An instantiated `RCPurchases` object
 */
- (instancetype)initWithAPIKey:(NSString *)APIKey
                     appUserID:(NSString * _Nullable)appUserID
                  userDefaults:(NSUserDefaults * _Nullable)userDefaults;

/// The `appUserID` used by `RCPurchases`. If not passed on initialization this will be generated and cached by `RCPurchases`.
@property (nonatomic, readonly) NSString *appUserID;

/** Set this to true if you are passing in an appUserID but it is anonymous, this is true by default if you didn't pass an appUserID
 If a user tries to purchase a product that is active on the current app store account, we will treat it as a restore and alias
 the new ID with the previous id.
 */
@property (nonatomic) BOOL isUsingAnonymousID;

/// Default to YES, set this to NO if you are finishing transactions with your own StoreKit queue listener
@property (nonatomic) BOOL finishTransactions;

/**
 Send your attribution data to RevenueCat so you can track the revenue generated by your different campaigns.

 @param data Dictionary provided by the network. See https://docs.revenuecat.com/docs/attribution
 @param network Enum for the network the data is coming from, see `RCAttributionNetwork` for supported networks
 */
- (void)addAttributionData:(NSDictionary *)data
               fromNetwork:(RCAttributionNetwork)network;
/**
 Delegate for `RCPurchases` instance. The delegate is responsible for handling completed purchases and updated purchaser information.

 @note `RCPurchases` will not listen for any purchases until the delegate is set. This prevents transactions from being processed before your app is ready to handle them.
 */
@property (nonatomic, weak) id<RCPurchasesDelegate> _Nullable delegate;

/**
 Fetch the configured entitlements for this user. Entitlements allows you to configure your in-app products via RevenueCat
 and greatly simplifies management. See the guide (https://docs.revenuecat.com/v1.0/docs/entitlements) for more info.

 Entitlements will be fetched and cached on instantiation so that, by the time they are needed, your prices are
 loaded for your purchase flow. Time is money.

 @param completion A completion block called when entitlements is available. Called immediately if entitlements are cached. Entitlements can be nil if an error occurred.
 */
- (void)entitlements:(void (^)(NSDictionary<NSString *, RCEntitlement *> * _Nullable))completion;

/**
 Fetches the `SKProducts` for your IAPs for given `productIdentifiers`. Use this method if you aren't using `-entitlements:`.
 You should use entitlements though.

 @note `completion` may be called without `SKProduct`s that you are expecting. This is usually caused by iTunesConnect configuration errors. Ensure your IAPs have the "Ready to Submit" status in iTunesConnect. Also ensure that you have an active developer program subscription and you have signed the latest paid application agreements.

 @param productIdentifiers A set of product identifiers for in app purchases setup via iTunesConnect. This should be either hard coded in your application, from a file, or from a custom endpoint if you want to be able to deploy new IAPs without an app update.
 @param completion An @escaping callback that is called with the loaded products. If the fetch fails for any reason it will return an empty array.
 */
- (void)productsWithIdentifiers:(NSArray<NSString *> *)productIdentifiers
                     completion:(void (^)(NSArray<SKProduct *>* products))completion;

/**
 Purchase the passed `SKProduct`.

 Call this method when a user has decided to purchase a product. Only call this in direct response to user input.

 From here `Purhases` will handle the purchase with `StoreKit` and call `purchases:completedTransaction:withUpdatedInfo:` or `purchases:failedTransaction:withReason:` on the `RCPurchases` `delegate` object.

 @note You do not need to finish the transaction yourself in the delegate, Purchases will handle this for you.

 @param product The `SKProduct` the user intends to purchase
 */
- (void)makePurchase:(SKProduct *)product;

/**
 This method will post all purchases associated with the current App Store account to RevenueCat and become associated with the current `appUserID`. If the receipt is being used by an existing user, the current `appUserID` will be aliased together with the `appUserID` of the existing user. Going forward, either `appUserID` will be able to reference the same user.

 You shouldn't use this method if you have your own account system. In that case "restoration" is provided by your app passing
 the same `appUserId` used to purchase originally.

 Triggers `-purchases:receivedUpdatedPurchaserInfo:` delegate method to be called.

 @note This may force your users to enter the App Store password so should only be performed on request of the user. Typically with a button in settings or near your purchase UI.
 */
- (void)restoreTransactionsForAppStoreAccount;

/**
 Computes whether or not a user is eligible for the introductory pricing period of a given product. You should use this method to determine whether or not you show the user the normal product price or the introductory price. This also applies to trials (trials are considered a type of introductory pricing).

 @note If you have multiple subscription groups you will need to specify which products belong to which subscription groups on https://app.revenuecat.com/. If RevenueCat can't definitively compute the eligibilty, most likely because of missing group information, it will return `RCIntroEligibilityStatusUnknown`. The best course of action on unknown status is to display the non-intro pricing, to not create a misleading situation.

 @param productIdentifiers Array of product identifiers for which you want to compute eligibility
 @param receiveEligibility A block that receives a dictionary of product_id -> `RCIntroEligibility`.
*/
- (void)checkTrialOrIntroductoryPriceEligibility:(NSArray<NSString *> *)productIdentifiers
                                      completion:(RCReceiveIntroEligibilityBlock)receiveEligibility;

/**
 Reads the App Store receipt and reads the original application version. Use this if RCPurchaserInfo.originalApplicationVersion is nil.
 Triggers purchases:receivedUpdatedPurchaserInfo: delegate method to be called;
 */
- (void)updateOriginalApplicationVersion;

/**
 Forces a refresh of the purchaser info. This will happen automatically in most cases and shouldn't be called.
 Triggers purchases:receivedUpdatedPurchaserInfo: delegate method to be called;
 */
- (void)updatePurchaserInfo;


/**
 This version of the Purchases framework
*/
+ (NSString *)frameworkVersion;

/**
 This function will alias two appUserIDs together.
 @param alias The new appUserID that should be linked to the currently identified appUserID
 */
- (void)createAlias:(NSString *)alias;

/**
 This function will alias two appUserIDs together.
 @param alias The new appUserID that should be linked to the currently identified appUserID
 @param completion An optional completion block called when the aliasing has been successful. This completion block will receive an error if there's been one.
 */
- (void)createAlias:(NSString *)alias completion:(void (^)(NSError * _Nullable error))completion;

/**
 This function will identify the current user with an appUserID. Tipically this would be used after a log out to identify a new user without calling configure
 @param appUserID The appUserID that should be linked to the currently user
 */
- (void)identify:(NSString * _Nullable)appUserID;

/**
 * Resets the Purchases client clearing the save appUserID. This will generate a random user id and save it in the cache.
 */
- (void) reset;
    
@end

/**
 Delegate for `RCPurchases` responsible for handling updating your app's state in response to completed purchases.

 @note Delegate methods can be called at any time after the `delegate` is set, not just in response to `makePurchase:` calls. Ensure your app is capable of handling completed transactions anytime `delegate` is set.
 */
@protocol RCPurchasesDelegate <NSObject>
@required

/**
 Called when a transaction has been succesfully posted to the backend. This will be called in response to `makePurchase:` call but can also occur when a subscription renews.

 @param purchases Related `RCPurchases` object
 @param transaction The transaction that was approved by `StoreKit` and verified by the backend
 @param purchaserInfo The updated purchaser info returned from the backend. The new transaction may have had an effect on expiration dates and purchased products. Use this object to up-date your app state.

 */
- (void)purchases:(RCPurchases *)purchases completedTransaction:(SKPaymentTransaction *)transaction
  withUpdatedInfo:(RCPurchaserInfo *)purchaserInfo;

/**
 Called when a `transaction` fails to complete a purchase with `StoreKit` or fails to be posted to the backend. The `localizedDescription` of `failureReason` will contain a message that may be useful for displaying to the user. Be sure to dismiss any purchasing UI if this method is called. This method can also be called at any time but outside of a purchasing context there often isn't much to do.

 @param purchases Related `RCPurchases` object
 @param transaction The transaction that failed to complete
 @param failureReason `NSError` containing the reason for the failure

 */
- (void)purchases:(RCPurchases *)purchases failedTransaction:(SKPaymentTransaction *)transaction withReason:(NSError *)failureReason;

/**
 Called whenever `RCPurchases` receives an updated purchaser info outside of a purchase. This will happen periodically 
 throughout the life of the app (e.g. UIApplicationDidBecomeActive).

 @param purchases Related `RCPurchases` object
 @param purchaserInfo Updated `RCPurchaserInfo`
 */
- (void)purchases:(RCPurchases *)purchases receivedUpdatedPurchaserInfo:(RCPurchaserInfo *)purchaserInfo;

/**
 Called when restoring transactions has been completed successfully.

 @param purchases Related `RCPurchases` object
 @param purchaserInfo Updated `RCPurchaserInfo`
 */
- (void)purchases:(RCPurchases *)purchases restoredTransactionsWithPurchaserInfo:(RCPurchaserInfo *)purchaserInfo;

/**
 Called when restoring transactions has failed

 @param purchases Related `RCPurchases` object
 @param error The failure reason
 */
- (void)purchases:(RCPurchases *)purchases failedToRestoreTransactionsWithError:(NSError *)error;

/**
 Called whenever RCPurchases fails to fetch a purchaserInfo.
*/
- (void)purchases:(RCPurchases *)purchases failedToUpdatePurchaserInfoWithError:(NSError *)error;

@optional

/**
 Called when a user initiates a promotional in-app purchase from the App Store. Use this method to tell `RCPurchases` if your app is able to handle a purchase at the current time. If yes, return true and `RCPurchases` will initiate a purchase and will finish with one of the appropriate `RCPurchasesDelegate` methods. If the app is not in a state to make a purchase: cache the defermentBlock, return no, then call the defermentBlock when the app is ready to make the promotional purchase. If the purchase should never be made, do not cache the defermentBlock and return `NO`. The default return value is `NO`, if you don't override this delegate method, `RCPurchases` will not proceed with promotional purchases.
 
 @param product `SKProduct` the product that was selected from the app store
 */
- (BOOL)purchases:(RCPurchases *)purchases shouldPurchasePromoProduct:(SKProduct *)product defermentBlock:(RCDeferredPromotionalPurchaseBlock)makeDeferredPurchase;

@end

NS_ASSUME_NONNULL_END
