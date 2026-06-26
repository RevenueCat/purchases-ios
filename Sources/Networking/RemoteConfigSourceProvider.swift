//
//  RemoteConfigSourceProvider.swift
//  RevenueCat
//
//  Created by Antonio Pallares on 26/06/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

/// A remote config source, plus the metadata used to order sources.
protocol RemoteConfigSource: WeightedSource {

    /// A plain URL or a URL format with placeholders (e.g. `{blob_ref}`), to be resolved by the caller.
    var url: String { get }

}

/// An endpoint handed out by a `RemoteConfigSourceProvider`. The `token` lets the provider ignore
/// `reportUnhealthy(_:)` calls about an endpoint it has already moved past.
struct RemoteConfigEndpoint<Source: RemoteConfigSource> {

    let source: Source

    fileprivate let token: UUID

    var url: String { self.source.url }

    fileprivate init(source: Source, token: UUID) {
        self.source = source
        self.token = token
    }

}

/// Hands out the current healthy remote config endpoint and falls back to the next one when the
/// current endpoint is reported unhealthy. Order is computed once via `WeightedSourceSelector`.
///
/// - Note: Thread-safe. If several callers hold the same endpoint and all report it unhealthy, only
///   the first report advances; the rest carry a stale `token` and are ignored, so a single failing
///   endpoint can't advance the order more than once.
final class RemoteConfigSourceProvider<Source: RemoteConfigSource> {

    private let selector: WeightedSourceSelector<Source>
    private let lock = Lock()

    /// Regenerated on every `advance()` so previously handed-out endpoints become stale.
    private var currentToken = UUID()

    init(sources: [Source], randomizer: WeightedSourceRandomizer? = nil) {
        self.selector = WeightedSourceSelector(sources: sources, randomizer: randomizer)
    }

    /// The current healthy endpoint, or `nil` once every source has been reported unhealthy.
    var currentEndpoint: RemoteConfigEndpoint<Source>? {
        return self.lock.perform {
            self.makeCurrentEndpoint()
        }
    }

    /// Advances to the next source so the next `currentEndpoint` read returns it. No-op if `endpoint`
    /// is no longer the current one.
    func reportUnhealthy(_ endpoint: RemoteConfigEndpoint<Source>) {
        self.lock.perform {
            guard endpoint.token == self.currentToken else { return }
            self.advance()
        }
    }

    /// Rewinds to the first source in the fallback order, e.g. to start fresh on a new fetch cycle.
    func restart() {
        self.lock.perform {
            self.selector.reset()
            self.currentToken = UUID()
        }
    }

    /// Moves to the next source and invalidates previously handed-out endpoints.
    /// Must be called while holding `lock`.
    private func advance() {
        self.selector.advance()
        self.currentToken = UUID()
    }

    /// Must be called while holding `lock`.
    private func makeCurrentEndpoint() -> RemoteConfigEndpoint<Source>? {
        guard let source = self.selector.current else { return nil }
        return RemoteConfigEndpoint(source: source, token: self.currentToken)
    }

}
