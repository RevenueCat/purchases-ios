//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfo+TestExtensions.swift
//
//  Created by Nacho Soto on 4/25/22.

@testable import RevenueCat
import XCTest

extension CustomerInfo {

    /// Initializes the customer with a dictionary
    /// Useful only for backwards compatibility with old tests
    convenience init(
        data: [String: Any],
        sandboxEnvironmentDetector: SandboxEnvironmentDetector = BundleSandboxEnvironmentDetector.default
    ) throws {
        self.init(customerInfo: try JSONDecoder.default.decode(dictionary: data),
                  sandboxEnvironmentDetector: sandboxEnvironmentDetector)
    }

}

extension CustomerInfo {

    // swiftlint:disable:next force_try
    static let emptyInfo: CustomerInfo = try! .init(data: [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "app_user_id",
            "subscriptions": [:] as [String: Any],
            "other_purchases": [:] as [String: Any],
            "original_application_version": "1.0",
            "original_purchase_date": "2019-07-17T00:05:54Z"
        ] as [String: Any]
    ])

    // swiftlint:disable:next force_try
    static let missingOriginalPurchaseDate: CustomerInfo = try! .init(data: [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "app_user_id",
            "subscriptions": [:] as [String: Any],
            "other_purchases": [:] as [String: Any],
            "original_application_version": "1.0"
        ] as [String: Any]
    ])

    // swiftlint:disable:next force_try
    static let missingOriginalApplicationVersion: CustomerInfo = try! .init(data: [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "app_user_id",
            "subscriptions": [:] as [String: Any],
            "other_purchases": [:] as [String: Any],
            "original_purchase_date": "2019-07-17T00:05:54Z"
        ] as [String: Any]
    ])

}

extension CustomerInfo {

    func asData(withNewSchemaVersion version: Any?) throws -> Data {
        var dictionary = try XCTUnwrap(
            JSONSerialization.jsonObject(with: try self.jsonEncodedData) as? [String: Any]
        )

        if let version = version {
            dictionary["schema_version"] = version
        } else {
            dictionary.removeValue(forKey: "schema_version")
        }

        return try JSONSerialization.data(withJSONObject: dictionary, options: [])
    }

}
