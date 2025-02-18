//
//  Constants.swift
//  PurchaseTester
//
//  Created by Josh Holtz on 6/21/22.
//

import Foundation

/*
 Configuration file for your app's RevenueCat settings.
 */

public struct Constants {

    /*
     The API key for your app from the RevenueCat dashboard: https://app.revenuecat.com
     This is the default used by `ConfigurationView`

     To add your own API key for local development, add it in your local.xcconfig file like this:
     REVENUECAT_API_KEY = "your-api-key"
     */
    public static var apiKey: String { Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String ?? "" }

}
