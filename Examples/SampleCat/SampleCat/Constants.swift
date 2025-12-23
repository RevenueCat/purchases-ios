import Foundation

/*
 Configuration file for your app's RevenueCat settings.
 */
enum Constants {
    /*
     The API key for your app from the RevenueCat dashboard: https://app.revenuecat.com
     */
    #error("Modify this property to reflect your app's API key, then remove this line.")
    static let apiKey = "REVENUECAT_API_KEY"
    
    /*
     The entitlement identifier from the RevenueCat dashboard that is activated upon successful in-app purchase for the duration of the purchase.
     */
    #error("Modify this property to reflect your app's entitlement identifier, then remove this line. If you do not use entitlements, you can set this property to nil.")
    static let entitlementIdentifier: String? = "premium"
}
