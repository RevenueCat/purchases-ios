<h3 align="center">😻 In-App Subscriptions Made Easy 😻</h1>

[![License](https://img.shields.io/cocoapods/l/RevenueCat.svg?style=flat)](http://cocoapods.org/pods/RevenueCat)
[![Version](https://img.shields.io/cocoapods/v/Purchases.svg?style=flat)](https://cocoapods.org/pods/RevenueCat)
[![Version](https://img.shields.io/cocoapods/v/RevenueCat.svg?style=flat)](https://cocoapods.org/pods/RevenueCat)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://docs.revenuecat.com/docs/ios#section-install-via-carthage)
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-orange.svg)](https://docs.revenuecat.com/docs/ios#section-install-via-swift-package-manager)

RevenueCat is a powerful, reliable, and free to use in-app purchase server with cross-platform support. Our open-source framework provides a backend and a wrapper around StoreKit and Google Play Billing to make implementing in-app purchases and subscriptions easy. 

Whether you are building a new app or already have millions of customers, you can use RevenueCat to:

  * Fetch products, make purchases, and check subscription status with our [native SDKs](https://docs.revenuecat.com/docs/installation). 
  * Host and [configure products](https://docs.revenuecat.com/docs/entitlements) remotely from our dashboard. 
  * Analyze the most important metrics for your app business [in one place](https://docs.revenuecat.com/docs/charts).
  * See customer transaction histories, chart lifetime value, and [grant promotional subscriptions](https://docs.revenuecat.com/docs/customers).
  * Get notified of real-time events through [webhooks](https://docs.revenuecat.com/docs/webhooks).
  * Send enriched purchase events to analytics and attribution tools with our easy integrations.

Sign up to [get started for free](https://app.revenuecat.com/signup).

## Migrating from Purchases v3
- See our [Migration guide](Documentation.docc/V4_API_Migration_guide.md)

## RevenueCat.framework

*Purchases* and *RevenueCat* are clients for the [RevenueCat](https://www.revenuecat.com/) subscription and purchase tracking system.

**Purchases** is the currently supported, production-ready, open source framework that provides a wrapper around `StoreKit` and the RevenueCat backend to make implementing in-app subscriptions in `Swift` or `Objective-C` easy - receipt validation and status tracking included! 

**RevenueCat** is our next big release (what we've been calling Purchases V4). It is a rename of `Purchases` to `RevenueCat`, and now, 100% `Swift` (while maintaining `Objective-C` compatibility). It contains all the same functionality (and almost exactly the same API) as `Purchases`. It's not a brand-new framework, but rather, a migration of the ObjC bits over to Swift with improved nullability, various bug fixes, and some new features. You can see what's changed in the [API updates doc](https://rev.cat/uet).

## RevenueCat SDK Features
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

## Getting Started
For more detailed information, you can view our complete documentation at [docs.revenuecat.com](https://docs.revenuecat.com/docs).

Or browse our iOS sample apps:
- [MagicWeather](Examples/MagicWeather)
- [MagicWeather SwiftUI](Examples/MagicWeatherSwiftUI)