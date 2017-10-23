## Purchases

[![Version](https://img.shields.io/cocoapods/v/Purchases.svg?style=flat)](https://cocoapods.org/pods/Purchases)
[![License](https://img.shields.io/cocoapods/l/Purchases.svg?style=flat)](http://cocoapods.org/pods/Purchases)


Purchases is a client for the [RevenueCat](https://www.revenuecat.com/) subscription and purchase tracking system. It is an open source framework that provides a wrapper around `StoreKit` and the RevenueCat backend to make implementing iOS in app purchases easy.


## Installation

*Purchases* is available through [CocoaPods](https://cocoapods.org/) and [Carthage](https://github.com/Carthage/Carthage)

### CocoaPods
```
pod "Purchases", "0.1.0"
```

### Carthage
```
github "revenuecat/purchases-ios"
```

## Getting Started

#### 1. Create a RevenueCat Account

Go to [RevenueCat](http://www.revenuecat.com), create an account, and obtain a shared secret for your application.

#### 2. In your app instantiate an `RCPurchases` object with your secret.

```obj-c
#import <Purchases/Purchases.h>

RCPurchases *purchases = [[RCPurchases alloc] initWithSharedSecret:@"myappsharedsecret"
                                                         appUserID:@"uniqueidforuser"];
```

#### 3. Create a delegate to handle new purchases

```obj-c
purchases.delegate = delegateObject;

- (void)purchases:(nonnull RCPurchases *)purchases
    completedTransaction:(nonnull SKPaymentTransaction *)transaction
         withUpdatedInfo:(nonnull RCPurchaserInfo *)purchaserInfo {
         [self saveNewPurchaserInfo:purchaserInfo];
}
```

#### 4. Make a purchase
```obj-c
[purchases purchaseProduct:mySubscriptionProduct];
```

#### 5. Make $$$

That's it. RevenueCat will handle all purchase verification and purchase tracking for you so you can focus on building your app.
