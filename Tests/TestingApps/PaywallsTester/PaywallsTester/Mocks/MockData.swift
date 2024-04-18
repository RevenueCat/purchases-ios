//
//  MockData.swift
//  
//
//  Created by Nacho Soto on 12/14/23.
//

import Foundation
import OSLog


#if DEBUG

public enum MockData {

    public static func developer() -> DeveloperResponse {
        return try! MockData.decode(Self.developerJson)
    }

}

extension MockData {

    static let developerJson = """
    {
        "apps": [
            {
                "api_key": "",
                "bundle_id": "com.revenuecat.sampleapp",
                "enable_price_experiments": false,
                "feature_overrides": [],
                "id": "asdasdsad",
                "name": "Main RevenueCat Sample App",
                "on_restore": null,
                "owner_email": "nacho@revenuecat.com"
            }
        ],
        "current_plan": "pro",
        "distinct_id": "asasdasd",
        "email": "nacho@revenuecat.com",
        "email_verified": true,
        "name": "Ignacio Soto Bustos"
    }
    """

}

extension MockData {

    public static func decode<T: Decodable>(_ json: String) throws -> T {
        do {
            return try JSONDecoder.default.decode(T.self, from: json.asData)
        } catch let error as NSError {
            Self.logger.error("Error decoding \(T.self): \(error.description)")
            throw error
        }
    }
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.revenuecat.PaywallsTester",
                                       category: "MockData")

}

#endif
