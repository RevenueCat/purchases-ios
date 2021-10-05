<h3 align="center">😻 In-App Subscriptions Made Easy 😻</h1>

[![License](https://img.shields.io/cocoapods/l/RevenueCat.svg?style=flat)](http://cocoapods.org/pods/RevenueCat)
[![Version](https://img.shields.io/cocoapods/v/Purchases.svg?style=flat)](https://cocoapods.org/pods/RevenueCat)
[![Version](https://img.shields.io/cocoapods/v/RevenueCat.svg?style=flat)](https://cocoapods.org/pods/RevenueCat)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://docs.revenuecat.com/docs/ios#section-install-via-carthage)
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-orange.svg)](https://docs.revenuecat.com/docs/ios#section-install-via-swift-package-manager)

## Purchases.framework (currently supported)
We're in the process of migrating the entire framework over to Swift 🎉. The new framework is called `RevenueCat.framework`. While this migration is happening, you can (and should) still use the currently supported production version you know and love. If you'd like to help us by testing our beta, please feel free!

### **IMPORTANT:** SPM integration note for users of our stable release:
Swift Package Manager (SPM) integration is currently not working as expected. If you wish to use the currently supported and stable `Purchases` framework (version 3.12.4), you'll need to specify `< 4.0.0` or for your dependencies in Xcode. By default, Xcode will specify `exactly 4.0.0` and that won't work because we haven't released that version yet, only `4.0.0-beta.x`.

## RevenueCat.framework Beta

*Purchases* and *RevenueCat* are clients for the [RevenueCat](https://www.revenuecat.com/) subscription and purchase tracking system.

**Purchases** is the currently supported, production-ready, open source framework that provides a wrapper around `StoreKit` and the RevenueCat backend to make implementing in-app subscriptions in `Swift` or `Objective-C` easy - receipt validation and status tracking included! 

**RevenueCat** is our next big release (what we've been calling Purchases V4). It is a rename of `Purchases` to `RevenueCat`, and now, 100% Swift. It contains all the same functionality (and almost exactly the same API) as `Purchases`. It's not a brand-new framework, but rather, a migration of the ObjC bits over to Swift with improved nullability, various bug fixes, and some new features. We're also going to be adding in `StoreKit2` support before we 🚢 it, too! The framework is nearly production-ready, but we're going to keep it in beta while we continue to work on the `StoreKit2` bits and iron out any remaining bugs folks find. Keep an eye out over the next few releases if you're excited to try out the `StoreKit2` integration- we'll announce when we add it to the beta 😄

### ⚠️ Beta build warning
Are you here because you saw a build warning about being on the Beta?

If you're cool being in the beta, there's nothing more for you to do 🎉
If you think you've made a mistake:

### Getting out of the beta 😿
#### Swift package manager

- You need to update the package's repo rules to use `3.0.0 < 4.0.0`

#### Cocoapods

- You need to use `Purchases` pod instead of `RevenueCat`

#### Carthage

- You need to use `github "RevenueCat/purchases-ios" ~> 3.12` in your `Cartfile`

#### Direct Integration

- You'll want to checkout one of the `3.x`[Purchases.framework tags](https://github.com/RevenueCat/purchases-ios/tags).

## RevenueCat SDK Features
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