//
//  ConfigItem.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-05-13.
//

import Foundation

// DO NOT MODIFY THIS FILE.
// CI system adds the API key here.
struct ConfigItem {
    /*
     To add your own API key for local development, add it in your local.xcconfig file like this:
     REVENUECAT_API_KEY = "your-api-key"
     */
    static var apiKey: String { Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String ?? "" }

    /*
     To add your own proxyURL for local development, add it in your local.xcconfig file like this:
     REVENUECAT_API_KEY = "your-api-key"
     */
    static var proxyURL: String? { Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_PROXY_URL") as? String }
}
