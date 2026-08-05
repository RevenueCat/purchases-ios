//
//  RemoteConfigTopic.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

/// Remote config topics that SDK code can read through `RemoteConfigManager`.
///
/// The sync path remains string-keyed so unknown server topics can still be persisted.
/// The read facade uses this closed set to avoid arbitrary or misspelled topic reads.
enum RemoteConfigTopic: String {

    case workflows
    case uiConfig = "ui_config"
    case sources

    var wireName: String {
        return self.rawValue
    }

}
