# ``RevenueCat/Purchases``

@Metadata {
    @DocumentationExtension(mergeBehavior: override)
}

``Purchases`` is the main entry point of the `RevenueCat` SDK. 
It provides access to all its features. 

## Overview

The ``Purchases`` class can be used to access all the features of the `RevenueCat` SDK. 
Most features require configuring the SDK before using it. 

## Topics

### Interacting with the SDK
- ``Purchases/shared``
- ``Purchases/isConfigured``
- ``Purchases/delegate``
- ``Purchases/logLevel``
- ``Purchases/logHandler``

### Configuring the SDK
- ``Purchases/configure(withAPIKey:)``
- ``Purchases/configure(withAPIKey:appUserID:)``
- ``Purchases/configure(withAPIKey:appUserID:observerMode:)``
- ``Purchases/configure(withAPIKey:appUserID:observerMode:userDefaults:)``

### Displaying Products
- ``Purchases/offerings()``
- ``Purchases/getOfferings(completion:)``
- ``Purchases/products(_:)``
- ``Purchases/getProducts(_:completion:)``

### Making Purchases
- ``Purchases/purchase(package:)``
- ``Purchases/purchase(package:completion:)``
- ``Purchases/purchase(product:)``
- ``Purchases/purchase(product:completion:)``
- ``Purchases/simulatesAskToBuyInSandbox``
- ``Purchases/canMakePayments()``

### Making Purchases with Subscription Offers
- ``Purchases/checkTrialOrIntroDiscountEligibility(_:)``
- ``Purchases/checkTrialOrIntroDiscountEligibility(_:completion:)``
- ``Purchases/getPromotionalOffer(forProductDiscount:product:)``
- ``Purchases/getPromotionalOffer(forProductDiscount:product:completion:)``
- ``Purchases/purchase(package:promotionalOffer:)``
- ``Purchases/purchase(package:promotionalOffer:completion:)``
- ``Purchases/purchase(product:promotionalOffer:)``
- ``Purchases/purchase(product:promotionalOffer:completion:)``
- ``Purchases/presentCodeRedemptionSheet()``

### Subscription Status
- ``Purchases/getCustomerInfo(completion:)``
- ``Purchases/customerInfo()``
- ``Purchases/customerInfoStream``

### Identifying Users
- ``Purchases/appUserID``
- ``Purchases/isAnonymous``
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
- ``Purchases/setMediaSource(_:)``
- ``Purchases/setPhoneNumber(_:)``
- ``Purchases/setAttributes(_:)``
- ``Purchases/collectDeviceIdentifiers()``

### Integrations
- ``Purchases/setAdjustID(_:)``
- ``Purchases/setAppsflyerID(_:)``
- ``Purchases/setAirshipChannelID(_:)``
- ``Purchases/setMparticleID(_:)``
- ``Purchases/setOnesignalID(_:)``
- ``Purchases/setFBAnonymousID(_:)``

### Advanced Configuration
- ``Purchases/finishTransactions``
- ``Purchases/invalidateCustomerInfoCache()``
- ``Purchases/forceUniversalAppStore``
- ``Purchases/automaticAppleSearchAdsAttributionCollection``
- ``Purchases/proxyURL``
- ``Purchases/verboseLogs``
- ``Purchases/verboseLogHandler``
- ``Purchases/allowSharingAppStoreAccount``
