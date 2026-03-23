//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DirectoryHelper.swift
//
//  Created by Rick van der Linden on 7/1/26.
//

import Foundation

enum DirectoryHelper {

    enum DirectoryType {
        case cache(overrideURL: URL? = nil)
        /// tvOS sandbox only allows writes under `Library/Caches` on physical devices.
        /// See "Local Storage for Your App Is Limited" in the App Programming Guide for tvOS:
        /// https://developer.apple.com/library/archive/documentation/General/Conceptual/AppleTV_PG/
        @available(tvOS, unavailable)
        case applicationSupport(overrideURL: URL? = nil)
    }

    /// The raw base persistence directory in the app's container for the current platform.
    /// On tvOS this is `Library/Caches`; on all other platforms it is `Library/Application Support`.
    /// Does **not** include the app-specific `{bundleId}.revenuecat` subdirectory.
    static var defaultPersistenceBaseUrl: URL? {
//        #if os(tvOS)
        let directoryType = DirectoryType.cache()
//        #else
//        let directoryType = DirectoryType.applicationSupport()
//        #endif
        return Self.baseUrl(for: directoryType, inAppSpecificDirectory: false)
    }

    static func baseUrl(for type: DirectoryType, inAppSpecificDirectory: Bool = true) -> URL? {
        guard let baseDirectory = type.url else {
            return nil
        }

        guard inAppSpecificDirectory else {
            return baseDirectory
        }

        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return nil
        }

        let appSpecificRevenueCatDirectory = "\(bundleIdentifier).revenuecat"

        return baseDirectory.appendingPathComponent(appSpecificRevenueCatDirectory)
    }
}

fileprivate extension DirectoryHelper.DirectoryType {
    var url: URL? {
        switch self {
        case .cache(let overrideURL):
            if let overrideURL {
                return overrideURL
            }

            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                return URL.cachesDirectory
            } else {
                return FileManager.default.urls(
                    for: .cachesDirectory,
                    in: .userDomainMask
                ).first
            }
        #if !os(tvOS)
        case .applicationSupport(let overrideURL):
            if let overrideURL {
                return overrideURL
            }

            if #available(iOS 16.0, macOS 13.0, watchOS 9.0, *) {
                return URL.applicationSupportDirectory
            } else {
                return try? FileManager.default.url(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
            }
        #endif
        }
    }
}
