//
//  RemoteConfigManager.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

// swiftlint:disable file_length

struct RemoteConfigBlobData<Value>: @unchecked Sendable {

    let value: Value
    fileprivate let generation: Int

    init(value: Value, generation: Int) {
        self.value = value
        self.generation = generation
    }

    func isSameGeneration(_ value: Int) -> Bool {
        return self.generation == value
    }

}

protocol RemoteConfigManagerType: AnyObject {

    /// Whether remote config should be ignored for the current manager lifetime.
    var isDisabled: Bool { get }

    /// Monotonically increases whenever committed remote config state is replaced or invalidated.
    var configGeneration: Int { get }

    var onRemoteConfigDisabled: (() -> Void)? { get set }

    func refreshRemoteConfig(fetchContext: RemoteConfigFetchContext, isAppBackgrounded: Bool)
    func refreshRemoteConfigIfStale(fetchContext: RemoteConfigFetchContext, isAppBackgrounded: Bool)

    /// Returns the committed item index for a known topic.
    ///
    /// If the topic is not cached, this waits for an in-flight refresh or triggers one foreground refresh before
    /// reading again. Returns `nil` when the endpoint is disabled or the topic is still unavailable after refresh.
    func topic(_ topic: RemoteConfigTopic) async -> RemoteConfiguration.ConfigTopic?

    /// Returns the blob payload bytes for an item referenced by `blob_ref`.
    ///
    /// Inline item metadata is exposed through `topic(_:)`; items without `blob_ref` return `nil`. Missing items
    /// wait for an in-flight refresh or trigger one foreground refresh before resolving the blob on demand.
    func blobData(for topic: RemoteConfigTopic, itemKey: String) async -> Data?

    /// Returns blob bytes together with the committed config generation that produced them.
    func blobDataSnapshot(for topic: RemoteConfigTopic, itemKey: String) async -> RemoteConfigBlobData<Data>?

    /// Runs `operation` atomically only if `snapshot` still belongs to the current committed config.
    func useIfCurrent<T>(_ snapshot: RemoteConfigBlobData<T>, operation: (T) -> Void) -> Bool

    /// Decodes a blob payload as a concrete `Decodable` type.
    ///
    /// Returns `nil` when the item or blob is unavailable. Throws when bytes are available but cannot be decoded.
    func blobData<T: Decodable>(
        for topic: RemoteConfigTopic,
        itemKey: String,
        as type: T.Type
    ) async throws -> T?

    /// Ensures every blob in `refs` has finished downloading (or failed), joining any already
    /// in-flight or queued (e.g. prefetch) download for the same ref instead of starting a
    /// duplicate. Returns once every ref has settled; the `Bool` reports whether all succeeded.
    @discardableResult
    func ensureBlobsDownloaded(_ refs: [String]) async -> Bool

    /// Decodes multiple blob payloads into one keyed JSON object.
    ///
    /// Each requested item must be backed by `blob_ref`. The merged object is keyed by item key, so item
    /// `translations` contributes to the `translations` field of `T`.
    func mergeItemsBlobData<T: Decodable>(
        for topic: RemoteConfigTopic,
        itemKeys: [String],
        as type: T.Type
    ) async throws -> T?

    /// Returns `topic`'s committed item index once every item flagged for prefetch has also finished
    /// downloading its blob (or failed). Behaves like `topic(_:)` otherwise: waits for an in-flight
    /// refresh or triggers one foreground refresh before reading, and returns `nil` when the endpoint
    /// is disabled or the topic is still unavailable after refresh.
    ///
    /// If the topic is invalidated (e.g. an identity change) while waiting on its blobs, this re-reads
    /// and waits again on the new snapshot's own prefetch refs rather than returning one paired with
    /// stale blob-wait results.
    func awaitTopicAndPrefetchBlobsReady(_ topic: RemoteConfigTopic) async -> RemoteConfiguration.ConfigTopic?

    func clearCache()
    func clearCache(forAppUserID appUserID: String)
    func close()

}

extension RemoteConfigManagerType {

    func withCurrentConfigGeneration<T>(_ operation: (Int) -> T?) -> T? {
        let generation = self.configGeneration
        guard let value = operation(generation),
              self.configGeneration == generation else {
            return nil
        }

        return value
    }

    func topicCacheSnapshot(_ topic: RemoteConfigTopic) async
    -> GenerationGuardedCacheSnapshot<RemoteConfiguration.ConfigTopic>? {
        guard let configTopic = await self.topic(topic) else { return nil }
        return .init(generation: self.configGeneration, key: configTopic)
    }

    func isCurrent(
        _ snapshot: GenerationGuardedCacheSnapshot<RemoteConfiguration.ConfigTopic>,
        for topic: RemoteConfigTopic
    ) async -> Bool {
        guard self.configGeneration == snapshot.generation,
              await self.topic(topic) == snapshot.key else {
            return false
        }

        return true
    }

    func awaitTopicAndPrefetchBlobsReady(_ topic: RemoteConfigTopic) async -> RemoteConfiguration.ConfigTopic? {
        guard var committed = await self.topic(topic) else { return nil }

        while true {
            let prefetchRefs = committed.values.compactMap { $0.prefetch ? $0.blobRef : nil }
            await self.ensureBlobsDownloaded(prefetchRefs)

            // The topic could have been invalidated and refetched (e.g. an identity change) while
            // waiting on its blobs. Re-reading and comparing catches that without needing this
            // generic extension to see RemoteConfigManager's private epoch tracking.
            guard let latest = await self.topic(topic) else { return nil }
            guard latest != committed else { return committed }
            committed = latest
        }
    }

    func mergeItemsBlobData<T: Decodable>(
        for topic: RemoteConfigTopic,
        itemKeys: [String],
        as type: T.Type
    ) async throws -> T? {
        let uniqueItemKeys = itemKeys.deduplicated()
        guard !self.isDisabled else {
            Logger.warn(Strings.remoteConfig.mergeItemsBlobDataDisabled(topic: topic, itemKeys: uniqueItemKeys))
            return nil
        }
        guard !uniqueItemKeys.isEmpty else {
            Logger.warn(Strings.remoteConfig.mergeItemsBlobDataEmpty(topic: topic))
            return nil
        }

        let resolvedBlobs = await withTaskGroup(of: (String, Data?).self) { group in
            for itemKey in uniqueItemKeys {
                group.addTask {
                    return (itemKey, await self.blobData(for: topic, itemKey: itemKey))
                }
            }

            var resolvedBlobs: [String: Data?] = [:]
            for await (itemKey, data) in group {
                resolvedBlobs.updateValue(data, forKey: itemKey)
            }
            return resolvedBlobs
        }

        let unavailableItemKeys = uniqueItemKeys.filter { itemKey in
            guard let resolvedBlob = resolvedBlobs[itemKey] else { return true }
            return resolvedBlob == nil
        }
        guard unavailableItemKeys.isEmpty else {
            Logger.warn(Strings.remoteConfig.mergeItemsBlobDataUnavailableItems(
                topic: topic,
                itemKeys: unavailableItemKeys
            ))
            return nil
        }

        guard let mergedData = try Self.makeJSONEnvelopeData(
            orderedItemKeys: uniqueItemKeys,
            resolvedBlobs: resolvedBlobs
        ) else {
            return nil
        }

        return try JSONDecoder.default.decode(type, from: mergedData)
    }

    /// Builds a keyed JSON object `{"<itemKey>":<blobBytes>,...}` from already-encoded blob payloads.
    ///
    /// Each blob is a valid JSON value that is appended verbatim, avoiding a decode -> encode -> decode
    /// cycle. Item keys keep the order of `orderedItemKeys` and are escaped via `JSONEncoder.default`.
    /// Returns `nil` if any key has no resolved blob data.
    private static func makeJSONEnvelopeData(
        orderedItemKeys: [String],
        resolvedBlobs: [String: Data?]
    ) throws -> Data? {
        var envelope = Data("{".utf8)
        for (index, itemKey) in orderedItemKeys.enumerated() {
            guard let resolvedBlob = resolvedBlobs[itemKey],
                  let data = resolvedBlob else { return nil }
            if index > 0 {
                envelope.append(contentsOf: ",".utf8)
            }
            envelope.append(try JSONEncoder.default.encode(itemKey))
            envelope.append(contentsOf: ":".utf8)
            envelope.append(data)
        }
        envelope.append(contentsOf: "}".utf8)
        return envelope
    }

}

final class NoOpRemoteConfigManager: RemoteConfigManagerType {

    let isDisabled = true
    let configGeneration = 0
    var onRemoteConfigDisabled: (() -> Void)?

    func refreshRemoteConfig(fetchContext: RemoteConfigFetchContext, isAppBackgrounded: Bool) {}

    func refreshRemoteConfigIfStale(fetchContext: RemoteConfigFetchContext, isAppBackgrounded: Bool) {}

    func topic(_ topic: RemoteConfigTopic) async -> RemoteConfiguration.ConfigTopic? {
        return nil
    }

    func blobData(for topic: RemoteConfigTopic, itemKey: String) async -> Data? {
        return nil
    }

    func blobDataSnapshot(for topic: RemoteConfigTopic, itemKey: String) async -> RemoteConfigBlobData<Data>? {
        return nil
    }

    func useIfCurrent<T>(_ snapshot: RemoteConfigBlobData<T>, operation: (T) -> Void) -> Bool {
        return false
    }

    func blobData<T: Decodable>(
        for topic: RemoteConfigTopic,
        itemKey: String,
        as type: T.Type
    ) async throws -> T? {
        return nil
    }

    func ensureBlobsDownloaded(_ refs: [String]) async -> Bool {
        return false
    }

    func clearCache() {}

    func clearCache(forAppUserID appUserID: String) {}

    func close() {}

}

/// Coordinates a single remote config refresh.
///
/// This manager currently owns only manifest replay, inline blob extraction, and config-state persistence.
// swiftlint:disable:next todo
/// TODO: Remove this interim scope once topic handler dispatch and SDK lifecycle wiring land.
final class RemoteConfigManager: RemoteConfigManagerType {

    private static let defaultDomain = "app"
    private static let refreshAttemptCooldownInSeconds: TimeInterval = 60

    private let remoteConfigAPI: RemoteConfigAPIType
    private let diskCache: RemoteConfigDiskCacheType
    private let blobStore: RemoteConfigBlobStoreType
    private let blobFetcher: RemoteConfigBlobFetcherType
    private let currentUserProvider: CurrentUserProvider
    private let dateProvider: DateProvider
    private let cacheDurationInSeconds: (Bool) -> TimeInterval

    /// Immutable per-request snapshot chosen under `lock`.
    fileprivate struct RefreshRequestContext {
        let epoch: Int
        let requestAppUserID: String
        let fetchContext: RemoteConfigFetchContext
    }

    /// Runs blocking committed-state reads away from the caller's executor.
    private let readQueue = DispatchQueue(label: "com.revenuecat.remote-config.read")

    /// Serializes refresh ownership, epoch checks, and cache mutations against `clearCache()` and `close()`.
    private let lock = Lock()

    /// Tracks the single config refresh whose completion read APIs may await.
    private var isRefreshing = false

    /// Forces refreshes to report `.appStart` until the session's first config is committed, regardless of the
    /// caller's context, so the backend always sees `app_start` on a fresh app open. Set under `lock` only once config
    /// is durably committed (persisted from a 200 or the fallback) or confirmed current (204); a failed refresh or an
    /// undecodable/unpersistable 200 keeps forcing `.appStart` until a later attempt actually commits config.
    private var hasCommittedInitialConfig = false

    /// Session-scoped kill switch set by disabling client errors. This is intentionally not reset by cache clears.
    private var isDisabledInternal = false

    /// Teardown guard that prevents new refresh work after `close()`.
    private var isClosed = false

    /// Incremented when local state is invalidated so late responses from older users/sessions are dropped.
    private var epoch = 0

    /// Incremented whenever committed config changes or becomes invalid. Async cache warmers use this
    /// as a stale-write guard so older work cannot repopulate memory after a newer config is active.
    private var generation = 0

    var onRemoteConfigDisabled: (() -> Void)?

    /// App user ID captured by an identity-bound cache clear.
    ///
    /// During login/switch/logout, `clearCache` can bump the epoch before every caller observes the new user from
    /// `CurrentUserProvider`. Storing the cleared identity under the same lock makes refresh preparation prefer this
    /// ID over the provider value, so a request is either created for the cleared identity or treated as stale later.
    private var identityBoundAppUserID: String?

    /// In-memory staleness marker. Only successful `200` and `204` responses mark the config fresh.
    private var lastRefreshedAt: Date?

    /// In-memory attempt marker used to avoid hammering the endpoint when a stale refresh keeps failing.
    private var lastRefreshAttemptAt: Date?

    /// Read callers waiting for the current refresh to finish before rereading committed config state.
    ///
    /// These continuations carry no result because callers decide what to do by rereading disk state after the
    /// refresh, clear, close, or failure completes.
    private var refreshContinuations: [CheckedContinuation<Void, Never>] = []

    init(
        remoteConfigAPI: RemoteConfigAPIType,
        diskCache: RemoteConfigDiskCacheType,
        blobStore: RemoteConfigBlobStoreType,
        blobFetcher: RemoteConfigBlobFetcherType,
        currentUserProvider: CurrentUserProvider,
        dateProvider: DateProvider = DateProvider(),
        cacheDurationInSeconds: @escaping (Bool) -> TimeInterval = { _ in 60 * 5.0 }
    ) {
        self.remoteConfigAPI = remoteConfigAPI
        self.diskCache = diskCache
        self.blobStore = blobStore
        self.blobFetcher = blobFetcher
        self.currentUserProvider = currentUserProvider
        self.dateProvider = dateProvider
        self.cacheDurationInSeconds = cacheDurationInSeconds
    }

    var isDisabled: Bool {
        return self.lock.perform {
            self.isDisabledInternal
        }
    }

    var configGeneration: Int {
        return self.lock.perform {
            self.generation
        }
    }

    private var canReadCommittedState: Bool {
        return self.lock.perform {
            !self.isDisabledInternal && !self.isClosed
        }
    }

    func refreshRemoteConfig(fetchContext: RemoteConfigFetchContext, isAppBackgrounded: Bool) {
        let appUserID = self.currentUserProvider.currentAppUserID
        guard let requestContext = self.prepareRefreshIfNeeded(
            fetchContext: fetchContext,
            appUserID: appUserID
        ) else { return }

        self.startRefresh(isAppBackgrounded: isAppBackgrounded, requestContext: requestContext)
    }

    func refreshRemoteConfigIfStale(fetchContext: RemoteConfigFetchContext, isAppBackgrounded: Bool) {
        let appUserID = self.currentUserProvider.currentAppUserID
        guard let requestContext = self.prepareRefreshIfStale(
            fetchContext: fetchContext,
            isAppBackgrounded: isAppBackgrounded,
            appUserID: appUserID
        ) else { return }

        self.startRefresh(isAppBackgrounded: isAppBackgrounded, requestContext: requestContext)
    }

    func topic(_ topic: RemoteConfigTopic) async -> RemoteConfiguration.ConfigTopic? {
        return await self.readCommittedState(refreshIfMissing: true) {
            await self.committedTopic(topic)
        }
    }

    func blobData(for topic: RemoteConfigTopic, itemKey: String) async -> Data? {
        guard let itemSnapshot = await self.readCommittedStateSnapshot(refreshIfMissing: true, {
            await self.committedTopic(topic)?[itemKey]
        }),
              let item = itemSnapshot.value else {
            return nil
        }

        return await self.readCommittedState(epoch: itemSnapshot.epoch) {
            await self.blobData(for: item)
        }
    }

    func blobDataSnapshot(for topic: RemoteConfigTopic, itemKey: String) async -> RemoteConfigBlobData<Data>? {
        guard let itemSnapshot = await self.readCommittedStateSnapshot(refreshIfMissing: true, {
            await self.committedTopic(topic)?[itemKey]
        }),
              let item = itemSnapshot.value,
              let blobRef = item.blobRef else {
            return nil
        }

        let generation = self.lock.perform {
            guard !self.isDisabledInternal,
                  !self.isClosed,
                  self.epoch == itemSnapshot.epoch,
                  self.diskCache.topic(topic)?[itemKey]?.blobRef == blobRef else {
                return nil as Int?
            }

            return self.generation
        }
        guard let generation else { return nil }

        guard let data = await self.readCommittedState(epoch: itemSnapshot.epoch, {
            await self.blobData(for: item)
        }) else { return nil }

        return self.lock.perform {
            guard !self.isDisabledInternal,
                  !self.isClosed,
                  self.generation == generation else {
                return nil
            }

            return RemoteConfigBlobData(value: data, generation: generation)
        }
    }

    func useIfCurrent<T>(_ snapshot: RemoteConfigBlobData<T>, operation: (T) -> Void) -> Bool {
        return self.lock.perform {
            guard !self.isDisabledInternal,
                  !self.isClosed,
                  self.generation == snapshot.generation else {
                return false
            }

            operation(snapshot.value)
            return true
        }
    }

    func blobData<T: Decodable>(
        for topic: RemoteConfigTopic,
        itemKey: String,
        as type: T.Type
    ) async throws -> T? {
        guard let data = await self.blobData(for: topic, itemKey: itemKey) else { return nil }

        return try JSONDecoder.default.decode(type, from: data)
    }

    func ensureBlobsDownloaded(_ refs: [String]) async -> Bool {
        return await self.blobFetcher.ensureAllDownloaded(refs: refs)
    }

    /// Wipes cached remote config state, for example after an identity change.
    ///
    /// The epoch bump, refresh-guard release, and cache wipe are serialized with response persistence so a late
    /// response for a previous user is either fully persisted before the wipe or dropped after the epoch changes.
    func clearCache() {
        self.clearCache(forAppUserID: self.currentUserProvider.currentAppUserID)
    }

    func clearCache(forAppUserID appUserID: String) {
        let continuations = self.lock.perform {
            self.epoch += 1
            self.generation += 1
            self.identityBoundAppUserID = appUserID
            self.isRefreshing = false
            self.lastRefreshedAt = nil
            self.lastRefreshAttemptAt = nil
            self.diskCache.clear()
            self.blobStore.clear()
            return self.drainRefreshContinuations()
        }
        continuations.forEach { $0.resume() }
    }

    func close() {
        let continuations = self.lock.perform {
            self.epoch += 1
            self.generation += 1
            self.isClosed = true
            self.isRefreshing = false
            return self.drainRefreshContinuations()
        }
        continuations.forEach { $0.resume() }
    }

}

private extension RemoteConfigManager {

    /// Overrides a refresh's context to `.appStart` until the session's first config is committed, so the backend
    /// always sees `app_start` first on a fresh app open. Must be called within `lock`.
    func fetchContextForRefresh(_ requested: RemoteConfigFetchContext) -> RemoteConfigFetchContext {
        return self.hasCommittedInitialConfig ? requested : .appStart
    }

    func prepareRefreshIfNeeded(
        fetchContext: RemoteConfigFetchContext,
        appUserID: String
    ) -> RefreshRequestContext? {
        return self.lock.perform {
            guard !self.isRefreshing,
                  !self.isDisabledInternal,
                  !self.isClosed else { return nil }

            let requestAppUserID = self.identityBoundAppUserID ?? appUserID
            self.isRefreshing = true
            return .init(
                epoch: self.epoch,
                requestAppUserID: requestAppUserID,
                fetchContext: self.fetchContextForRefresh(fetchContext)
            )
        }
    }

    func prepareRefreshIfStale(
        fetchContext: RemoteConfigFetchContext,
        isAppBackgrounded: Bool,
        appUserID: String,
        expectedEpoch: Int? = nil
    ) -> RefreshRequestContext? {
        return self.lock.perform {
            guard !self.isRefreshing,
                  !self.isDisabledInternal,
                  !self.isClosed else { return nil }
            let now = self.dateProvider.now()
            if let expectedEpoch {
                guard self.epoch == expectedEpoch || self.identityBoundAppUserID != nil else { return nil }
            }
            if let lastRefreshedAt = self.lastRefreshedAt {
                guard now.timeIntervalSince(lastRefreshedAt)
                    > self.cacheDurationInSeconds(isAppBackgrounded) else { return nil }
            }
            if let lastRefreshAttemptAt = self.lastRefreshAttemptAt {
                guard now.timeIntervalSince(lastRefreshAttemptAt)
                    > Self.refreshAttemptCooldownInSeconds else { return nil }
            }

            let requestAppUserID = self.identityBoundAppUserID ?? appUserID
            self.isRefreshing = true
            self.lastRefreshAttemptAt = now
            return .init(
                epoch: self.epoch,
                requestAppUserID: requestAppUserID,
                fetchContext: self.fetchContextForRefresh(fetchContext)
            )
        }
    }

    func startRefresh(isAppBackgrounded: Bool, requestContext: RefreshRequestContext) {
        let persisted = self.diskCache.read()
        let request = RemoteConfigRequest(
            fetchContext: requestContext.fetchContext,
            appUserID: requestContext.requestAppUserID,
            domain: persisted?.domain ?? Self.defaultDomain,
            manifest: persisted?.manifest,
            prefetchedBlobs: self.cachedPrefetchedBlobRefs(from: persisted)
        )

        Logger.verbose(Strings.remoteConfig.refreshing(
            domain: request.domain, manifestPresent: request.manifest != nil, isAppBackgrounded: isAppBackgrounded
        ))

        self.enqueueRefreshIfCurrent(
            request: request,
            persisted: persisted,
            isAppBackgrounded: isAppBackgrounded,
            requestEpoch: requestContext.epoch
        )
    }

    func enqueueRefreshIfCurrent(
        request: RemoteConfigRequest,
        persisted: PersistedRemoteConfiguration?,
        isAppBackgrounded: Bool,
        requestEpoch: Int
    ) {
        // Keep the epoch check and operation enqueue atomic with clearCache(), so a clear cannot slip in between them.
        // This assumes getRemoteConfig only registers/enqueues work and does not synchronously call its completion.
        self.lock.perform {
            guard self.epoch == requestEpoch else { return }

            self.remoteConfigAPI.getRemoteConfig(
                request: request,
                isAppBackgrounded: isAppBackgrounded
            ) { [weak self] result in
                guard let self else { return }

                switch result {
                case let .success(fetchResult):
                    self.handleSuccess(
                        fetchResult,
                        previous: persisted,
                        requestEpoch: requestEpoch
                    )
                case let .failure(error):
                    self.handleFailure(
                        error,
                        request: request,
                        previous: persisted,
                        isAppBackgrounded: isAppBackgrounded,
                        requestEpoch: requestEpoch
                    )
                }
            }
        }
    }

    @discardableResult
    func releaseGuardIfOwned(requestEpoch: Int) -> Bool {
        let continuations = self.lock.perform {
            guard self.epoch == requestEpoch else { return nil as [CheckedContinuation<Void, Never>]? }
            self.isRefreshing = false
            return self.drainRefreshContinuations()
        }
        guard let continuations else { return false }

        continuations.forEach { $0.resume() }
        return true
    }

    func handleSuccess(
        _ fetchResult: RemoteConfigFetchResult,
        previous: PersistedRemoteConfiguration?,
        requestEpoch: Int
    ) {
        guard self.isCurrent(requestEpoch) else { return }
        defer { self.releaseGuardIfOwned(requestEpoch: requestEpoch) }

        guard let container = fetchResult.container else {
            Logger.debug(Strings.remoteConfig.notModified)
            self.markRefreshedIfCurrent(requestEpoch)
            return
        }

        do {
            let response = try container.configElement.withDecodedPayloadBytes { bytes in
                try JSONDecoder.default.decode(
                    RemoteConfiguration.self,
                    from: Data(bytes)
                )
            }

            self.lock.perform {
                guard self.epoch == requestEpoch else { return }
                let didPersist = self.persist(
                    container: container,
                    previous: previous,
                    response: response
                )
                if didPersist {
                    self.generation += 1
                    self.markRefreshed()
                }
            }
        } catch {
            Logger.error(Strings.remoteConfig.failedToParseResponse(error))
        }

    }

    func handleFailure(
        _ error: BackendError,
        request: RemoteConfigRequest,
        previous: PersistedRemoteConfiguration?,
        isAppBackgrounded: Bool,
        requestEpoch: Int
    ) {
        guard error.isRemoteConfigFallbackEligible,
              !self.hasUsableCachedConfig(previous, for: request.domain) else {
            self.handleFinalFailure(error, requestEpoch: requestEpoch, shouldDisableRefresh: true)
            return
        }

        guard SystemInfo.proxyURL == nil else {
            self.handleFinalFailure(error, requestEpoch: requestEpoch, shouldDisableRefresh: false)
            return
        }

        self.enqueueRemoteConfigFallbackIfCurrent(
            domain: request.domain,
            previous: previous,
            isAppBackgrounded: isAppBackgrounded,
            requestEpoch: requestEpoch,
            originalError: error
        )
    }

    func hasUsableCachedConfig(
        _ previous: PersistedRemoteConfiguration?,
        for domain: String
    ) -> Bool {
        return previous?.domain == domain
    }

    func enqueueRemoteConfigFallbackIfCurrent(
        domain: String,
        previous: PersistedRemoteConfiguration?,
        isAppBackgrounded: Bool,
        requestEpoch: Int,
        originalError: BackendError
    ) {
        self.lock.perform {
            guard self.epoch == requestEpoch else { return }

            self.remoteConfigAPI.getRemoteConfigFallback(
                domain: domain,
                isAppBackgrounded: isAppBackgrounded
            ) { [weak self] result in
                guard let self else { return }

                switch result {
                case let .success(fallbackResult):
                    self.handleRemoteConfigFallbackSuccess(
                        fallbackResult,
                        previous: previous,
                        requestEpoch: requestEpoch
                    )
                case let .failure(fallbackError):
                    self.handleFinalFailure(fallbackError, requestEpoch: requestEpoch, shouldDisableRefresh: true)
                }
            }
        }
    }

    func handleRemoteConfigFallbackSuccess(
        _ fallbackResult: RemoteConfigFallbackFetchResult,
        previous: PersistedRemoteConfiguration?,
        requestEpoch: Int
    ) {
        guard self.isCurrent(requestEpoch) else { return }
        defer { self.releaseGuardIfOwned(requestEpoch: requestEpoch) }

        self.lock.perform {
            guard self.epoch == requestEpoch else { return }
            let didPersist = self.persist(
                container: nil,
                previous: previous,
                response: fallbackResult.configuration
            )
            if didPersist {
                self.generation += 1
                self.markRefreshed()
            }
        }
    }

    func handleFinalFailure(
        _ error: BackendError,
        requestEpoch: Int,
        shouldDisableRefresh: Bool
    ) {
        let result = self.lock.perform {
            guard self.epoch == requestEpoch else {
                return nil as (continuations: [CheckedContinuation<Void, Never>], didDisable: Bool)?
            }

            let didDisable: Bool
            if shouldDisableRefresh {
                didDisable = self.disableRefreshIfNeeded(for: error)
            } else {
                didDisable = false
            }
            self.isRefreshing = false

            return (self.drainRefreshContinuations(), didDisable)
        }

        guard let result else { return }
        result.continuations.forEach { $0.resume() }

        if result.didDisable {
            self.onRemoteConfigDisabled?()
        }

        Logger.error(Strings.remoteConfig.refreshFailed(error))
    }

    func disableRefreshIfNeeded(for error: BackendError) -> Bool {
        guard error.isRemoteConfigDisablingClientError,
              !self.isDisabledInternal else { return false }

        self.isDisabledInternal = true
        self.generation += 1
        return true
    }

    func isCurrent(_ requestEpoch: Int) -> Bool {
        return self.lock.perform {
            self.epoch == requestEpoch
        }
    }

    func markRefreshedIfCurrent(_ requestEpoch: Int) {
        self.lock.perform {
            guard self.epoch == requestEpoch else { return }

            self.markRefreshed()
        }
    }

    /// Records a landed refresh: stamps the refresh time and marks the session's initial config as committed, so
    /// later refreshes stop being forced to `.appStart`. Must be called within `lock`.
    func markRefreshed() {
        self.hasCommittedInitialConfig = true
        self.lastRefreshedAt = self.dateProvider.now()
    }

    /// Waits for committed config state to become available for read APIs.
    ///
    /// A read first joins existing refresh work. If no refresh is in flight and remote config is still readable,
    /// it starts one foreground refresh only when stale and waits for that attempt before the caller rereads
    /// disk state. When an epoch is supplied, the wait/refresh is skipped if cache state changed since the
    /// caller's initial committed read.
    func awaitConfigForRead(expectedEpoch: Int? = nil) async {
        if let expectedEpoch, !self.isReadable(epoch: expectedEpoch) {
            return
        }

        if await self.awaitInFlightRefresh() {
            return
        }

        if let expectedEpoch {
            guard self.isReadable(epoch: expectedEpoch) else { return }
        } else {
            guard self.canReadCommittedState else { return }
        }

        let appUserID = self.currentUserProvider.currentAppUserID
        if let requestContext = self.prepareRefreshIfStale(
            fetchContext: .read,
            isAppBackgrounded: false,
            appUserID: appUserID,
            expectedEpoch: expectedEpoch
        ) {
            self.startRefresh(isAppBackgrounded: false, requestContext: requestContext)
        }
        _ = await self.awaitInFlightRefresh()
    }

    /// Joins the current refresh if one is active.
    ///
    /// Returns `true` only when the caller actually waited on refresh completion. Returning `false` lets callers
    /// decide whether to start a new refresh attempt.
    func awaitInFlightRefresh() async -> Bool {
        var didRegisterWaiter = false
        await withCheckedContinuation { continuation in
            didRegisterWaiter = self.lock.perform {
                guard self.isRefreshing else { return false }

                self.refreshContinuations.append(continuation)
                return true
            }

            if !didRegisterWaiter {
                continuation.resume()
            }
        }

        return didRegisterWaiter
    }

    /// Removes and returns all read waiters so they can be resumed outside the lock.
    func drainRefreshContinuations() -> [CheckedContinuation<Void, Never>] {
        defer { self.refreshContinuations = [] }

        return self.refreshContinuations
    }

    /// Reads committed state only if the manager remains on the same epoch for the whole operation.
    ///
    /// If the value is missing, callers may opt into the read-facade behavior of awaiting or triggering one
    /// foreground refresh before reading again. If `clearCache()`, `close()`, or disable happens during either
    /// read, the result is discarded.
    func readCommittedState<T>(
        refreshIfMissing: Bool = false,
        _ operation: () async -> T?
    ) async -> T? {
        return await self.readCommittedStateSnapshot(refreshIfMissing: refreshIfMissing, operation)?.value
    }

    func readCommittedState<T>(
        epoch: Int,
        _ operation: () async -> T?
    ) async -> T? {
        return await self.readCommittedStateSnapshot(epoch: epoch, operation)?.value
    }

    func readCommittedStateSnapshot<T>(
        refreshIfMissing: Bool = false,
        _ operation: () async -> T?
    ) async -> (value: T?, epoch: Int)? {
        guard let result = await self.readCurrentCommittedState(operation) else { return nil }
        if result.value != nil || !refreshIfMissing {
            return result
        }

        await self.awaitConfigForRead(expectedEpoch: result.epoch)
        guard self.isReadable(epoch: result.epoch) else { return nil }

        return await self.readCommittedStateSnapshot(epoch: result.epoch, operation)
    }

    func readCurrentCommittedState<T>(_ operation: () async -> T?) async -> (value: T?, epoch: Int)? {
        guard let epoch = self.currentReadableEpoch() else { return nil }

        return await self.readCommittedStateSnapshot(epoch: epoch, operation)
    }

    func readCommittedStateSnapshot<T>(
        epoch: Int,
        _ operation: () async -> T?
    ) async -> (value: T?, epoch: Int)? {
        guard self.isReadable(epoch: epoch) else { return nil }

        let value = await operation()

        return self.isReadable(epoch: epoch) ? (value, epoch) : nil
    }

    func currentReadableEpoch() -> Int? {
        return self.lock.perform {
            guard !self.isDisabledInternal, !self.isClosed else { return nil }

            return self.epoch
        }
    }

    func isReadable(epoch: Int) -> Bool {
        return self.lock.perform {
            !self.isDisabledInternal && !self.isClosed && self.epoch == epoch
        }
    }

    /// Reads committed topic metadata off the caller's executor.
    func committedTopic(_ topic: RemoteConfigTopic) async -> RemoteConfiguration.ConfigTopic? {
        return await self.performRead {
            self.diskCache.topic(topic)
        }
    }

    /// Resolves an external blob item through the high-priority fetch path.
    ///
    /// Inline item metadata is returned by `topic(_:)`; this method only returns bytes for items backed by
    /// `blob_ref`.
    func blobData(for item: RemoteConfiguration.ConfigItem) async -> Data? {
        guard let ref = item.blobRef else { return nil }

        guard await self.blobFetcher.ensureDownloaded(ref: ref) else { return nil }

        return await self.readBlob(ref: ref)
    }

    /// Reads committed blob bytes off the caller's executor.
    func readBlob(ref: String) async -> Data? {
        return await self.performRead {
            self.blobStore.read(ref: ref)
        }
    }

    /// Performs small blocking cache reads on the manager's read queue.
    func performRead<T>(_ operation: @escaping () -> T) async -> T {
        let operation = SendableReadOperation(run: operation)
        return await withCheckedContinuation { continuation in
            self.readQueue.async {
                continuation.resume(returning: operation.run())
            }
        }
    }

    /// Replays only requested prefetch blobs that are still present in the blob store.
    func cachedPrefetchedBlobRefs(from persisted: PersistedRemoteConfiguration?) -> [String] {
        guard let persisted else { return [] }

        let cachedRefs = self.blobStore.cachedRefs()
        return persisted.prefetchBlobs.filter { cachedRefs.contains($0) }
    }

    /// Persists the config sync state and any valid inline blobs from a successful container response.
    func persist(
        container: RemoteConfigContainer?,
        previous: PersistedRemoteConfiguration?,
        response: RemoteConfiguration
    ) -> Bool {
        Logger.debug(Strings.remoteConfig.receivedConfiguration(
            activeTopics: response.activeTopics, changedTopics: Array(response.topics.entries.keys)
        ))

        let postSyncTopics = self.postSyncTopics(
            previous: previous,
            response: response
        )
        let postSyncReferencedBlobRefs = self.postSyncReferencedBlobRefs(
            response: response,
            postSyncTopics: postSyncTopics
        )

        let persistedConfiguration = PersistedRemoteConfiguration(
            domain: response.domain,
            manifest: response.manifest,
            activeTopics: response.activeTopics,
            prefetchBlobs: response.prefetchBlobs,
            topics: postSyncTopics
        )

        guard self.diskCache.write(persistedConfiguration) else { return false }

        if let container {
            self.extractInlineBlobs(from: container, keepingOnly: postSyncReferencedBlobRefs)
        }
        self.blobStore.retainOnly(postSyncReferencedBlobRefs)

        Logger.debug(Strings.remoteConfig.persistedConfiguration(
            domain: response.domain,
            activeTopicCount: response.activeTopics.count,
            referencedBlobCount: postSyncReferencedBlobRefs.count
        ))

        let refsToPrefetch = self.postSyncPrefetchBlobRefs(
            response: response,
            postSyncTopics: postSyncTopics
        ).filter { !self.blobStore.contains(ref: $0) }
        Logger.verbose(Strings.remoteConfig.prefetchingBlobCount(refsToPrefetch.count))
        self.blobFetcher.prefetch(refs: refsToPrefetch)

        return true
    }

    /// Returns the full topic index that should be persisted after this response is applied.
    ///
    /// Changed topics overwrite previous entries, unchanged active topics keep previous entries, and inactive topics
    /// are removed. Changed topics are full replacements, not item-level patches, so removed items fall out of
    /// the persisted topic index and blob retention set.
    func postSyncTopics(
        previous: PersistedRemoteConfiguration?,
        response: RemoteConfiguration
    ) -> RemoteConfiguration.Topics {
        let entries = (previous?.topics.entries ?? [:])
            .merging(response.topics.entries) { _, changed in changed }
            .filter { topic, _ in response.activeTopics.contains(topic) }

        return RemoteConfiguration.Topics(entries: entries)
    }

    /// Returns the post-sync set of blob refs the SDK should keep locally.
    ///
    /// This includes requested prefetch blobs plus blob refs used by active topics after merging changed
    /// response topics with previously persisted unchanged topics.
    func postSyncReferencedBlobRefs(
        response: RemoteConfiguration,
        postSyncTopics: RemoteConfiguration.Topics
    ) -> Set<String> {
        return Set(response.prefetchBlobs).union(postSyncTopics.blobRefs)
    }

    /// Returns the post-sync blob refs the SDK should proactively warm.
    ///
    /// This includes server-requested prefetch blobs plus any active-topic item whose metadata has
    /// `prefetch: true`.
    func postSyncPrefetchBlobRefs(
        response: RemoteConfiguration,
        postSyncTopics: RemoteConfiguration.Topics
    ) -> [String] {
        let itemPrefetchBlobRefs = postSyncTopics.entries.values.flatMap { topic in
            topic.values
                .filter(\.prefetch)
                .compactMap(\.blobRef)
        }

        return (response.prefetchBlobs + itemPrefetchBlobRefs).deduplicated()
    }

    /// Writes valid inline content elements that are referenced by this config response.
    ///
    /// Invalid or unreferenced content elements are skipped because inline blobs are opportunistic cache entries.
    func extractInlineBlobs(
        from container: RemoteConfigContainer,
        keepingOnly referencedBlobRefs: Set<String>
    ) {
        for (ref, element) in container.inlineContentElements {
            guard referencedBlobRefs.contains(ref) else { continue }

            do {
                try element.withDecodedPayloadBytes { bytes in
                    guard RemoteConfigBlobRefHelpers.isValidPayload(bytes, expectedRef: ref) else {
                        throw RCContainer.Parser.FormatError.checksumMismatch(
                            expected: ref,
                            actual: RemoteConfigBlobRefHelpers.ref(for: bytes)
                        )
                    }

                    if self.blobStore.write(ref: ref, bytes: bytes) {
                        Logger.verbose(Strings.remoteConfig.storedInlineBlob(ref, byteCount: bytes.count))
                    }
                }
            } catch {
                Logger.error(Strings.remoteConfig.skippingInvalidBlob(ref))
            }
        }
    }

}

private struct SendableReadOperation<T>: @unchecked Sendable {

    let run: () -> T

}

private extension BackendError {

    /// Client errors disable remote config refreshes as a safety mechanism for the current manager lifetime.
    var isRemoteConfigDisablingClientError: Bool {
        guard case let .networkError(.errorResponse(_, statusCode, _)) = self else {
            return false
        }

        return 400...499 ~= statusCode.rawValue
    }

    /// Failures that can retry against a fallback host are eligible for the JSON fallback config request.
    var isRemoteConfigFallbackEligible: Bool {
        guard case let .networkError(networkError) = self else {
            return false
        }

        return networkError.isAllowedToRetryWithFallbackHost
    }

}
