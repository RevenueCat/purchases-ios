[![RevenueCat](https://s3.amazonaws.com/www.revenuecat.com/assets/images/logo_red200.png)](https://www.revenuecat.com)

[![Version](https://img.shields.io/cocoapods/v/Purchases.svg?style=flat)](https://cocoapods.org/pods/Purchases)
[![License](https://img.shields.io/cocoapods/l/Purchases.svg?style=flat)](http://cocoapods.org/pods/Purchases)

## Purchases.framework

*Purchases* is a client for the [RevenueCat](https://www.revenuecat.com/) subscription and purchase tracking system. It is an open source framework that provides a wrapper around `StoreKit` and the RevenueCat backend to make implementing in-app purchases in `Swift` or `Objective-C` easy.


## Features
|   | RevenueCat |
| --- | --- |
✅ | Server-side receipt validation
➡️ | [Webhooks](https://docs.revenuecat.com/docs/webhooks) - enhanced server-to-server communication with events for purchases, renewals, cancellations, and more   
🎯 | Subscription status tracking - know whether a user is subscribed whether they're on iOS, Android or web  
📊 | Analytics - automatic calculation of metrics like conversion, mrr, and churn  
📝 | [Online documentation](https://docs.revenuecat.com/docs) up to date  
🔀 | [Integrations](https://www.revenuecat.com/integrations) - over a dozen integrations to easily send purchase data where you need it  
💯 | Well maintained - [frequent releases](https://github.com/RevenueCat/purchases-ios/releases)  
📮 | Great support - [Help Center](https://docs.revenuecat.com/discuss)  
🤩 | Awesome [new features](https://trello.com/b/RZRnWRbI/revenuecat-product-roadmap)  


## Installation

*Purchases* is available through [CocoaPods](https://cocoapods.org/) and [Carthage](https://github.com/Carthage/Carthage)

### CocoaPods
```
pod "Purchases"
```

And then run:

```
pod install
```

### Carthage
```
github "revenuecat/purchases-ios"
```

And then run:

```
carthage update --no-use-binaries
```

## Getting Started
For more detailed information, you can view our complete documentation at [docs.revenuecat.com](https://docs.revenuecat.com/docs).

#### 1. Get a RevenueCat API key

Log in to the [RevenueCat dashboard](https://app.revenuecat.com) and obtain a free API key for your application.

#### 2. Initialize an `RCPurchases` object
> Don't forget to enable the In-App Purchase capability for your project under `Project Target -> Capabilities -> In-App Purchase`

You should only configure *Purchases* once (usually on app launch) as soon as your app has a unique user id for your user. This can be when a user logs in if you have accounts or on launch if you can generate a random user identifier. The same instance is shared throughout your app by accessing the `.shared` instance in the SDK.

Swift:
```swift
import Purchases

Purchases.debugLogsEnabled = true
Purchases.configure(withAPIKey: "my_api_key", appUserID: "my_app_user_id")
```

Obj-C:
```obj-c
#import "RCPurchases.h"

RCPurchases.debugLogsEnabled = YES;
[RCPurchases configureWithAPIKey:@"my_api_key" appUserID:@"my_app_user_id"];
```

#### 3. Displaying Available Products
*Purchases* will automatically fetch the latest *active* entitlements and get the product information from Apple or Google. This means when users launch your purchase screen, products will already be loaded.

Below is an example of fetching entitlements and launching an upsell screen.

Swift:
```swift
func displayUpsellScreen() {
    Purchases.shared.entitlements { (entitlements, error) in
        let vc = UpsellController()
        vc.entitlements = entitlements
        presentViewController(vc, animated: true, completion: nil)
    }
}
```

Obj-C
```obj-c
[[RCPurchases sharedPurchases] entitlementsWithCompletionBlock:^(RCEntitlements *entitlements, NSError *error) {
  UpsellViewController *vc = [[UpsellViewController alloc] init];
  vc.entitlements = entitlements;
  [self presentViewController:vc animated:YES completion:nil];
}];
```

#### 4. Make a purchase
When it comes time to make a purchase, *Purchases* has a simple method, `makePurchase`. The code sample below shows the process of purchasing a product and confirming it unlocks the "my_entitlement_identifier" content.

Swift:
```swift
Purchases.shared.makePurchase(product, { (transaction, purchaserInfo, error) in
    if let error = error {
        // Error making purchase
    } else if let purchaserInfo = purchaserInfo {
    
        if purchaserInfo.activeEntitlements.contains("my_entitlement_identifier") {
            // Unlock that great "pro" content
        }
        
    }
})
```

Obj-C:
```obj-c
[[RCPurchases sharedPurchases] makePurchase:product withCompletionBlock:^(SKPaymentTransaction *transaction, RCPurchaserInfo * purchaserInfo, NSError * error) {

    if ([purchaserInfo.activeEntitlements containsObject:@"my_entitlement_identifier"]) {
        // Unlock that great "pro" content.
    }
}];
```
>`makePurchase` handles the underlying framework interaction and automatically validates purchases with Apple through our secure servers. This helps reduce in-app purchase fraud and decreases the complexity of your app. Receipt tokens are stored remotely and always kept up-to-date.


#### 5. Get Subscription Status
*Purchases* makes it easy to check what active subscriptions the current user has. This can be done two ways within the `.purchaserInfo` method:
1. Checking active Entitlements - this lets you see what entitlements ([from RevenueCat dashboard](https://app.revenuecat.com)) are active for the user.
2. Checking the active subscriptions - this lets you see what product ids (from iTunes Connect or Play Store) are active for the user.

Swift:
```swift
Purchases.shared.purchaserInfo { (purchaserInfo, error) in
    if let error = error {
        // Error fetching entitlements
    } else if let purchaserInfo = purchaserInfo {

        // Option 1: Check if user has access to entitlement (from RevenueCat dashboard)
        if purchaserInfo.activeEntitlements.contains("my_entitlement_identifier") {
            // Grant user "pro" access
        }

        // Option 2: Check if user has active subscription (from App Store Connect or Play Store)
        if purchaserInfo.activeSubscriptions.contains("my_product_identifier") {
            // Grant user "pro" access
        }
    }
}
```

Obj-C:
```obj-c
[[RCPurchases sharedPurchases] purchaserInfoWithCompletionBlock:^(RCPurchaserInfo * purchaserInfo, NSError * error) {
        
    // Option 1: Check if user has access to entitlement (from RevenueCat dashboard)
    if ([purchaserInfo.activeEntitlements containsObject:@"my_entitlement_identifier"]) {
        // Grant user "pro" access
    }

    // Option 2: Check if user has active subscription (from App Store Connect or Play Store)
    if ([purchaserInfo.activeSubscriptions containsObject:@"my_product_identifier"]) {
    // Grant user "pro" access
    }
}];
```
>Since the SDK updates and caches the latest PurchaserInfo when the app becomes active, the completion block in `.purchaserInfo` won't need to make a network request in most cases.

### Restoring Purchases
Restoring purchases is a mechanism by which your user can restore their in-app purchases, reactivating any content that had previously been purchased from the same store account (Apple or Google).

If two different App User IDs try to restore transactions from the same underlying store account (Apple or Google) RevenueCat will create an alias between the two App User IDs and count them as the same user going forward.

This is a common if your app does not have accounts and is relying on RevenueCat's random App User IDs.

Swift:
```swift
Purchases.shared.restoreTransactions { (purchaserInfo, error) in
    //... check purchaserInfo to see if entitlement is now active
}
```

Obj-C:
```obj-c
[[RCPurchases sharedPurchases] restoreTransactionsWithCompletionBlock:^(RCPurchaserInfo * purchaserInfo, NSError * error) {
    //... check purchaserInfo to see if entitlement is now active
}];
```

**Restoring purchases for logged in users:**  
>If you've provided your own App User ID, calling restoreTransactions could alias the logged in user to another generated App User ID that has made a purchase on the same device.

**Allow Sharing App or Play Store Accounts**
>By default, RevenueCat will not let you reuse an App or Play Store account that already has an active subscription. If you set allowSharingAppStoreAccount = True the SDK will be permissive in accepting shared accounts, creating aliases as needed.

>By default allowSharingAppStoreAccount is True for RevenueCat random App User IDs but must be enabled manually if you want to allow permissive sharing for your own App User IDs.

## Debugging
You can enabled detailed debug logs by setting `debugLogsEnabled = true`. You can set this **before** you configure Purchases.

Swift:
```swift
Purchases.debugLogsEnabled = true
Purchases.configure(withAPIKey: "my_api_key", appUserID: "my_app_user_id")
```
Obj-C:
```obj-c
RCPurchases.debugLogsEnabled = YES;
[RCPurchases configureWithAPIKey:@"my_api_key" appUserID:@"my_app_user_id"];
```

**OS_ACTIVITY_MODE**
>On iOS, disabling `OS_ACTIVITY_MODE` in your XCode scheme will block debug logs from printing in the console. If you have debug logs enabled, but don't see any output, go to `Product -> Scheme -> Edit Scheme...` in Xcode and uncheck the `OS_ACTIVITY_MODE` environment variable.

Example output:
```
[Purchases] - DEBUG: Debug logging enabled.
[Purchases] - DEBUG: SDK Version - 2.0.0
[Purchases] - DEBUG: Initial App User ID - (null)
[Purchases] - DEBUG: GET /v1/subscribers/<APP_USER_ID>
[Purchases] - DEBUG: GET /v1/subscribers/<APP_USER_ID>/products
[Purchases] - DEBUG: No cached entitlements, fetching
[Purchases] - DEBUG: Vending purchaserInfo from cache
[Purchases] - DEBUG: applicationDidBecomeActive
[Purchases] - DEBUG: GET /v1/subscribers/<APP_USER_ID>/products 200
```

## Entitlements
An entitlement represents features or content that a user is "entitled" to. With Entitlements, you can set up your available in-app products remotely and control their availability without the need to update your app. For more information on configuring entitlements, look at our [entitlements documetation](https://docs.revenuecat.com/docs/entitlements).

## Sample App
We've added an example in this project showing a simple example using *Purchases* with the RevenueCat backend. Note that the pre-registered in app purchases in the demo apps are for illustration purposes only and may not be valid in App Store Connect. [Set up your own purchases](https://docs.revenuecat.com/docs/entitlements) with RevenueCat when running the example.

## Next Steps
- Head over to our **[online documentation](https://docs.revenuecat.com/docs)** for complete setup guides
- If you haven't already, make sure your products are configured correctly in the RevenueCat dashboard by checking out our [guide on entitlements](https://docs.revenuecat.com/docs/entitlements)
- If you want to use your own user identifiers, read about [setting app user ids](https://docs.revenuecat.com/docs/user-ids)
- If you're moving to RevenueCat from another system, see our guide on [migrating your existing subscriptions](https://docs.revenuecat.com/docs/migrating-existing-subscriptions)
- Once you're ready to test your integration, you can follow our guides on [testing purchases](https://docs.revenuecat.com/docs/testing-purchases)


## Reporting Issues
You can use Github Issues to report any bugs and issues with *Purchases*. Here is some advice for users that want to report an issue:

1. Make sure that you are using the latest version of *Purchases*. The issue that you are about to report may be already fixed in the latest master branch version: https://github.com/revenuecat/purchases-ios/tree/master.
2. Providing reproducible steps for the issue will shorten the time it takes for it to be fixed - a Gist is always welcomed!
3. Since some issues are Sandbox specific, specifying what environment you encountered the issue might help.
​

## Technical Support or Questions
If you have questions or need help integrating *Purchases* please [contact us](https://www.revenuecat.com/contact) or email *support@revenuecat.com* instead of opening an issue.


## Feature Requests
If there is something you'd like to see included or feel anything is missing you can add a feature to our [public roadmap](https://trello.com/b/RZRnWRbI/revenuecat-product-roadmap). If the feature already exists, or you see something else you'd like, upvote it.


## Pricing
*Purchases* SDK is free to use but some features require a paid plan. You can find more about that on our website on the [pricing plan page](https://www.revenuecat.com/pricing).
