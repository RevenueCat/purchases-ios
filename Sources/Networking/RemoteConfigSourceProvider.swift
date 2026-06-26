//
//  RemoteConfigSourceProvider.swift
//  RevenueCat
//
//  Created by Antonio Pallares on 26/06/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

/// A remote config source: a URL plus the metadata used to order sources.
struct RemoteConfigSource {

    /// A plain URL or a URL format with placeholders (e.g. `{blob_ref}`), to be resolved by the caller.
    let url: String
    let priority: Int
    let weight: Int

}

/// The api and blob sources for the remote config, as provided by the `sources` topic.
struct RemoteConfigSources {

    let api: [RemoteConfigSource]
    let blob: [RemoteConfigSource]

}

/// An endpoint handed out by a `RemoteConfigSourceProvider`. Report it back via `reportUnhealthy(_:)`
/// to fall back to the next source. The `url` is its identity: a report is ignored once the provider
/// has already moved past that url.
struct RemoteConfigEndpoint: WeightedSource {

    enum Kind {
        case api
        case blob
    }

    let kind: Kind
    let source: RemoteConfigSource

    /// A plain URL or a URL format with placeholders, to be resolved by the caller.
    var url: String { self.source.url }
    var priority: Int { self.source.priority }
    var weight: Int { self.source.weight }

}

protocol RemoteConfigSourceProviderType: AnyObject {

    /// The current healthy api endpoint, or `nil` once every api source has been reported unhealthy.
    var currentAPIEndpoint: RemoteConfigEndpoint? { get }

    /// The current healthy blob endpoint, or `nil` once every blob source has been reported unhealthy.
    var currentBlobEndpoint: RemoteConfigEndpoint? { get }

    /// Falls back to the next source for the endpoint's kind. No-op if `endpoint` is no longer current.
    func reportUnhealthy(_ endpoint: RemoteConfigEndpoint)

    /// Rewinds the given kind to its first source, e.g. to start fresh on a new fetch cycle.
    func restart(_ kind: RemoteConfigEndpoint.Kind)

}

/// The address book for remote config: hands out the current healthy api and blob endpoints and
/// falls back to the next one when an endpoint is reported unhealthy. Each kind fails over
/// independently. Sources are deduped by url and ordered once via `WeightedSourceSelector`.
///
/// - Note: Thread-safe.
final class RemoteConfigSourceProvider: RemoteConfigSourceProviderType {

    private let api: SourceFailover
    private let blob: SourceFailover

    init(sources: RemoteConfigSources, randomizer: WeightedSourceRandomizer? = nil) {
        self.api = SourceFailover(endpoints: Self.endpoints(from: sources.api, kind: .api), randomizer: randomizer)
        self.blob = SourceFailover(endpoints: Self.endpoints(from: sources.blob, kind: .blob), randomizer: randomizer)
    }

    var currentAPIEndpoint: RemoteConfigEndpoint? {
        return self.api.current
    }

    var currentBlobEndpoint: RemoteConfigEndpoint? {
        return self.blob.current
    }

    func reportUnhealthy(_ endpoint: RemoteConfigEndpoint) {
        switch endpoint.kind {
        case .api: self.api.reportUnhealthy(url: endpoint.url)
        case .blob: self.blob.reportUnhealthy(url: endpoint.url)
        }
    }

    func restart(_ kind: RemoteConfigEndpoint.Kind) {
        switch kind {
        case .api: self.api.restart()
        case .blob: self.blob.restart()
        }
    }

    /// Builds the endpoints for a kind, collapsing duplicate urls to the occurrence with the highest
    /// priority (tie-broken by weight). Done once here so endpoints never need to be rebuilt on reads.
    private static func endpoints(
        from sources: [RemoteConfigSource],
        kind: RemoteConfigEndpoint.Kind
    ) -> [RemoteConfigEndpoint] {
        var bestByURL: [String: RemoteConfigSource] = [:]
        var order: [String] = []
        for source in sources {
            guard let existing = bestByURL[source.url] else {
                bestByURL[source.url] = source
                order.append(source.url)
                continue
            }
            if source.priority != existing.priority || source.weight != existing.weight {
                Logger.debug(Strings.remoteConfig.duplicateSourceURL(source.url))
            }
            if source.priority > existing.priority ||
                (source.priority == existing.priority && source.weight > existing.weight) {
                bestByURL[source.url] = source
            }
        }
        return order.compactMap { url in
            bestByURL[url].map { RemoteConfigEndpoint(kind: kind, source: $0) }
        }
    }

}

/// Walks a single list of endpoints in fallback order, using each endpoint's url as its identity so a
/// stale `reportUnhealthy(url:)` (one the list has already moved past) is ignored.
///
/// - Note: Thread-safe.
private final class SourceFailover {

    private let selector: WeightedSourceSelector<RemoteConfigEndpoint>
    private let lock = Lock()

    init(endpoints: [RemoteConfigEndpoint], randomizer: WeightedSourceRandomizer?) {
        self.selector = WeightedSourceSelector(sources: endpoints, randomizer: randomizer)
    }

    var current: RemoteConfigEndpoint? {
        return self.lock.perform { self.selector.current }
    }

    func reportUnhealthy(url: String) {
        self.lock.perform {
            // Only advance when the report is about the current endpoint: a url the list has already
            // moved past (e.g. from a concurrent caller) no longer matches, so it can't advance twice.
            guard self.selector.current?.url == url else { return }
            self.selector.advance()
        }
    }

    func restart() {
        self.lock.perform { self.selector.reset() }
    }

}
