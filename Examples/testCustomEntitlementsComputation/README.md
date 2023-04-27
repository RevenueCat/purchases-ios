# Custom Entitlements Computation Example App

This app is useful for testing RevenueCat under Custom Entitlements Computation mode and understanding how it works.

## What is Custom Entitlements Computation mode? 

This is a special behavior mode for RevenueCat SDK, is intended for apps that will do their own entitlement computation separate from RevenueCat. 

Apps using this mode rely on webhooks to signal their backends to refresh entitlements with RevenueCat.

In this mode, RevenueCat will not generate anonymous user IDs, it will not refresh customerInfo cache automatically only when a purchase goes through 
and it will disallow all methods other than those for configuration, switching users, getting offerings and making purchases.

When in this mode, the app should use switchUser(to:) to switch to a different App User ID if needed. 
The SDK should only be configured once the initial appUserID is known.

## Using the app

To use the app, you should do the following: 
- Configure your app in the [RevenueCat dashboard](https://app.revenuecat.com/). No special configuration is needed, but you should contact RevenueCat support
before enabling this mode to ensure that it's the right one for your app. It's highly recommended to set Transfer Behavior to "Keep with original App User ID" in the RevenueCat Dashboard. 
- Update the API key in Constants.swift and remove the #error line. You can update the default `appUserID` there too, although apps in this mode should 
always be calling configure only when the appUserID is already known. 
- Update the bundle ID to match your RevenueCat app configuration.
- Have at least one Offering with at least one Package configured for iOS, since this is the one that the purchase button will use. 

Once configured correctly, the app will allow you to log in with different users, and will show a list of all the times CustomerInfoAsyncStream fired, as well as 
the values for each one. 

To use this mode, ensure that you install the RevenueCat_CustomEntitlementComputation SDK in Swift Package Manager. 

Happy testing!

![sample screenshot](./Sample%20screenshot.png)

## Using Custom Entitlements mode

### Installation: 

Install the SDK through Swift Package Manager. 

Select File » Add Packages... and enter the repository URL of the https://github.com/RevenueCat/purchases-ios.git into the search bar (top right). Set the Dependency Rule to Up to next major, and the version number to 4.18.0 < 5.0.0.

**Check `RevenueCat_CustomEntitlementComputation` when a prompt for "Choose Package Products for purchases-ios" appears**. Finally, choose the target where you want to use it.

The library should have been added to the Swift Package Dependencies section and you should be able to import it now.

### Configuration: 

The SDK should be configured once the user has already logged in. To configure, call:

```swift
Purchases.configureInCustomEntitlementsComputationMode(apiKey: "your_api_key", appUserID: appUserID)
```

### Getting Offerings: 

Call getOfferings through either the Async / Await or completion blocks alternatives:

```swift

let offerings = try await Purchases.shared.offerings()

```

```swift
Purchases.shared.getOfferings { (offerings, error) in
    // code to handle here
}
```

### Switching users: 

To switch to a different user, call:

```swift
Purchases.shared.switchUser(to: appUserID)
```

This will ensure that all purchases made from this point on are posted for the new appUserID. 
After calling this method, you might need to call your backend to refresh entitlements for the new appUserID if they haven't been refreshed already.

### Making purchases:

Call `purchase(package:)` through either the Async / Await or completion blocks alternatives:

```swift
do {
    let (transaction, customerInfo, _) = try await Purchases.shared.purchase(package: package)
    print(
        """
        Purchase finished:
        Transaction: \(transaction.debugDescription)
        CustomerInfo: \(customerInfo.debugDescription)
        """
    )
} catch ErrorCode.receiptAlreadyInUseError {
    print("The receipt is already in use by another subscriber. " +
          "Log in with the previous account or contact support to get your purchases transferred to " +
          "regain access")
} catch ErrorCode.paymentPendingError {
    print("The purchase is pending and may be completed at a later time." +
          "This can happen when awaiting parental approval or going through extra authentication flows " +
          "for credit cards in some countries.")
} catch ErrorCode.purchaseCancelledError {
    print("Purchase was cancelled by the user.")
} catch {
    print("FAILED TO PURCHASE: \(error.localizedDescription)")
}
```

```swift
Purchases.shared.purchase(package: package) { (transaction, customerInfo, error, userCancelled) in
    if let error = error as? ErrorCode {
        switch error {
        case .receiptAlreadyInUseError:
            print("The receipt is already in use by another subscriber. " +
                  "Log in with the previous account or contact support to get your purchases transferred to " +
                  "regain access")
        case .paymentPendingError:
            print("The purchase is pending and may be completed at a later time." +
                  "This can happen when awaiting parental approval or going through extra authentication flows " +
                  "for credit cards in some countries.")
        case .purchaseCancelledError:
            print("Purchase was cancelled by the user.")
        default:
            print("FAILED TO PURCHASE: \(error.localizedDescription)")
        }
        return
    } else if let error = error {
        print("FAILED TO PURCHASE: \(error.localizedDescription)")
        return
    }

    print(
        """
        Purchase finished:
        Transaction: \(transaction.debugDescription)
        CustomerInfo: \(customerInfo.debugDescription)
        """
    )
}
```

### Observing changes to purchases:

To ensure that your app reacts to changes to subscriptions in real time, you can use `customerInfoStream`. This stream will only fire when new `customerInfo` is registered
in RevenueCat, like when a subscription is renewed. If there are no changes from the last value, it will not fire. This means it's not guaranteed to fire on every app open.

```swift
for await customerInfo in Purchases.shared.customerInfoStream {
    // code to handle here
}
```
