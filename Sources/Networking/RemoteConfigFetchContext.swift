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
/// Each case maps to the SDK situation that triggered the config fetch. The raw `String` value is sent in the
/// remote config request body as the `fetch_context` field.
enum RemoteConfigFetchContext: String, Codable, Equatable {
    case appStart = "app_start"
    case foreground = "foreground"
    case identityChange = "identity_change"
    case read = "read"
}
