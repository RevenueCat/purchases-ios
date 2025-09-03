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

#if canImport(UIKit)
import UIKit
#endif

#if DEBUG

enum EnvironmentKey: String {

    case XCTestConfigurationFile = "XCTestConfigurationFilePath"
    case RCRunningTests = "RCRunningTests"
    case RCRunningIntegrationTests = "RCRunningIntegrationTests"
    case RCMockAdServicesToken = "RCMockAdServicesToken"
    case XCCloud = "XCODE_CLOUD"
    case xcodeRunningForPreviews = "XCODE_RUNNING_FOR_PREVIEWS"
    case emergeIsRunningForSnapshots = "EMERGE_IS_RUNNING_FOR_SNAPSHOTS"

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
    @_spi(Internal) public static var isRunningRevenueCatTests: Bool {
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

    /// `true` when running as part of an Xcode Preview (either in Xcode or on Emerge Tool's servers)
    @_spi(Internal) public static var isRunningForPreviews: Bool {
        return self[.xcodeRunningForPreviews] == "1" || self[.emergeIsRunningForSnapshots] == "1"
    }

    /// Returns a string identifying the platform and environment
    /// the app is running on (iOS, Mac Catalyst, visionOS, etc.).
    @_spi(Internal) public var platformString: String {
        #if os(macOS)
        return "Native Mac"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(watchOS)
        return "watchOS"
        #elseif os(visionOS)
        // May want to distinguish between iPad apps running on visionOS and native visionOS apps in the future
        return "visionOS"
        #elseif os(iOS)
        if isMacCatalystApp {
            if #available(iOS 14.0, *), isiOSAppOnMac {
                switch UIDevice.current.userInterfaceIdiom {
                case .phone:
                    return "iPhone App on Mac"
                case .pad:
                    return "iPad App on Mac"
                default:
                    return "Unexpected iOS App on Mac"
                }
            } else {
                switch UIDevice.current.userInterfaceIdiom {
                case .mac:
                    return "Mac Catalyst Optimized for Mac"
                case .pad:
                    return "Mac Catalyst Scaled to iPad"
                default:
                    return "Unexpected Platform on Mac Catalyst"
                }
            }
        } else {
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                return "iOS"
            case .pad:
                return "iPad OS"
            default:
                return "Unexpected iOS Platform"
            }
        }
        #endif
    }
}

#endif
