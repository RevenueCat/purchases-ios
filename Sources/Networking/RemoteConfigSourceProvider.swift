//
//  RemoteConfigSourceProvider.swift
//  RevenueCat
//
//  Created by Antonio Pallares on 26/06/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

/// A remote config source: a URL plus the metadata used to order sources.
struct RemoteConfigSource: WeightedSource {

    /// A plain URL or a URL format with placeholders (e.g. `{blob_ref}`), to be resolved by the caller.
    let url: String
    let priority: Int
    let weight: Int

}

/// A source handed out by a `RemoteConfigSourceProvider`, tagged with its purpose (api or blob).
/// Report it back via `reportUnhealthy(_:)` to fall back to the next source. The opaque `token`
/// is its identity: a report is ignored once the provider has moved past it (via fallback or
/// `restart(for:)`), so stale or concurrent reports can't advance the order more than once.
struct RemoteConfigSourceHandle {

    /// What the source is used for: calling the config api or downloading a blob.
    enum Purpose {
        case api
        case blob
    }

    let purpose: Purpose
    let source: RemoteConfigSource

    /// Identifies the handout that produced this handle. Opaque to callers; only meaningful to the
    /// provider, which uses it to discard stale reports.
    fileprivate let token: Int

    /// A plain URL or a URL format with placeholders, to be resolved by the caller.
    var url: String { self.source.url }

    fileprivate init(purpose: Purpose, source: RemoteConfigSource, token: Int) {
        self.purpose = purpose
        self.source = source
        self.token = token
    }

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
        self.api = SourceFailover(purpose: .api, sources: Self.dedupe(apiSources), randomizer: randomizer)
        self.blob = SourceFailover(purpose: .blob, sources: Self.dedupe(blobSources), randomizer: randomizer)
    }

    func getCurrent(for purpose: RemoteConfigSourceHandle.Purpose) -> RemoteConfigSourceHandle? {
        switch purpose {
        case .api: return self.api.current
        case .blob: return self.blob.current
        }
    }

    func reportUnhealthy(_ handle: RemoteConfigSourceHandle) {
        switch handle.purpose {
        case .api: self.api.reportUnhealthy(handle)
        case .blob: self.blob.reportUnhealthy(handle)
        }
    }

    func restart(for purpose: RemoteConfigSourceHandle.Purpose) {
        switch purpose {
        case .api: self.api.restart()
        case .blob: self.blob.restart()
        }
    }

    /// Collapses duplicate urls to the occurrence with the highest priority (i.e. the lowest
    /// `priority` number, tie-broken by weight), keeping first-seen order. Done once at init so
    /// reads never need to re-dedupe.
    private static func dedupe(_ sources: [RemoteConfigSource]) -> [RemoteConfigSource] {
        var bestByURL: [String: RemoteConfigSource] = [:]
        var order: [String] = []
        for source in sources {
            guard let existing = bestByURL[source.url] else {
                bestByURL[source.url] = source
                order.append(source.url)
                continue
            }
            if source.priority != existing.priority || source.weight != existing.weight {
                Logger.warn(Strings.remoteConfig.duplicateSourceURL(source.url))
            }
            if source.priority < existing.priority ||
                (source.priority == existing.priority && source.weight > existing.weight) {
                bestByURL[source.url] = source
            }
        }
        return order.compactMap { bestByURL[$0] }
    }

}

/// Walks a single list of sources in fallback order. Every handout is stamped with the current
/// `token`, which is bumped whenever the position changes (fallback or `restart()`). A report only
/// advances if its handle still carries the current token, so stale or concurrent reports - and
/// reports left over from before a `restart()` - are ignored.
///
/// - Note: Thread-safe.
private final class SourceFailover {

    private let purpose: RemoteConfigSourceHandle.Purpose
    private let selector: WeightedSourceSelector<RemoteConfigSource>
    private let lock = Lock()
    private var token = 0

    init(
        purpose: RemoteConfigSourceHandle.Purpose,
        sources: [RemoteConfigSource],
        randomizer: WeightedSourceRandomizer?
    ) {
        self.purpose = purpose
        self.selector = WeightedSourceSelector(sources: sources, randomizer: randomizer)
    }

    var current: RemoteConfigSourceHandle? {
        return self.lock.perform {
            self.selector.current.map {
                RemoteConfigSourceHandle(purpose: self.purpose, source: $0, token: self.token)
            }
        }
    }

    func reportUnhealthy(_ handle: RemoteConfigSourceHandle) {
        self.lock.perform {
            guard handle.token == self.token else { return }
            self.selector.advance()
            self.token += 1
        }
    }

    func restart() {
        self.lock.perform {
            self.selector.reset()
            self.token += 1
        }
    }

}
