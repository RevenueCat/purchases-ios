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
- ``Purchases/configure(with:)-6oipy``

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
- ``Purchases/presentCodeRedemptionSheet()``

### Subscription Status
- ``Purchases/getCustomerInfo(completion:)``
- ``Purchases/customerInfo(fetchPolicy:)``
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
- ``Purchases/setPushTokenString(_:)``
- ``Purchases/setMediaSource(_:)``
- ``Purchases/setPhoneNumber(_:)``
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

### Advanced Configuration
- ``Purchases/finishTransactions``
- ``Purchases/invalidateCustomerInfoCache()``
- ``Purchases/forceUniversalAppStore``
- ``Purchases/proxyURL``
- ``Purchases/verboseLogs``
- ``Purchases/verboseLogHandler``
- ``Purchases/allowSharingAppStoreAccount``

### Configuring the SDK with parameters (deprecated)
- ``Purchases/configure(withAPIKey:appUserID:)``
- ``Purchases/configure(withAPIKey:appUserID:observerMode:)``
- ``Purchases/configure(withAPIKey:appUserID:observerMode:userDefaults:)``
- ``Purchases/configure(withAPIKey:appUserID:observerMode:userDefaults:useStoreKit2IfAvailable:)``
