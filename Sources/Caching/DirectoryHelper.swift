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
//  Created by Rick van der Linden on 15/1/26.
//

import Foundation

enum DirectoryHelper {

    enum DirectoryType {
        case cache
        case applicationSupport
    }

    static func baseUrl(for type: DirectoryType) -> URL? {
        guard let baseDirectory = type.url, let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return nil
        }

        let revenueCatFolder = "\(bundleIdentifier).revenuecat"

        return baseDirectory.appendingPathComponent(revenueCatFolder)
    }
}

fileprivate extension DirectoryHelper.DirectoryType {
    var url: URL? {
        switch self {
        case .cache:
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                return URL.cachesDirectory
            } else {
                return FileManager.default.urls(
                    for: .cachesDirectory,
                    in: .userDomainMask
                ).first
            }
        case .applicationSupport:
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                return URL.applicationSupportDirectory
            } else {
                return try? FileManager.default.url(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
            }
        }
    }
}
