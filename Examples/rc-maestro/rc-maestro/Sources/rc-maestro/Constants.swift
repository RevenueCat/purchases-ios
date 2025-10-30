//
//  Constants.swift
//  Maestro-Debug
//
//  Created by Facundo Menzella on 7/7/25.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import UIKit

enum Constants {
    /*
     To add your own API key for local development, add it in your local.xcconfig file like this:
     REVENUECAT_API_KEY = your-api-key
     */
    static let apiKey: String = {
        Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String ?? ""
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
    
    /*
     The force server error strategy to configure Purchases with
     To be used in (e2e) tests in order to simulate server failures
     REVENUECAT_FORCE_SERVER_ERROR_STRATEGY = primary_domain_down
     */
    static var forceServerErrorStrategy: Constants.ForceServerErrorStrategy {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_FORCE_SERVER_ERROR_STRATEGY") as? String else {
            return .never
        }
        
        return ForceServerErrorStrategy(rawValue: value) ?? .never
    }
    
    enum ForceServerErrorStrategy: String {
        case primaryDomainDown = "primary_domain_down"
        case never
    }
}
