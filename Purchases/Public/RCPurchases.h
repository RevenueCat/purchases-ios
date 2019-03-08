//
//  RCPurchases.h
//  Purchases
//
//  Created by Jacob Eiting on 9/29/17.
//  Copyright © 2019 RevenueCat, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RCEntitlement.h"

@class SKProduct, SKPayment, SKPaymentTransaction, RCPurchaserInfo, RCIntroEligibility, RCEntitlement;
@protocol RCPurchasesDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 Completion block for calls that send back a `PurchaserInfo`
 */
typedef void (^RCReceivePurchaserInfoBlock)(RCPurchaserInfo * _Nullable, NSError * _Nullable) NS_SWIFT_NAME(Purchases.ReceivePurchaserInfoBlock);

/**
 Completion block for `checkTrialOrIntroductoryPriceEligibility:completionBlock:`
 */
typedef void (^RCReceiveIntroEligibilityBlock)(NSDictionary<NSString *, RCIntroEligibility *> *) NS_SWIFT_NAME(Purchases.ReceiveIntroEligibilityBlock);

/**
 Completion block for `entitlementsWithCompletionBlock:`
 */
typedef void (^RCReceiveEntitlementsBlock)(RCEntitlements * _Nullable, NSError * _Nullable) NS_SWIFT_NAME(Purchases.ReceiveEntitlementsBlock);

/**
 Completion block for `productsWithIdentifiers:completionBlock:`
 */
typedef void (^RCReceiveProductsBlock)(NSArray<SKProduct *> *) NS_SWIFT_NAME(Purchases.ReceiveProductsBlock);

/**
 Completion block for `makePurchase:withCompletionBlock:`
 */
typedef void (^RCPurchaseCompletedBlock)(SKPaymentTransaction * _Nullable, RCPurchaserInfo * _Nullable, NSError * _Nullable, BOOL userCancelled) NS_SWIFT_NAME(Purchases.PurchaseCompletedBlock);

/**
 Deferred block for `shouldPurchasePromoProduct:defermentBlock`
 */
typedef void (^RCDeferredPromotionalPurchaseBlock)(void);


/**
 @typedef RCAttributionNetwork
 @brief Enum of supported attribution networks
 @constant RCAttributionNetworkAppleSearchAds Apple's search ads
 @constant RCAttributionNetworkAppsFlyer AppsFlyer https://www.appsflyer.com/
 @constant RCAttributionNetworkAdjust Adjust https://www.adjust.com/
 @constant RCAttributionNetworkTenjin Tenjin https://www.tenjin.io/
 */
typedef NS_ENUM(NSInteger, RCAttributionNetwork) {
    /**
     Apple's search ads
     */
    RCAttributionNetworkAppleSearchAds = 0,
    /**
     Adjust https://www.adjust.com/
     */
    RCAttributionNetworkAdjust,
    /**
     AppsFlyer https://www.appsflyer.com/
     */
    RCAttributionNetworkAppsFlyer,
    /**
     Branch https://www.branch.io/
     */
    RCAttributionNetworkBranch,
    /**
     Tenjin https://www.tenjin.io/
     */
    RCAttributionNetworkTenjin
};

/**
 `RCPurchases` is the entry point for Purchases.framework. It should be instantiated as soon as your app has a unique user id for your user. This can be when a user logs in if you have accounts or on launch if you can generate a random user identifier.

 @warning Only one instance of RCPurchases should be instantiated at a time! Use a configure method to let the framework handle the singleton instance for you.
 */
NS_SWIFT_NAME(Purchases)
@interface RCPurchases : NSObject

/**
 Enable debug logging. Useful for debugging issues with the lovely team @RevenueCat
*/
@property (class, nonatomic, assign) BOOL debugLogsEnabled;

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
@property (class, nonatomic, readonly) RCPurchases *sharedPurchases;


#pragma mark Configuration

/** Set this to true if you are passing in an appUserID but it is anonymous, this is true by default if you didn't pass an appUserID
 If a user tries to purchase a product that is active on the current app store account, we will treat it as a restore and alias
 the new ID with the previous id.
 */
@property (nonatomic) BOOL allowSharingAppStoreAccount;

/// Default to YES, set this to NO if you are finishing transactions with your own StoreKit queue listener
@property (nonatomic) BOOL finishTransactions;

/// This version of the Purchases framework
+ (NSString *)frameworkVersion;

/// Delegate for `RCPurchases` instance. The delegate is responsible for handling promotional product purchases and changes to purchaser information.
@property (nonatomic, weak) id<RCPurchasesDelegate> _Nullable delegate;

#pragma mark Identity

/// The `appUserID` used by `RCPurchases`. If not passed on initialization this will be generated and cached by `RCPurchases`.
@property (nonatomic, readonly) NSString *appUserID;

/**
 This function will alias two appUserIDs together.
 @param alias The new appUserID that should be linked to the currently identified appUserID
 @param completion An optional completion block called when the aliasing has been successful. This completion block will receive an error if there's been one.
 */
- (void)createAlias:(NSString *)alias completionBlock:(RCReceivePurchaserInfoBlock _Nullable)completion
NS_SWIFT_NAME(createAlias(_:_:));

/**
 This function will identify the current user with an appUserID. Typically this would be used after a logout to identify a new user without calling configure
 @param appUserID The appUserID that should be linked to the currently user
 */
- (void)identify:(NSString * _Nullable)appUserID completionBlock:(RCReceivePurchaserInfoBlock _Nullable)completion
NS_SWIFT_NAME(identify(_:_:));

/**
 * Resets the Purchases client clearing the saved appUserID. This will generate a random user id and save it in the cache.
 */
- (void)resetWithCompletionBlock:(RCReceivePurchaserInfoBlock _Nullable)completion
NS_SWIFT_NAME(reset(_:));

#pragma mark Attribution

/**
 Send your attribution data to RevenueCat so you can track the revenue generated by your different campaigns.

 @param data Dictionary provided by the network. See https://docs.revenuecat.com/docs/attribution
 @param network Enum for the network the data is coming from, see `RCAttributionNetwork` for supported networks
 */
- (void)addAttributionData:(NSDictionary *)data
               fromNetwork:(RCAttributionNetwork)network;

#pragma mark Purchases

/**
 Get latest available purchaser info.
 
 @param completion A completion block called when purchaser info is available and not stale. Called immediately if purchaser info is cached. Purchaser info can be nil if an error occurred.
 */
- (void)purchaserInfoWithCompletionBlock:(RCReceivePurchaserInfoBlock)completion
NS_SWIFT_NAME(purchaserInfo(_:));

/**
 Fetch the configured entitlements for this user. Entitlements allows you to configure your in-app products via RevenueCat
 and greatly simplifies management. See the guide (https://docs.revenuecat.com/docs/entitlements) for more info.

 Entitlements will be fetched and cached on instantiation so that, by the time they are needed, your prices are
 loaded for your purchase flow. Time is money.

 @param completion A completion block called when entitlements is available. Called immediately if entitlements are cached. Entitlements can be nil if an error occurred.
 */
- (void)entitlementsWithCompletionBlock:(RCReceiveEntitlementsBlock)completion
NS_SWIFT_NAME(entitlements(_:));

/**
 Fetches the `SKProducts` for your IAPs for given `productIdentifiers`. Use this method if you aren't using `-entitlements:`.
 You should use entitlements though.

 @note `completion` may be called without `SKProduct`s that you are expecting. This is usually caused by iTunesConnect configuration errors. Ensure your IAPs have the "Ready to Submit" status in iTunesConnect. Also ensure that you have an active developer program subscription and you have signed the latest paid application agreements. If you're having trouble see: https://www.revenuecat.com/2018/10/11/configuring-in-app-products-is-hard

 @param productIdentifiers A set of product identifiers for in app purchases setup via iTunesConnect. This should be either hard coded in your application, from a file, or from a custom endpoint if you want to be able to deploy new IAPs without an app update.
 @param completion An @escaping callback that is called with the loaded products. If the fetch fails for any reason it will return an empty array.
 */
- (void)productsWithIdentifiers:(NSArray<NSString *> *)productIdentifiers
                     completionBlock:(RCReceiveProductsBlock)completion
NS_SWIFT_NAME(products(_:_:));

/**
 Purchase the passed `SKProduct`.
 
 Call this method when a user has decided to purchase a product. Only call this in direct response to user input.
 
 From here `Purchases` will handle the purchase with `StoreKit` and call the `RCPurchaseCompletedBlock`.
 
 @note You do not need to finish the transaction yourself in the completion callback, Purchases will handle this for you.
 
 @param product The `SKProduct` the user intends to purchase
 */
- (void)makePurchase:(SKProduct *)product withCompletionBlock:(RCPurchaseCompletedBlock)completion
NS_SWIFT_NAME(makePurchase(_:_:));

/**
 This method will post all purchases associated with the current App Store account to RevenueCat and become associated with the current `appUserID`. If the receipt is being used by an existing user, the current `appUserID` will be aliased together with the `appUserID` of the existing user. Going forward, either `appUserID` will be able to reference the same user.

 You shouldn't use this method if you have your own account system. In that case "restoration" is provided by your app passing
 the same `appUserId` used to purchase originally.

 @note This may force your users to enter the App Store password so should only be performed on request of the user. Typically with a button in settings or near your purchase UI.
 */
- (void)restoreTransactionsWithCompletionBlock:(RCReceivePurchaserInfoBlock _Nullable)completion
NS_SWIFT_NAME(restoreTransactions(_:));

/**
 Computes whether or not a user is eligible for the introductory pricing period of a given product. You should use this method to determine whether or not you show the user the normal product price or the introductory price. This also applies to trials (trials are considered a type of introductory pricing).

 @note If you have multiple subscription groups you will need to specify which products belong to which subscription groups on https://app.revenuecat.com/. If RevenueCat can't definitively compute the eligibilty, most likely because of missing group information, it will return `RCIntroEligibilityStatusUnknown`. The best course of action on unknown status is to display the non-intro pricing, to not create a misleading situation.

 @param productIdentifiers Array of product identifiers for which you want to compute eligibility
 @param receiveEligibility A block that receives a dictionary of product_id -> `RCIntroEligibility`.
*/
- (void)checkTrialOrIntroductoryPriceEligibility:(NSArray<NSString *> *)productIdentifiers
                                 completionBlock:(RCReceiveIntroEligibilityBlock)receiveEligibility;
    
@end

/**
 Delegate for `RCPurchases` responsible for handling updating your app's state in response to updated purchaser info or promotional product purchases.
 
 @note Delegate methods can be called at any time after the `delegate` is set, not just in response to `purchaserInfo:` calls. Ensure your app is capable of handling these calls at anytime if `delegate` is set.
 */
NS_SWIFT_NAME(PurchasesDelegate)
@protocol RCPurchasesDelegate <NSObject>
@optional

/**
 Called whenever `RCPurchases` receives updated purchaser info. This may happen periodically
 throughout the life of the app if new information becomes available (e.g. UIApplicationDidBecomeActive).
 
 @param purchases Related `RCPurchases` object
 @param purchaserInfo Updated `RCPurchaserInfo`
 */
- (void)purchases:(RCPurchases *)purchases didReceiveUpdatedPurchaserInfo:(RCPurchaserInfo *)purchaserInfo
NS_SWIFT_NAME(purchases(_:didReceiveUpdated:));

/**
 Called when a user initiates a promotional in-app purchase from the App Store. Use this method to tell `RCPurchases` if your app is able to handle a purchase at the current time. If yes, return true and `RCPurchases` will initiate a purchase and will finish with one of the appropriate `RCPurchasesDelegate` methods. If the app is not in a state to make a purchase: cache the defermentBlock, return no, then call the defermentBlock when the app is ready to make the promotional purchase. If the purchase should never be made, do not cache the defermentBlock and return `NO`. The default return value is `NO`, if you don't override this delegate method, `RCPurchases` will not proceed with promotional purchases.
 
 @param product `SKProduct` the product that was selected from the app store
 */
- (BOOL)purchases:(RCPurchases *)purchases shouldPurchasePromoProduct:(SKProduct *)product defermentBlock:(RCDeferredPromotionalPurchaseBlock)makeDeferredPurchase;

@end

NS_ASSUME_NONNULL_END
