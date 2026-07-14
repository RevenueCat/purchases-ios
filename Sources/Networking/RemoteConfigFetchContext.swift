//
//  RemoteConfigFetchContext.swift
//  RevenueCat
//
//  Created by Antonio Pallares.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation

/// Describes why the SDK is requesting remote config.
///
/// Each case maps to the SDK situation that triggered the config fetch. The raw `String` value is sent on the wire
/// in the `fetch_context` request field.
enum RemoteConfigFetchContext: String, Codable, Equatable {
    case appStart = "app_start"
    case foreground = "foreground"
    case identityChange = "identity_change"
    case read = "read"
}
