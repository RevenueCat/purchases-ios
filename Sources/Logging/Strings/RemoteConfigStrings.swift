//
//  RemoteConfigStrings.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

enum RemoteConfigStrings {

    case failedToReadCache(Error)
    case failedToWriteCache
    case failedToParseResponse(Error)
    case refreshFailed(BackendError)

}

extension RemoteConfigStrings: LogMessage {

    var description: String {
        switch self {
        case let .failedToReadCache(error):
            return "Failed to read remote config cache from disk: \(error.localizedDescription)"
        case .failedToWriteCache:
            return "Failed to write remote config cache to disk."
        case let .failedToParseResponse(error):
            return "Failed to parse remote config response. Keeping cached configuration. Error: " +
            "\(error.localizedDescription)"
        case let .refreshFailed(error):
            return "Remote config refresh failed. Keeping cached configuration. Error: \(error)"
        }
    }

    var category: String { return "remote_config" }

}
