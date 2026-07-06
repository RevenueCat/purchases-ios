//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferingsConfigGate.swift
//
//  Created by RevenueCat.

import Foundation

/// Gates offerings delivery on remote-config readiness — the config-endpoint replacement for the old
/// "wait for the workflows list before returning offerings" behavior.
///
/// `OfferingsManager` stays ignorant of which config topic matters: it just calls `awaitReady` and
/// delivers in the completion. When no gate is wired, offerings deliver immediately.
protocol OfferingsConfigGate {

    func awaitReady(completion: @escaping () -> Void)

}

/// Backed by `RemoteConfigManager`: "ready" means the `workflows` topic has synced at least once.
/// `RemoteConfigManager.topic(_:)` returns immediately from disk once a topic has synced, so this
/// only blocks (or triggers a refresh) on a true cold start; it never forces a fresh sync on an
/// already-populated topic. Ongoing staleness is handled independently by the SDK's foreground/launch
/// remote-config refresh, not by this gate.
final class RemoteConfigOfferingsConfigGate: OfferingsConfigGate {

    private let remoteConfigManager: RemoteConfigManagerType

    init(remoteConfigManager: RemoteConfigManagerType) {
        self.remoteConfigManager = remoteConfigManager
    }

    func awaitReady(completion: @escaping () -> Void) {
        Task {
            _ = await self.remoteConfigManager.topic(.workflows)
            completion()
        }
    }

}
