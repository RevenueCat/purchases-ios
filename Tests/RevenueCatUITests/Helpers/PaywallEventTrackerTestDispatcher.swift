//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Created by Monika Mateska on 09/04/2026.

import Foundation
@testable import RevenueCatUI

/// Test-only paywall event scheduling: uses `Task { }` so work inherits the caller's actor context.
/// Prefer this over ``PaywallEventTracker/dispatcher()`` in tests that assert on tracked events,
/// because `Task.detached(priority: .background)` can delay delivery on some CI environments.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum PaywallEventTrackerTestDispatcher {

    static let value: PaywallEventTracker.EventDispatcher = { work in
        Task { await work() }
    }

}
