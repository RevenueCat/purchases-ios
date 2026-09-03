//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageSelectionAnnouncement.swift
//
//  Created by Michael S. Muegel on 8/28/26.

import SwiftUI

#if !os(tvOS) // For Paywalls V2

/// The spoken selection state of the package being rendered — "Selected" or "Not selected" —
/// carried down so the package's first text component can announce it right after the offer's
/// name, rather than after all of its pricing detail.
struct PackageSelectionAnnouncementKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {

    var packageSelectionAnnouncement: String? {
        get { self[PackageSelectionAnnouncementKey.self] }
        set { self[PackageSelectionAnnouncementKey.self] = newValue }
    }

}

#endif
