[![RevenueCat](https://s3.amazonaws.com/www.revenuecat.com/assets/images/logo_red200.png)](https://www.revenuecat.com)

[![Version](https://img.shields.io/cocoapods/v/Purchases.svg?style=flat)](https://cocoapods.org/pods/Purchases)
[![License](https://img.shields.io/cocoapods/l/Purchases.svg?style=flat)](http://cocoapods.org/pods/Purchases)

## Purchases.framework

*Purchases* is a client for the [RevenueCat](https://www.revenuecat.com/) subscription and purchase tracking system. It is an open source framework that provides a wrapper around `StoreKit` and the RevenueCat backend to make implementing in-app purchases in `Swift` or `Objective-C` easy.

Features:
- Server-side receipt validation
- [Webhooks](https://docs.revenuecat.com/docs/webhooks) - enhanced server-to-server communication with events for purchases, renewals, cancellations, and more
- Subscription status tracking - know whether a user is subscribed whether they're on iOS, Android or web.
- Analytics - automatic calculation of metrics like conversion, mrr, and churn
- [Online documentation](https://docs.revenuecat.com/docs) up to date
- [Integrations](https://www.revenuecat.com/integrations) - over a dozen integrations to easily send purchase data where you need it
- Well maintained - [frequent releases](https://github.com/RevenueCat/purchases-ios/releases)
- Great support - [Help Center](https://docs.revenuecat.com/discuss)
- Awesome [new features](https://trello.com/b/RZRnWRbI/revenuecat-product-roadmap)


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

You should only initialize Purchases once (usually on app launch) and share the same instance throughout your app by setting the shared instance in the SDK - *Purchases* will take care of making a singleton for you.

```swift
import Purchases

let purchases = RCPurchases.configure(withAPIKey: "my_api_key")
purchases.delegate = self
```

```obj-c
#import "RCPurchases.h"

RCPurchases *purchases = [[RCPurchases alloc] initWithAPIKey:@"my_api_key"];
purchases.delegate = self;
```

#### 3. Make a purchase
When it comes time to make a purchase, *Purchases* has a simple method, `makePurchase`. The code sample below shows the process of fetching entitlements (which should be pre-loaded and super fast) and purchasing the "monthly" product offering.

```swift
purchases.entitlements { entitlements in
    guard let pro = entitlements?["my_entitlement_name"] else { return }
    guard let monthly = pro.offerings["my_offering_name"] else { return }
    guard let product = monthly.activeProduct else { return }
    purchases.makePurchase(product)
}
```

```obj-c
[purchases entitlements:^(NSDictionary<NSString *, RCEntitlement *> *entitlements) {
	SKProduct *product = entitlements[@"my_entitlement_name"].offerings[@"my_offering_name"].activeProduct;
    [purchases makePurchase:product];
}];
```
>`makePurchase` handles the underlying framework interaction and automatically validates purchases with Apple through our secure servers. This helps reduce in-app purchase fraud and decreases the complexity of your app. Receipt tokens are stored remotely and always kept up-to-date.

#### 4. Unlock Content
Once the purchase is made, verified, and stored, we will send you the latest version of a purchaser's available entitlements - this is done via the *Purchases* listener/delegate. It is your responsibility to unlock appropriate content or features in response to this.

```swift
func purchases(_ purchases: RCPurchases, completedTransaction transaction: SKPaymentTransaction, withUpdatedInfo purchaserInfo: RCPurchaserInfo) {
    if purchaserInfo.activeEntitlements.contains("my_entitlement_name") {
        // Unlock that great "pro" content.
    }
}
```

```obj-c
- (void)purchases:(RCPurchases *)purchases completedTransaction:(SKPaymentTransaction*)transaction withUpdatedInfo:(RCPurchaserInfo *)purchaserInfo {
    [purchaserInfo.activeEntitlements containsObject:@"my_entitlement_name"];
}
```

#### 5. Get Subscription Status
*Purchases* makes it easy to check what active subscriptions the current user has. This can be done two ways within the `receivedUpdatedPurchaserInfo` listener/delegate:
1. Checking active Entitlements - this lets you see what entitlements ([from RevenueCat dashboard](https://app.revenuecat.com)) are active for the user.
2. Checking the active subscriptions - this lets you see what product ids (from iTunes Connect or Play Store) are active for the user.

```swift
func purchases(_ purchases: RCPurchases, receivedUpdatedPurchaserInfo purchaserInfo: RCPurchaserInfo) {
    let entitlements = purchaserInfo.activeEntitlements
    let subscriptions = purchaserInfo.activeSubscriptions

    if entitlements.contains("my_entitlement_name") {
        // print("user is a pro")
    }

    if subscriptions.contains("my_subscription_id") {
        // print("user is a pro")
    }
}
```

#### 6. Displaying Available Products
*Purchases* will automatically fetch the latest *active* entitlements and get the product information from Apple. This means when users launch your purchase screen, products will already be loaded.

```swift
func displayUpsellScreen() {
    purchases?.entitlements({ (ents) in
        let vc = UpsellController()
        vc.entitlements = ents
        presentViewController(vc, animated: true, completion: nil)
    })
}
```

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
