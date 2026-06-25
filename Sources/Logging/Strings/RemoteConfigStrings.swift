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
    case failedToWriteCache

}

extension RemoteConfigStrings: LogMessage {

    var description: String {
        switch self {
        case .cacheURLNotAvailable:
            return "Remote config cache URL is not available."
        case let .failedToReadCache(error):
            return "Failed to read remote config cache from disk: \(error.localizedDescription)"
        case .failedToWriteCache:
            return "Failed to write remote config cache to disk."
        }
    }

    var category: String { return "remote_config" }

}
