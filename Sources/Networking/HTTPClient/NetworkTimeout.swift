//
//  NetworkTimeout.swift
//  RevenueCat
//
//  Created by Antonio Pallares on 13/7/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation

/// Represents how HTTP request timeouts are computed.
///
/// By default the SDK uses a set of built-in per-request timeout tiers (see
/// ``HTTPRequestTimeoutManager/Timeout``). When the developer explicitly sets a timeout via
/// `Configuration/Builder/with(networkTimeout:)`, that value replaces the built-in base/flat
/// tiers for every request kind, while the reduced fail-fast tiers stay fixed.
enum NetworkTimeout: Equatable, Hashable {

    /// Use the SDK's built-in per-request timeout tiers.
    case `default`

    /// Use a developer-provided timeout for the base/flat tiers.
    case custom(TimeInterval)
}

extension NetworkTimeout {

    /// The overall timeout ceiling applied at the `URLSession` level
    /// (`timeoutIntervalForRequest`/`timeoutIntervalForResource`).
    var timeoutInterval: TimeInterval {
        switch self {
        case .default: return Configuration.networkTimeoutDefault
        case let .custom(value): return value
        }
    }
}
