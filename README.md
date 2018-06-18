[![RevenueCat](https://s3.amazonaws.com/www.revenuecat.com/assets/images/logo_red200.png)](https://www.revenuecat.com)
## Purchases.framework

[![Version](https://img.shields.io/cocoapods/v/Purchases.svg?style=flat)](https://cocoapods.org/pods/Purchases)
[![License](https://img.shields.io/cocoapods/l/Purchases.svg?style=flat)](http://cocoapods.org/pods/Purchases)


Purchases is a client for the [RevenueCat](https://www.revenuecat.com/) subscription and purchase tracking system. It is an open source framework that provides a wrapper around `StoreKit` and the RevenueCat backend to make implementing iOS in app purchases easy.

Check out the [getting started guide](https://docs.revenuecat.com/v1.0/docs/getting-started-1).


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

#### 1. Create a RevenueCat Account

Go to [RevenueCat](http://www.revenuecat.com), create an account, and obtain an API key for your application.

#### 2. In your app instantiate an `RCPurchases` object with your secret.

```swift
import Purchases

let purchases = RCPurchases(apiKey: "myappapikey")!
purchases.delegate = self;
```

```obj-c
@import Purchases

RCPurchases *purchases = [[RCPurchases alloc] initWithAPIKey:@"myappAPIKey"];
purchases.delegate = self;
```

#### 3. Make a purchase

```swift
purchases.entitlements({ (entitlements) in
  let product = entitlements["pro"].offerings["monthly"]!.activeProduct
  purchases.makePurchase(product)
})

```

```obj-c
[purchases entitlements:^(NSDictionary *entitlements) {
  SKProduct *product = entitlements[@"pro"].offerings[@"monthly"].activeProduct;
  [purchases makePurchase:product];
}];
```

#### 4. Unlock Entitlements
```swift
func purchases(_ purchases: RCPurchases, completedTransaction transaction: SKPaymentTransaction, withUpdatedInfo purchaserInfo: RCPurchaserInfo) {
  if (purchaseInfo.activeEntitlements.contains("pro")) {
    // Unlock that great "pro" content.
  }
}
```

```obj-c
- (void)purchases:(RCPurchases *)purchases
completedTransaction:(SKPaymentTransaction *)transaction
  withUpdatedInfo:(RCPurchaserInfo *)purchaserInfo {  
  [purchaserInfo.activeEntitlements containsObject:@"pro"];
}

```
