//
//  RemoteConfigStrings.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

enum RemoteConfigStrings {

    case cacheURLNotAvailable
    case failedToReadCache(Error)
    case failedToWriteCache(Error)

}

extension RemoteConfigStrings: LogMessage {

    var description: String {
        switch self {
        case .cacheURLNotAvailable:
            return "Remote config cache URL is not available."
        case let .failedToReadCache(error):
            return "Failed to read remote config cache from disk: \(error.localizedDescription)"
        case let .failedToWriteCache(error):
            return "Failed to write remote config cache to disk: \(error.localizedDescription)"
        }
    }

    var category: String { return "remote_config" }

}
