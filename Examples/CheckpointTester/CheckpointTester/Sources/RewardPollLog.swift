//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardPollLog.swift
//

import Foundation
import RevenueCat

/// Captures the SDK's own reward-verification-polling log lines so this demo app can show them on screen,
/// instead of requiring the Xcode console to see what each poll attempt returned.
@MainActor
final class RewardPollLog: ObservableObject {

    static let shared = RewardPollLog()

    @Published private(set) var lines: [String] = []

    private init() {}

    func clear() {
        self.lines = []
    }

    fileprivate func record(_ message: String) {
        self.lines.append(message)
    }

    /// Installs a `Purchases.logHandler` that forwards only reward-verification-polling messages here.
    /// Every message this SDK version logs about a poll starts with "Reward verification" (see
    /// `AdsStrings` in the core SDK), so that's used as the filter rather than a level/category check.
    static func install() {
        Purchases.verboseLogs = true
        Purchases.logHandler = { level, message in
            print("[\(level)] \(message)")
            guard message.contains("Reward verification") else { return }
            Task { @MainActor in
                Self.shared.record(message)
            }
        }
    }

}
