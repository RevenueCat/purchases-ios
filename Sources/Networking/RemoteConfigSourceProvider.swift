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

/// Used by the networking layer to resolve the API base host and drive failover across API sources
protocol APISourceProviding: AnyObject {

    /// The current healthy API base source, or `nil` once every API source has been reported unhealthy.
    func currentAPISource() -> RemoteConfigSourceHandle?

    /// Reports the given API source as unhealthy so the next `currentAPISource()` advances past it.
    /// No-op if `handle` is no longer the current source (stale/concurrent reports are ignored).
    func reportUnhealthy(_ handle: RemoteConfigSourceHandle)

}

protocol RemoteConfigSourceProviderType: APISourceProviding {

    /// The current healthy source for `purpose`, or `nil` once all of its sources are reported unhealthy.
    func getCurrent(for purpose: RemoteConfigSourceHandle.Purpose) -> RemoteConfigSourceHandle?

    /// Falls back to the next source for the handle's purpose. No-op if `handle` is no longer current.
    func reportUnhealthy(_ handle: RemoteConfigSourceHandle)

    /// Rewinds the given purpose to its first source, e.g. to start fresh on a new fetch cycle.
    func restart(for purpose: RemoteConfigSourceHandle.Purpose)

    /// Rewinds the given purpose only if every known source for it has already been exhausted.
    @discardableResult
    func restartIfExhausted(for purpose: RemoteConfigSourceHandle.Purpose) -> Bool

}

extension RemoteConfigSourceProviderType {

    func currentAPISource() -> RemoteConfigSourceHandle? {
        return self.getCurrent(for: .api)
    }

}

/// Read-only access to a topic's persisted item index (metadata only — no blob bytes, no waiting).
protocol RemoteConfigTopicStoreType: AnyObject {

    /// The saved items for `name`, or `nil` when the topic is unknown / nothing has been persisted yet.
    func topic(_ name: String) -> RemoteConfiguration.ConfigTopic?

}

/// The address book for remote config: hands out the current healthy api and blob sources and
/// falls back to the next one when a source is reported unhealthy. Each purpose fails over
/// independently.
///
/// Reads the `sources` topic lazily from the topic store and rebuilds its ordered lists only when
/// that topic changes: an unchanged topic keeps failover progress, while a changed one restarts both
/// lists from the top. While the topic has no usable api sources, it falls back to an embedded
/// default so the SDK can reach the config api before any config is fetched. Blob sources have no
/// embedded default: they are only useful alongside a fetched config, which carries its own. Sources
/// are deduped by url and ordered via `WeightedSourceSelector`.
///
/// - Note: Thread-safe.
final class RemoteConfigSourceProvider: RemoteConfigSourceProviderType {

    private static let sourcesTopicName = "sources"
    private static let apiItem = "api"
    private static let blobItem = "blob"
    private static let sourcesKey = "sources"
    private static let urlKey = "url"
    private static let urlFormatKey = "url_format"
    private static let priorityKey = "priority"
    private static let weightKey = "weight"

    // Embedded api defaults used until a `sources` topic is fetched, so the SDK can always reach
    // config. Their very high `priority` numbers keep them below anything a fetched topic provides
    // (lower number wins), so they only act as a fallback.
    private static let defaultAPISources = [
        RemoteConfigSource(url: "https://api.revenuecat.com/", priority: 100_000, weight: 1),
        RemoteConfigSource(url: "https://api.rc-backup.com/", priority: 100_001, weight: 1)
    ]

    private let topicStore: RemoteConfigTopicStoreType
    private let randomizer: WeightedSourceRandomizer?
    private let lock = Lock()

    /// Topic the current failovers were built from. `nil` means there is no sources topic (absent, or
    /// none seen yet), in which case the failovers hold the embedded defaults.
    private var sourcesTopic: RemoteConfiguration.ConfigTopic?
    private var api: SourceFailover
    private var blob: SourceFailover

    init(
        topicStore: RemoteConfigTopicStoreType,
        randomizer: WeightedSourceRandomizer? = nil
    ) {
        self.topicStore = topicStore
        self.randomizer = randomizer
        self.api = SourceFailover(
            purpose: .api,
            sources: Self.dedupe(Self.sources(from: nil, for: .api)),
            randomizer: randomizer
        )
        self.blob = SourceFailover(
            purpose: .blob,
            sources: Self.dedupe(Self.sources(from: nil, for: .blob)),
            randomizer: randomizer
        )
    }

    func getCurrent(for purpose: RemoteConfigSourceHandle.Purpose) -> RemoteConfigSourceHandle? {
        return self.lock.perform {
            self.rebuildIfNeeded()
            return self.failover(for: purpose).current
        }
    }

    func reportUnhealthy(_ handle: RemoteConfigSourceHandle) {
        self.lock.perform {
            // Rebuild happened, no need to report unhealthy
            if !self.rebuildIfNeeded() {
                self.failover(for: handle.purpose).reportUnhealthy(handle)
            }
        }
    }

    func restart(for purpose: RemoteConfigSourceHandle.Purpose) {
        self.lock.perform {
            // Rebuild happened, no need to restart
            if !self.rebuildIfNeeded() {
                self.failover(for: purpose).restart()
            }
        }
    }

    @discardableResult
    func restartIfExhausted(for purpose: RemoteConfigSourceHandle.Purpose) -> Bool {
        return self.lock.perform {
            if self.rebuildIfNeeded() {
                return true
            }

            let failover = self.failover(for: purpose)
            guard failover.current == nil else { return false }

            failover.restart()
            return true
        }
    }

    private func failover(for purpose: RemoteConfigSourceHandle.Purpose) -> SourceFailover {
        switch purpose {
        case .api: return self.api
        case .blob: return self.blob
        }
    }

    /// Rebuilds both failovers from the latest `sources` topic when it changed, returning whether a
    /// rebuild happened. Callers must hold `lock`.
    @discardableResult
    private func rebuildIfNeeded() -> Bool {
        let topic = self.topicStore.topic(Self.sourcesTopicName)
        guard topic != self.sourcesTopic else { return false }

        // Seed the new generation past any token the previous one could have handed out, so reports
        // left over from before the rebuild are ignored instead of advancing the freshly-restarted list.
        let nextToken = max(self.api.currentToken, self.blob.currentToken) + 1
        self.api = SourceFailover(
            purpose: .api,
            sources: Self.dedupe(Self.sources(from: topic, for: .api)),
            randomizer: self.randomizer,
            initialToken: nextToken
        )
        self.blob = SourceFailover(
            purpose: .blob,
            sources: Self.dedupe(Self.sources(from: topic, for: .blob)),
            randomizer: self.randomizer,
            initialToken: nextToken
        )
        self.sourcesTopic = topic
        return true
    }

    /// The sources for `purpose`, parsed from the `sources` `topic`. Api falls back to the embedded
    /// default while the topic has no usable api sources; blob has no default, so it can be empty.
    private static func sources(
        from topic: RemoteConfiguration.ConfigTopic?,
        for purpose: RemoteConfigSourceHandle.Purpose
    ) -> [RemoteConfigSource] {
        switch purpose {
        case .api:
            let parsed = topic.map { Self.parseSources($0, item: Self.apiItem, urlKey: Self.urlKey) } ?? []
            return parsed.isEmpty ? Self.defaultAPISources : parsed
        case .blob:
            return topic.map { Self.parseSources($0, item: Self.blobItem, urlKey: Self.urlFormatKey) } ?? []
        }
    }

    /// Extracts the source list from the `sources` topic item `item` (`api` or `blob`), reading each
    /// entry's url from `urlKey` (`url` for api, `url_format` for blob). Malformed entries are skipped.
    private static func parseSources(
        _ topic: RemoteConfiguration.ConfigTopic,
        item: String,
        urlKey: String
    ) -> [RemoteConfigSource] {
        guard case .array(let entries)? = topic[item]?.content[Self.sourcesKey] else {
            return []
        }
        return entries.compactMap { element in
            guard case .object(let object) = element,
                  case .string(let url)? = object[urlKey],
                  case .int(let priority)? = object[Self.priorityKey],
                  case .int(let weight)? = object[Self.weightKey] else {
                return nil
            }
            return RemoteConfigSource(url: url, priority: priority, weight: weight)
        }
    }

    /// Collapses duplicate urls to the occurrence with the highest priority (i.e. the lowest
    /// `priority` number, tie-broken by weight), keeping first-seen order. Done once per rebuild so
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
/// - Note: Not thread-safe on its own: `RemoteConfigSourceProvider` serializes every access under its
/// own lock.
private final class SourceFailover {

    private let purpose: RemoteConfigSourceHandle.Purpose
    private let selector: WeightedSourceSelector<RemoteConfigSource>
    private var token: Int

    init(
        purpose: RemoteConfigSourceHandle.Purpose,
        sources: [RemoteConfigSource],
        randomizer: WeightedSourceRandomizer?,
        initialToken: Int = 0
    ) {
        self.purpose = purpose
        self.selector = WeightedSourceSelector(sources: sources, randomizer: randomizer)
        self.token = initialToken
    }

    /// The token a handle handed out right now would carry. Used to seed the next generation on rebuild.
    var currentToken: Int {
        return self.token
    }

    var current: RemoteConfigSourceHandle? {
        return self.selector.current.map {
            RemoteConfigSourceHandle(purpose: self.purpose, source: $0, token: self.token)
        }
    }

    func reportUnhealthy(_ handle: RemoteConfigSourceHandle) {
        guard handle.token == self.token else { return }
        self.selector.advance()
        self.token += 1
    }

    func restart() {
        self.selector.reset()
        self.token += 1
    }

}
