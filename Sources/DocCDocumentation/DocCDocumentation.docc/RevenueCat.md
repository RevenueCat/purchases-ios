# ``RevenueCat``

😻 In-App Subscriptions Made Easy 😻

## Overview

RevenueCat is a powerful, reliable, and free to use in-app purchase server with cross-platform support. Our open-source framework provides a backend and a wrapper around StoreKit and Google Play Billing to make implementing in-app purchases and subscriptions easy. 

Whether you are building a new app or already have millions of customers, you can use RevenueCat to:

  * Fetch products, make purchases, and check subscription status with our [native SDKs](https://docs.revenuecat.com/docs/installation). 
  * Host and [configure products](https://docs.revenuecat.com/docs/entitlements) remotely from our dashboard. 
  * Analyze the most important metrics for your app business [in one place](https://docs.revenuecat.com/docs/charts).
  * See customer transaction histories, chart lifetime value, and [grant promotional subscriptions](https://docs.revenuecat.com/docs/customers).
  * Get notified of real-time events through [webhooks](https://docs.revenuecat.com/docs/webhooks).
  * Send enriched purchase events to analytics and attribution tools with our easy integrations.

Sign up to [get started for free](https://app.revenuecat.com/signup).

### RevenueCat SDK Features
|   | RevenueCat |
| --- | --- |
✅ | Server-side receipt validation
➡️ | [Webhooks](https://docs.revenuecat.com/docs/webhooks) - enhanced server-to-server communication with events for purchases, renewals, cancellations, and more
🖥 | iOS, tvOS, macOS and watchOS support
🎯 | Subscription status tracking - know whether a user is subscribed whether they're on iOS, Android or web
📊 | Analytics - automatic calculation of metrics like conversion, mrr, and churn
📝 | [Online documentation](https://docs.revenuecat.com/docs) up to date
🔀 | [Integrations](https://www.revenuecat.com/integrations) - over a dozen integrations to easily send purchase data where you need it
💯 | Well maintained - [frequent releases](https://github.com/RevenueCat/purchases-ios/releases)
📮 | Great support - [Help Center](https://community.revenuecat.com)

- Important: You're viewing the documentation for RevenueCat iOS SDK version 4.
For documentation on version 3, visit [the docs for RevenueCat iOS SDK version 3.](https://sdk.revenuecat.com/ios/index.html)

## Migrating from Purchases v3
When transitioning between our V3 SDK, we ported our entire SDK into Swift. 
Migrating from Objective-C to Swift required a number of API changes, but we feel that the
changes resulted in the SDK having a more natural feel for developers. In addition,
we introduced several new types and APIs.

Our <doc:V4_API_Migration_guide> provides information on how to migrate from V3 to V4. 

## Getting Started
For more detailed information, you can view our complete documentation at [docs.revenuecat.com](https://docs.revenuecat.com/docs).

Or browse our iOS sample apps:
- [MagicWeather](https://github.com/RevenueCat/purchases-ios/tree/main/Examples/MagicWeather)
- [MagicWeather SwiftUI](https://github.com/RevenueCat/purchases-ios/tree/main/Examples/MagicWeatherSwiftUI)

## Topics

### Purchases
- ``Purchases``

### Configuring the SDK
- ``Purchases/configure(withAPIKey:)``
- ``Purchases/configure(with:)-6oipy``

### Displaying Products
- ``Offerings``
- ``Offering``
- ``Package``
- ``StoreProduct``
- ``SubscriptionPeriod``

- ``Purchases/offerings()``
- ``Purchases/getOfferings(completion:)``
- ``Purchases/products(_:)``
- ``Purchases/getProducts(_:completion:)``

### Making Purchases
- ``StoreTransaction``

- ``Purchases/purchase(package:)``
- ``Purchases/purchase(package:completion:)``
- ``Purchases/purchase(product:)``
- ``Purchases/purchase(product:completion:)``

### Making Purchases with Subscription Offers
- ``IntroEligibility``
- ``PromotionalOffer``
- ``StoreProductDiscount``

- ``Purchases/checkTrialOrIntroDiscountEligibility(productIdentifiers:)``
- ``Purchases/checkTrialOrIntroDiscountEligibility(productIdentifiers:completion:)``
- ``Purchases/checkTrialOrIntroDiscountEligibility(product:)``
- ``Purchases/checkTrialOrIntroDiscountEligibility(product:completion:)``
- ``Purchases/promotionalOffer(forProductDiscount:product:)``
- ``Purchases/getPromotionalOffer(forProductDiscount:product:completion:)``
- ``Purchases/purchase(package:promotionalOffer:)``
- ``Purchases/purchase(package:promotionalOffer:completion:)``
- ``Purchases/purchase(product:promotionalOffer:)``
- ``Purchases/purchase(product:promotionalOffer:completion:)``

### Subscription Status
- ``CustomerInfo``
- ``EntitlementInfo``
- ``EntitlementInfos``
- ``PurchasesDelegate``

- ``Purchases/getCustomerInfo(completion:)``
- ``Purchases/customerInfo(fetchPolicy:)``
- ``Purchases/customerInfoStream``

### Identifying Users
- ``Purchases/logIn(_:)``
- ``Purchases/logIn(_:completion:)``
- ``Purchases/logOut()``
- ``Purchases/logOut(completion:)``

### Managing Subscriptions
- ``Purchases/syncPurchases()``
- ``Purchases/syncPurchases(completion:)``
- ``Purchases/restorePurchases()``
- ``Purchases/restorePurchases(completion:)``
- ``Purchases/beginRefundRequestForActiveEntitlement()``
- ``Purchases/beginRefundRequest(forEntitlement:)``
- ``Purchases/beginRefundRequest(forProduct:)``
- ``Purchases/showManageSubscriptions()``
- ``Purchases/showManageSubscriptions(completion:)``

### Subscriber Attributes
- ``Purchases/setAttributes(_:)``
- ``Purchases/setAd(_:)``
- ``Purchases/setEmail(_:)``
- ``Purchases/setDisplayName(_:)``
- ``Purchases/setKeyword(_:)``
- ``Purchases/setCampaign(_:)``
- ``Purchases/setCreative(_:)``
- ``Purchases/setAdGroup(_:)``
- ``Purchases/setPushToken(_:)``
- ``Purchases/setPushTokenString(_:)``
- ``Purchases/setMediaSource(_:)``
- ``Purchases/setPhoneNumber(_:)``
- ``Purchases/setAttributes(_:)``
- ``Purchases/collectDeviceIdentifiers()``

### Integrations
- ``Purchases/setAdjustID(_:)``
- ``Purchases/setAirshipChannelID(_:)``
- ``Purchases/setAppsflyerID(_:)``
- ``Purchases/setCleverTapID(_:)``
- ``Purchases/setFBAnonymousID(_:)``
- ``Purchases/setFirebaseAppInstanceID(_:)``
- ``Purchases/setMixpanelDistinctID(_:)``
- ``Purchases/setMparticleID(_:)``
- ``Purchases/setOnesignalID(_:)``

### Configuring the SDK with parameters (deprecated)
- ``Purchases/configure(withAPIKey:appUserID:)``
- ``Purchases/configure(withAPIKey:appUserID:observerMode:)``
- ``Purchases/configure(withAPIKey:appUserID:observerMode:userDefaults:)``
- ``Purchases/configure(withAPIKey:appUserID:observerMode:userDefaults:useStoreKit2IfAvailable:)``
