//
//  Constants.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-05-13.
//

import Foundation

// DO NOT MODIFY THIS FILE.
// CI system adds the API key here.
enum Constants {
    /*
     To add your own API key for local development, add it in your local.xcconfig file like this:
     REVENUECAT_API_KEY = your-api-key
     */
    static let apiKey: String = {
        "appl_yBXmuJBTosTvPtfwIySkUzDkxAq"
    }()

    /*
     To add your own proxyURL for local development, add it in your local.xcconfig file like this:
     REVENUECAT_PROXY_URL = your-api-key
     */
    static let proxyURL: String? = {
        guard
            var scheme = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_PROXY_URL_SCHEME") as? String,
            !scheme.isEmpty,
            let host = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_PROXY_URL_HOST") as? String,
            !host.isEmpty else {
            return nil
        }
        if !scheme.hasSuffix(":") {
            scheme.append(":")
        }
        return "\(scheme)//\(host)"
    }()
}
