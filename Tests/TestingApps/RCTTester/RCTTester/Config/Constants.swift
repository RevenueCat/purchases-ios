//
//  Constants.swift
//  RCTTester
//

import Foundation

enum Constants {

    static let apiKey: String = {
        Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String ?? ""
    }()

}
