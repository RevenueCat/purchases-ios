//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LaunchMeasurement.swift
//
//  Created by Facundo Menzella on 9/7/26.

import Foundation

/// One app launch's phase timings, measured from process start (`LaunchClock` creation in
/// the `App` initializer). Encoded as JSON into the `benchmark-result` accessibility element
/// so the XCUITest runner can collect it; also compiled into the benchmark unit-test target.
struct LaunchSample: Codable, Equatable {

    /// Milliseconds until `Purchases.configure` returned.
    var configuredMs: Double?
    /// Milliseconds until the first `CustomerInfo` was delivered.
    var customerInfoMs: Double?
    /// Milliseconds until `getOfferings` completed.
    var offeringsMs: Double?
    /// Milliseconds until the rendered `PaywallView` appeared.
    var paywallAppearedMs: Double?
    /// Non-nil when the launch could not complete; the runner fails loudly on it.
    var error: String?

    func jsonString() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(self),
              let json = String(data: data, encoding: .utf8) else {
            return "{\"error\":\"encoding-failed\"}"
        }
        return json
    }

    static func decode(from json: String) -> LaunchSample? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(LaunchSample.self, from: data)
    }

}

/// Monotonic clock anchored at creation. Created as the first stored property of the `App`
/// type so elapsed values approximate time-since-process-start for the phases we control.
final class LaunchClock: Sendable {

    private let start = DispatchTime.now()

    func elapsedMs() -> Double {
        let nanos = DispatchTime.now().uptimeNanoseconds - self.start.uptimeNanoseconds
        return Double(nanos) / 1_000_000
    }

}
