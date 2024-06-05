//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OSVersion.swift
//
//  Created by Nacho Soto on 4/13/22.

import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(WatchKit)
import WatchKit
#endif

/// The equivalent version for the current device running tests.
/// Examples:
///     - `tvOS 15.1` maps to `.iOS15`
///     - `iOS 14.3` maps to `.iOS14`
///     - `macCatalyst 15.2` maps to `.iOS15`
enum OSVersionEquivalent: Int {

    case iOS12 = 12
    case iOS13 = 13
    case iOS14 = 14
    case iOS15 = 15
    case iOS16 = 16
    case iOS17 = 17

}

extension OSVersionEquivalent {

    static let current: Self = {
        #if os(macOS)
        // Not currently supported
        // Must convert e.g.: macOS 10.15 to iOS 13
        fatalError(Error.unknownOS().localizedDescription)
        #elseif os(watchOS)
        // The feature set on watchOS is currently equivalent to iOS 13.
        // For example, FakeTrackingManagerAuthorizationStatus isn't available.
        return .iOS13
        #else
        // Note: this is either iOS/tvOS/macCatalyst
        // They all share equivalent versions

        let majorVersion = ProcessInfo().operatingSystemVersion.majorVersion

        guard let equivalent = Self(rawValue: majorVersion) else {
            fatalError(Error.unknownOS().localizedDescription)
        }

        return equivalent
        #endif
    }()

}

private extension OSVersionEquivalent {

    private enum Error: Swift.Error {

        case unknownOS(systemName: String, version: String)
        case unknownPlatform

        static func unknownOS() -> Self {
            #if os(watchOS)
            let device = WKInterfaceDevice.current()

            return .unknownOS(systemName: device.systemName, version: device.systemVersion)
            #elseif os(iOS) || os(tvOS)
            let device = UIDevice.current

            return .unknownOS(systemName: device.systemName, version: device.systemVersion)
            #else
            return .unknownPlatform
            #endif
        }

    }

}
