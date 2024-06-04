//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProcessInfo+Extensions.swift
//
//  Created by Nacho Soto on 11/29/22.

import Foundation

#if DEBUG

enum EnvironmentKey: String {

    case XCTestConfigurationFile = "XCTestConfigurationFilePath"
    case RCRunningTests = "RCRunningTests"
    case RCRunningIntegrationTests = "RCRunningIntegrationTests"
    case RCMockAdServicesToken = "RCMockAdServicesToken"
    case XCCloud = "XCODE_CLOUD"

}

extension ProcessInfo {

    static subscript(key: EnvironmentKey) -> String? {
        return Self.processInfo.environment[key.rawValue]
    }

}

extension ProcessInfo {

    static var isRunningUnitTests: Bool {
        return self[.XCTestConfigurationFile] != nil
    }

    /// `true` when running unit or integration tests (configured in .xctestplan files).
    static var isRunningRevenueCatTests: Bool {
        return self[.RCRunningTests] == "1"
    }

    /// `true` when running integration tests (configured in .xctestplan files).
    static var isRunningIntegrationTests: Bool {
        return self[.RCRunningIntegrationTests] == "1"
    }

    static var mockAdServicesToken: String? {
        guard let token = self[.RCMockAdServicesToken], !token.isEmpty else { return nil }

        return token
    }

    static var isXcodeCloud: Bool {
        return self[.XCCloud] == "1"
    }

}

#endif
