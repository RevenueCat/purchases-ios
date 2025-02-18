//
//  Constants.swift
//  Magic Weather
//
//  Created by Cody Kerns on 12/14/20.
//

import Foundation

/*
 Configuration file for your app's RevenueCat settings.
 */

struct Constants {
    
    /*
     The API key for your app from the RevenueCat dashboard: https://app.revenuecat.com
     */
    static let apiKey: String = {
        // return "your-api-key"
        guard let key = Bundle.main.object(forInfoDictionaryKey: "EXAMPLE_APP_API_KEY") as? String, !key.isEmpty else {
            fatalError("Modify this property to reflect your app's API key")
        }
        return key
    }()

    /*
     The entitlement ID from the RevenueCat dashboard that is activated upon successful in-app purchase for the duration of the purchase.
     */
    static let entitlementID = {
        // return "premium"
        guard let key = Bundle.main.object(forInfoDictionaryKey: "EXAMPLE_APP_ENTITLEMENT_ID") as? String, !key.isEmpty else {
            fatalError("Modify this property to reflect your app's entitlement identifier")
        }
        return key
    }()

}
