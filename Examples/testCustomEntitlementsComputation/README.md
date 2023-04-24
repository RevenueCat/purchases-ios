# Custom Entitlements Computation Example App

This app is useful for testing RevenueCat under Custom Entitlements Computation mode and understanding how it works.

## What is Custom Entitlements Computation mode? 

This is a special behavior mode for RevenueCat SDK, is intended for apps that will do their own entitlement computation separate from RevenueCat. 

Apps using this mode rely on webhooks to signal their backends to refresh entitlements with RevenueCat.

In this mode, RevenueCat will not generate anonymous user IDs, it will not refresh customerInfo cache automatically only when a purchase goes through 
and it will disallow the logOut methods.

When in this mode, the app should use logIn to switch to a different App User ID if needed. 
The SDK should only be configured once the initial appUserID is known.

## Using the app

To use the app, you should do the following: 
- Configure your app in the [RevenueCat dashboard](https://app.revenuecat.com/). No special configuration is needed, but you should contact RevenueCat support
before enabling this mode to ensure that it's the right one for your app. 
- Update the API key in Constants.swift and remove the #error line. You can update the default `appUserID` there too, although apps in this mode should 
always be calling configure only when the appUserID is already known. 
- Update the bundle ID to match your RevenueCat app configuration.
- Have at least one Offering with at least one Package configured for iOS, since this is the one that the purchase button will use. 

Once configured correctly, the app will allow you to log in with different users, and will show a list of all the times CustomerInfoAsyncStream fired, as well as 
the values for each one. 

Happy testing!

![sample screenshot](./Sample%20screenshot.png)