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

/// A source handed out by a `RemoteConfigSourceProvider`, tagged with its purpose (api or blob).
/// Report it back via `reportUnhealthy(_:)` to fall back to the next source. The `url` is its
/// identity: a report is ignored once the provider has already moved past that url.
struct RemoteConfigSourceHandle: WeightedSource {

    /// What the source is used for: calling the config api or downloading a blob.
    enum Purpose {
        case api
        case blob
    }

    let purpose: Purpose
    let source: RemoteConfigSource

    /// A plain URL or a URL format with placeholders, to be resolved by the caller.
    var url: String { self.source.url }
    var priority: Int { self.source.priority }
    var weight: Int { self.source.weight }

}

protocol RemoteConfigSourceProviderType: AnyObject {

    /// The current healthy source for `purpose`, or `nil` once all of its sources are reported unhealthy.
    func getCurrent(for purpose: RemoteConfigSourceHandle.Purpose) -> RemoteConfigSourceHandle?

    /// Falls back to the next source for the handle's purpose. No-op if `handle` is no longer current.
    func reportUnhealthy(_ handle: RemoteConfigSourceHandle)

    /// Rewinds the given purpose to its first source, e.g. to start fresh on a new fetch cycle.
    func restart(for purpose: RemoteConfigSourceHandle.Purpose)

}

/// The address book for remote config: hands out the current healthy api and blob sources and
/// falls back to the next one when a source is reported unhealthy. Each purpose fails over
/// independently. Sources are deduped by url and ordered once via `WeightedSourceSelector`.
///
/// - Note: Thread-safe.
final class RemoteConfigSourceProvider: RemoteConfigSourceProviderType {

    private let api: SourceFailover
    private let blob: SourceFailover

    init(
        apiSources: [RemoteConfigSource],
        blobSources: [RemoteConfigSource],
        randomizer: WeightedSourceRandomizer? = nil
    ) {
        self.api = SourceFailover(handles: Self.handles(from: apiSources, purpose: .api), randomizer: randomizer)
        self.blob = SourceFailover(handles: Self.handles(from: blobSources, purpose: .blob), randomizer: randomizer)
    }

    func getCurrent(for purpose: RemoteConfigSourceHandle.Purpose) -> RemoteConfigSourceHandle? {
        switch purpose {
        case .api: return self.api.current
        case .blob: return self.blob.current
        }
    }

    func reportUnhealthy(_ handle: RemoteConfigSourceHandle) {
        switch handle.purpose {
        case .api: self.api.reportUnhealthy(url: handle.url)
        case .blob: self.blob.reportUnhealthy(url: handle.url)
        }
    }

    func restart(for purpose: RemoteConfigSourceHandle.Purpose) {
        switch purpose {
        case .api: self.api.restart()
        case .blob: self.blob.restart()
        }
    }

    /// Builds the handles for a purpose, collapsing duplicate urls to the occurrence with the highest
    /// priority (tie-broken by weight). Done once here so handles never need to be rebuilt on reads.
    private static func handles(
        from sources: [RemoteConfigSource],
        purpose: RemoteConfigSourceHandle.Purpose
    ) -> [RemoteConfigSourceHandle] {
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
            bestByURL[url].map { RemoteConfigSourceHandle(purpose: purpose, source: $0) }
        }
    }

}

/// Walks a single list of handles in fallback order, using each handle's url as its identity so a
/// stale `reportUnhealthy(url:)` (one the list has already moved past) is ignored.
///
/// - Note: Thread-safe.
private final class SourceFailover {

    private let selector: WeightedSourceSelector<RemoteConfigSourceHandle>
    private let lock = Lock()

    init(handles: [RemoteConfigSourceHandle], randomizer: WeightedSourceRandomizer?) {
        self.selector = WeightedSourceSelector(sources: handles, randomizer: randomizer)
    }

    var current: RemoteConfigSourceHandle? {
        return self.lock.perform { self.selector.current }
    }

    func reportUnhealthy(url: String) {
        self.lock.perform {
            // Only advance when the report is about the current source: a url the list has already
            // moved past (e.g. from a concurrent caller) no longer matches, so it can't advance twice.
            guard self.selector.current?.url == url else { return }
            self.selector.advance()
        }
    }

    func restart() {
        self.lock.perform { self.selector.reset() }
    }

}
