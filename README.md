[![RevenueCat](https://s3.amazonaws.com/www.revenuecat.com/assets/images/logo_red200.png)](https://www.revenuecat.com)

[![Version](https://img.shields.io/cocoapods/v/Purchases.svg?style=flat)](https://cocoapods.org/pods/Purchases)
[![License](https://img.shields.io/cocoapods/l/Purchases.svg?style=flat)](http://cocoapods.org/pods/Purchases)

## Purchases.framework

*Purchases* is a client for the [RevenueCat](https://www.revenuecat.com/) subscription and purchase tracking system. It is an open source framework that provides a wrapper around `StoreKit` and the RevenueCat backend to make implementing in-app purchases in `Swift` or `Objective-C` easy.


**Features:**  
✅ Server-side receipt validation  
➡️ [Webhooks](https://docs.revenuecat.com/docs/webhooks) - enhanced server-to-server communication with events for purchases, renewals, cancellations, and more   
🎯 Subscription status tracking - know whether a user is subscribed whether they're on iOS, Android or web  
📊 Analytics - automatic calculation of metrics like conversion, mrr, and churn  
📝 [Online documentation](https://docs.revenuecat.com/docs) up to date  
🔀 [Integrations](https://www.revenuecat.com/integrations) - over a dozen integrations to easily send purchase data where you need it  
💯 Well maintained - [frequent releases](https://github.com/RevenueCat/purchases-ios/releases)  
📮 Great support - [Help Center](https://docs.revenuecat.com/discuss)  
🤩 Awesome [new features](https://trello.com/b/RZRnWRbI/revenuecat-product-roadmap)  


## Installation

*Purchases* is available through [CocoaPods](https://cocoapods.org/) and [Carthage](https://github.com/Carthage/Carthage)

### CocoaPods
```
pod "Purchases"
```

### Carthage
```
github "revenuecat/purchases-ios"
```


## Getting Started
For more detailed information, you can view our complete documentation at [docs.revenuecat.com](https://docs.revenuecat.com/).

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


#### 3. Make a purchase
When it comes time to make a purchase, *Purchases* has a simple method, `makePurchase`. The code sample below shows the process of purchasing a product and confirming it unlocks the "my_entitlement_name" content.

Swift:
```swift
Purchases.shared.makePurchase(product, { (transaction, purchaserInfo, error) in
    if let error = error {
        // Error making purchase
    } else if let purchaserInfo = purchaserInfo {
    
        if purchaserInfo.activeEntitlements.contains("my_entitlement_name") {
            // Unlock that great "pro" content
        }
        
    }
})
```

Obj-C:
```obj-c
[[RCPurchases sharedPurchases] makePurchase:product withCompletionBlock:^(SKPaymentTransaction *transaction, RCPurchaserInfo * purchaserInfo, NSError * error) {

    if ([purchaserInfo.activeEntitlements containsObject:@"my_entitlement_name"]) {
        // Unlock that great "pro" content.
    }
}];
```
>`makePurchase` handles the underlying framework interaction and automatically validates purchases with Apple through our secure servers. This helps reduce in-app purchase fraud and decreases the complexity of your app. Receipt tokens are stored remotely and always kept up-to-date.


#### 4. Get Subscription Status
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
        if purchaserInfo.activeEntitlements.contains("my_entitlement_name") {
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
    if ([purchaserInfo.activeEntitlements containsObject:@"my_entitlement_name"]) {
        // Grant user "pro" access
    }

    // Option 2: Check if user has active subscription (from App Store Connect or Play Store)
    if ([purchaserInfo.activeSubscriptions containsObject:@"my_product_identifier"]) {
	// Grant user "pro" access
    }
}];
```
>Since the SDK updates and caches the latest PurchaserInfo, the completion block in `.purchaserInfo` won't need to make a network request in most cases. This creates a fast and seamless startup experience.


#### 5. Displaying Available Products
*Purchases* will automatically fetch the latest *active* entitlements and get the product information from Apple or Google. This means when users launch your purchase screen, products will already be loaded.

Below is an example of fetching entitlements and launching an upsell screen.

Swift:
```swift
func displayUpsellScreen() {
    purchases?.entitlements({ (ents) in
        let vc = UpsellController()
        vc.entitlements = ents
        presentViewController(vc, animated: true, completion: nil)
    })
}
```

Obj-C
```obj-c
[self.purchases entitlements:^(NSDictionary<NSString *, RCEntitlement *> *entitlements) {
  UpsellViewController *vc = [[UpsellViewController alloc] init];
  vc.entitlements = entitlements;
  [self presentViewController:vc animated:YES completion:nil];
}];
```


## Next Steps
- If you haven't already, make sure your products are configured correctly in the RevenueCat dashboard by checking out our [guide on entitlements :arrow-right:](https://docs.revenuecat.com/docs/entitlements)
- If you want to use your own user identifiers, read about [setting app user ids :arrow-right:](https://docs.revenuecat.com/docs/user-ids)
- If you're moving to RevenueCat from another system, see our guide on [migrating your existing subscriptions :fa-arrow-right:](https://docs.revenuecat.com/docs/migrating-existing-subscriptions)
- Once you're ready to test your integration, you can follow our guides on [testing purchases :fa-arrow-right:](https://docs.revenuecat.com/docs/testing-purchases)


## Reporting Issues

You can use Github Issues to report any bugs and issues with *Purchases*. Here is some advice for users that want to report an issue:

1. Make sure that you are using the latest version of *Purchases*. The issue that you are about to report may be already fixed in the latest master branch version: https://github.com/revenuecat/purchases-ios/tree/master.
2. Providing reproducible steps for the issue will shorten the time it takes for it to be fixed - a Gist is always welcomed!
3. Since some issues are Sandbox specific, specifying what environment you encountered the issue might help.
​

## Technical Support or Questions

If you have questions or need help integrating *Purchases* please [contact us](https://www.revenuecat.com/contact) or email *support@revenuecat.com* instead of opening an issue.


## Pricing

*Purchases* SDK is free to use but some features require a paid plan. You can find more about that on our website on the [pricing plan page](https://www.revenuecat.com/pricing).
