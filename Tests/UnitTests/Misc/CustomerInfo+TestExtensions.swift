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

    func asData() throws -> Data {
        return try JSONEncoder.default.encode(self)
    }

}

extension CustomerInfo {

    func asData(withNewSchemaVersion version: Any?) throws -> Data {
        var dictionary = try XCTUnwrap(JSONSerialization.jsonObject(with: try self.asData()) as? [String: Any])

        if let version = version {
            dictionary["schema_version"] = version
        } else {
            dictionary.removeValue(forKey: "schema_version")
        }

        return try JSONSerialization.data(withJSONObject: dictionary, options: [])
    }

}
