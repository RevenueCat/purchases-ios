//
//  RCPurchases.h
//  Purchases
//
//  Created by Jacob Eiting on 9/29/17.
//  Copyright © 2017 RevenueCat, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKProduct, SKPayment, SKPaymentTransaction, RCPurchaserInfo, RCIntroEligibility;
@protocol RCPurchasesDelegate;

NS_ASSUME_NONNULL_BEGIN

typedef void (^RCDeferredPromotionalPurchaseBlock)(void);
typedef void (^RCReceiveIntroEligibilityBlock)(NSDictionary<NSString *, RCIntroEligibility *> *);

/**
 `RCPurchases` is the entry point for Purchases.framework. It should be instantiated as soon as your app has a unique user id for your user. This can be when a user logs in if you have accounts or on launch if you can generate a random user identifier.
 */
@interface RCPurchases : NSObject

/**
 Initializes an `RCPurchases` object with specified API key.

 @note Use this initializer if your app does not have an account system. `Purchases` will generate a unique identifier for the current device and persist it to `NSUserDefaults`.

 @param APIKey The API Key generated for your app from https://www.revenuecat.com/

 @return An instantiated `RCPurchases` object
 */
- (instancetype _Nullable)initWithAPIKey:(NSString *)APIKey;

/**
 Initializes an `RCPurchases` object with specified API key and app user ID.

 @note Best practice is to use a salted hash of your unique app user ids for improved privacy.

 @warning Use this initializer if you have your own user identifiers that you manage, such as in the case that you have an account system that you manage.

 @param APIKey The API Key generated for your app from https://www.revenuecat.com/

 @param appUserID The unique app user id for this user. This user id will allow users to share their purchases and subscriptions across devices. Pass nil if you want `RCPurchases` to generate this for you.

 @return An instantiated `RCPurchases` object
 */
- (instancetype _Nullable)initWithAPIKey:(NSString *)APIKey
                               appUserID:(NSString * _Nullable)appUserID;

/**
 Initializes an `RCPurchases` object with a custom userDefaults. Use this contructor if you want to sync status across
 a shared container, such as between a host app and an extension.

 @param APIKey The API Key generated for your app from https://www.revenuecat.com/

 @param appUserID The unique app user id for this user. This user id will allow users to share their purchases and subscriptions across devices. Pass nil if you want `RCPurchases` to generate this for you.

 @return An instantiated `RCPurchases` object
 */

- (instancetype _Nullable)initWithAPIKey:(NSString *)APIKey
                               appUserID:(NSString * _Nullable)appUserID
                            userDefaults:(NSUserDefaults *)userDefaults;

/// The `appUserID` used by `RCPurchases`. If not passed on initialization this will be generated and cached by `RCPurchases`.
@property (nonatomic, readonly) NSString *appUserID;

/**
 Delegate for `RCPurchases` instance. Object is responsible for handling completed purchases and updated subscription information.

 @note `RCPurchases` will not listen for any `SKTransactions` until the delegate is set. This prevents `SKTransactions` from being processed before your app is ready to handle them.
 */
@property (nonatomic, weak) id<RCPurchasesDelegate> _Nullable delegate;

/**
 Fetches the `SKProducts` for your IAPs for given `productIdentifiers`.

 @note You may wish to do this soon after app initialization and store the result to speed up your in app purchase experience. Slow purchase screens lead to decreased conversions.

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

 Triggers purchases:receivedUpdatedPurchaserInfo: delegate method to be called.

 @note This may force your users to enter the App Store password so should only be performed on request of the user. Typically with a button in settings or near your purchase UI.
 */
- (void)restoreTransactionsForAppStoreAccount;

/**
 Fetches the latest purchaser info from the backend. This will happen periodically on `applicationDidResumeActive:` and will trigger the delegate method `purchases:receivedUpdatedPurchaserInfo:`. You can use this method if you'd like to refresh the purchaser info manually. Triggers purchases:receivedUpdatedPurchaserInfo: delegate method to be called.
 */
- (void)updatePurchaserInfo;

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
 This version of the Purchases framework
*/
+ (NSString *)frameworkVersion;

@end

/**
 Delegate for `RCPurchases` responsible for handling updating your app's state in response to completed purchases.

 @note Delegate methods can be called at any time after the `delegate` is set, not just in response to `makePurchase:` calls. Ensure your app is capable of handling completed transactions anytime `delegate` is set.
 */
@protocol RCPurchasesDelegate
@required
/**
 Called when a transaction has been succesfully posted to the backend. This will be called in response to `makePurchase:` call but can also occur at other times, especially when dealing with subscriptions.

 @param purchases Related `RCPurchases` object
 @param transaction The transaction that was approved by `StoreKit` and verified by the backend
 @param purchaserInfo The updated purchaser info returned from the backend. The new transaction may have had an effect on expiration dates and purchased products. Use this object to up-date your app state.

 */
- (void)purchases:(RCPurchases *)purchases completedTransaction:(SKPaymentTransaction *)transaction
  withUpdatedInfo:(RCPurchaserInfo *)purchaserInfo;

/**
 Called when a `transaction` fails to complete purchase with `StoreKit` or fails to be posted to the backend. The `localizedDescription` of `failureReason` will contain a message that may be useful for displaying to the user. Be sure to dismiss any purchasing UI if this method is called. This method can also be called at any time but outside of a purchasing context there often isn't much to do.

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
