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
🖥 | macOS support
🎯 | Subscription status tracking - know whether a user is subscribed whether they're on iOS, Android or web
📊 | Analytics - automatic calculation of metrics like conversion, mrr, and churn
📝 | [Online documentation](https://docs.revenuecat.com/docs) up to date
🔀 | [Integrations](https://www.revenuecat.com/integrations) - over a dozen integrations to easily send purchase data where you need it
💯 | Well maintained - [frequent releases](https://github.com/RevenueCat/purchases-ios/releases)
📮 | Great support - [Help Center](https://community.revenuecat.com)

## Getting Started
For more detailed information, you can view our complete documentation at [docs.revenuecat.com](https://docs.revenuecat.com/docs).

Or browse our iOS sample apps:
- [MagicWeather](Examples/MagicWeather)
- [MagicWeather SwiftUI](Examples/MagicWeatherSwiftUI)

## Topics

### Purchases
- ``Purchases``

### Configuring the SDK

- ``Purchases/configure(withAPIKey:)``
- ``Purchases/configure(withAPIKey:appUserID:)``
- ``Purchases/configure(withAPIKey:appUserID:observerMode:)``
- ``Purchases/configure(withAPIKey:appUserID:observerMode:userDefaults:)``

### Displaying Products
- ``Offerings``
- ``Offering``
- ``Package``
- ``StoreProduct``
- ``SubscriptionPeriod``

- ``Purchases/getOfferings(completion:)``
- ``Purchases/getProducts(_:completion:)``

### Making Purchases
- ``StoreTransaction``
- ``Purchases/purchase(package:)``
- ``Purchases/purchase(package:completion:)``
- ``Purchases/purchase(product:)``
- ``Purchases/purchase(product:completion:)``

### Making Purchases with Promotional Offers
- ``IntroEligibility``
- ``StoreProductDiscount``
- ``Purchases/checkTrialOrIntroductoryPriceEligibility(_:)``
- ``Purchases/purchase(package:discount:completion:)``
- ``Purchases/purchase(product:discount:completion:)``

### Subscription Status
- ``CustomerInfo``
- ``EntitlementInfo``
- ``EntitlementInfos``
- ``PurchasesDelegate``
- ``Purchases/getCustomerInfo(completion:)``

### Identifying Users
- ``Purchases/logIn(_:completion:)``
- ``Purchases/logOut(completion:)``

### Managing Subscriptions
- ``Purchases/syncPurchases()``
- ``Purchases/restorePurchases()``
- ``Purchases/beginRefundRequestForActiveEntitlement()``
- ``Purchases/beginRefundRequest(forEntitlement:)``
- ``Purchases/beginRefundRequest(forProduct:)``
- ``Purchases/showManageSubscriptions()``

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
- ``Purchases/setMediaSource(_:)``
- ``Purchases/setPhoneNumber(_:)``
- ``Purchases/setAttributes(_:)``

### Integrations
- ``Purchases/setAdjustID(_:)``
- ``Purchases/setAppsflyerID(_:)``
- ``Purchases/setAirshipChannelID(_:)``
- ``Purchases/setMparticleID(_:)``
- ``Purchases/setOnesignalID(_:)``
- ``Purchases/setFBAnonymousID(_:)(_:)``
