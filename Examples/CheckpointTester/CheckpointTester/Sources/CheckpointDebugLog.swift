//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointDebugLog.swift
//

import Foundation
import RevenueCat

/// A single running log of checkpoint activity: request/result lines recorded directly by this app,
/// interleaved with the SDK's own ad-presentation and reward-verification-polling log lines, so this
/// demo app can show the whole story on screen instead of requiring the Xcode console.
@MainActor
final class CheckpointDebugLog: ObservableObject {

    static let shared = CheckpointDebugLog()

    @Published private(set) var lines: [String] = []

    private init() {}

    func clear() {
        self.lines = []
    }

    func record(_ message: String) {
        self.lines.append(message)
    }

    /// Installs a `Purchases.logHandler` that forwards ad-presentation and reward-verification-polling
    /// messages here. Every message this SDK version logs about presenting a checkpoint ad or polling a
    /// reward starts with "Presenting checkpoint ad" / "Reward verification" (see `CheckpointPresenterStrings`
    /// in the AdMob adapter and `AdsStrings` in the core SDK), so that's used as the filter rather than a
    /// level/category check.
    static func install() {
        Purchases.verboseLogs = true
        Purchases.logHandler = { level, message in
            print("[\(level)] \(message)")
            guard message.contains("Reward verification") || message.contains("Presenting checkpoint ad") else {
                return
            }
            Task { @MainActor in
                Self.shared.record(message)
            }
        }
    }

}
