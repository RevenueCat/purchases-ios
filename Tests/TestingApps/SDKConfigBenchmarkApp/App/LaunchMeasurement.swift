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
    /// Milliseconds until the `PaywallView` wrapper mounted (may still be a loading state).
    var paywallAppearedMs: Double?
    /// Milliseconds until the SDK tracked the paywall impression: the content view (resolved
    /// paywall or explicit fallback) actually appeared. This is the headline number.
    var paywallImpressionMs: Double?
    /// Whether the config endpoint path ran this launch (its refresh was observed in the log).
    /// Runtime proof of which SDK variant is actually inside the binary.
    var configPathActive: Bool = false
    /// Terminal state of the config refresh: `persisted`, `not_modified`, or `failed`.
    /// A config-variant launch whose refresh failed silently measures legacy fallback
    /// behavior, so the runner requires a success outcome, not just an active path.
    var configOutcome: String?
    /// Milliseconds until the config endpoint response was persisted (config variant only;
    /// observed via the SDK's log stream, nil when the config path never ran).
    var configPersistedMs: Double?
    /// Milliseconds until the last blob landed in the store (nil when no blobs were stored).
    var lastBlobStoredMs: Double?
    /// Blobs written to the store this launch, split by how they arrived.
    var blobsInline: Int = 0
    var blobsDownloaded: Int = 0
    /// Total bytes of blobs stored this launch.
    var blobBytes: Int = 0
    /// Size extremes, for empirically checking the backend's inline-size budget (blobs under
    /// the budget should arrive inline; a small blob arriving via CDN is a regression signal).
    var maxInlineBlobBytes: Int?
    var minDownloadedBlobBytes: Int?
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
        return try? JSONDecoder().decode(LaunchSample.self, from: Data(json.utf8))
    }

}

/// SDK values the app copies because the SDK does not export them. Each one is pinned to
/// the real SDK by a unit test in the benchmark suite, so drift over there fails a test
/// instead of silently corrupting rows (a stale suite name would stop `--wipe-state` from
/// wiping and make "cold" rows measure warm behavior; stale event types would time out
/// every launch).
enum SDKObservedValues {

    /// Event types meaning "paywall content actually appeared": a classic paywall tracks
    /// `paywall_impression`; a workflow paywall tracks `workflows_step_started`.
    static let contentAppearedEventTypes: Set<String> = [
        "paywall_impression",
        "workflows_step_started"
    ]

    /// The UserDefaults suite the SDK persists into (`UserDefaults.revenueCatSuiteName`,
    /// which is private).
    static let revenueCatUserDefaultsSuiteName = "com.revenuecat.user_defaults"

}

/// One blob landing in the SDK's content-addressed store, observed from the SDK's log stream.
struct BlobStorageEvent: Equatable {

    enum Source: String {
        /// Delivered inside the config container response.
        case inline
        /// Fetched separately from a blob source (CDN).
        case downloaded
    }

    let source: Source
    let byteCount: Int

}

/// Extracts config-path progress from the SDK's log messages (the only observable the stock
/// SDK offers an app). Substring-based so logger prefixes (level, emoji) don't matter; the
/// exact phrases are pinned to `RemoteConfigStrings` by unit tests in the benchmark suite.
enum BlobLogParser {

    private static let inlineMarker = "Stored inline remote config blob '"
    private static let downloadedMarker = "Stored remote config blob '"
    private static let configPersistedMarker = "Persisted remote config for domain '"
    private static let configRefreshingMarker = "Refreshing remote config for domain '"
    private static let configNotModifiedMarker = "Remote config was not modified"
    private static let configRefreshFailedMarker = "Remote config refresh failed"

    static func blobEvent(from message: String) -> BlobStorageEvent? {
        let source: BlobStorageEvent.Source
        if message.contains(Self.inlineMarker) {
            source = .inline
        } else if message.contains(Self.downloadedMarker) {
            source = .downloaded
        } else {
            return nil
        }

        guard let byteCount = Self.integer(before: " bytes", in: message) else { return nil }
        return BlobStorageEvent(source: source, byteCount: byteCount)
    }

    static func isConfigPersisted(_ message: String) -> Bool {
        return message.contains(Self.configPersistedMarker)
    }

    /// Fires on every config-variant launch (cold 200 and warm 204 alike), so it doubles as
    /// runtime proof that `ENABLE_REMOTE_CONFIG` is compiled into the SDK being measured.
    static func isConfigRefreshStarted(_ message: String) -> Bool {
        return message.contains(Self.configRefreshingMarker)
    }

    /// The refresh revalidated via a manifest 204 (warm path's terminal success state).
    static func isConfigNotModified(_ message: String) -> Bool {
        return message.contains(Self.configNotModifiedMarker)
    }

    /// The refresh failed and the SDK fell back to cached/legacy behavior. A launch ending
    /// here must not pass as a config-path measurement.
    static func isConfigRefreshFailed(_ message: String) -> Bool {
        return message.contains(Self.configRefreshFailedMarker)
    }

    private static func integer(before suffix: String, in message: String) -> Int? {
        guard let suffixRange = message.range(of: suffix) else { return nil }
        let digits = message[..<suffixRange.lowerBound].reversed().prefix(while: \.isNumber)
        guard !digits.isEmpty else { return nil }
        return Int(String(digits.reversed()))
    }

}

/// Accumulates config-path progress from SDK log messages during one launch. Fed from the
/// log handler (arbitrary threads); snapshotted into the sample when the launch finishes,
/// so blob numbers mean "stored by the time the paywall appeared".
final class BlobObserver: @unchecked Sendable {

    private let lock = NSLock()
    private let clock: LaunchClock
    private var configPathActive = false
    private var configOutcome: String?
    private var configPersistedMs: Double?
    private var lastBlobStoredMs: Double?
    private var inlineCount = 0
    private var downloadedCount = 0
    private var totalBytes = 0
    private var maxInlineBytes: Int?
    private var minDownloadedBytes: Int?

    init(clock: LaunchClock) {
        self.clock = clock
    }

    func ingest(_ message: String) {
        let elapsed = self.clock.elapsedMs()
        let blobEvent = BlobLogParser.blobEvent(from: message)
        var isConfigPersisted = false
        var isConfigRefresh = false
        var terminalOutcome: String?
        if blobEvent == nil {
            isConfigPersisted = BlobLogParser.isConfigPersisted(message)
            isConfigRefresh = !isConfigPersisted && BlobLogParser.isConfigRefreshStarted(message)
            if isConfigPersisted {
                terminalOutcome = "persisted"
            } else if BlobLogParser.isConfigNotModified(message) {
                terminalOutcome = "not_modified"
            } else if BlobLogParser.isConfigRefreshFailed(message) {
                terminalOutcome = "failed"
            }
        }
        guard blobEvent != nil || isConfigPersisted || isConfigRefresh || terminalOutcome != nil else {
            return
        }

        self.lock.lock()
        defer { self.lock.unlock() }

        if isConfigRefresh || isConfigPersisted || terminalOutcome != nil {
            self.configPathActive = true
        }
        if let terminalOutcome, self.configOutcome == nil {
            self.configOutcome = terminalOutcome
        }
        if isConfigPersisted, self.configPersistedMs == nil {
            self.configPersistedMs = elapsed
        }
        guard let blobEvent else { return }

        self.lastBlobStoredMs = elapsed
        self.totalBytes += blobEvent.byteCount
        switch blobEvent.source {
        case .inline:
            self.inlineCount += 1
            self.maxInlineBytes = max(self.maxInlineBytes ?? .min, blobEvent.byteCount)
        case .downloaded:
            self.downloadedCount += 1
            self.minDownloadedBytes = min(self.minDownloadedBytes ?? .max, blobEvent.byteCount)
        }
    }

    func apply(to sample: inout LaunchSample) {
        self.lock.lock()
        defer { self.lock.unlock() }

        sample.configPathActive = self.configPathActive
        sample.configOutcome = self.configOutcome
        sample.configPersistedMs = self.configPersistedMs
        sample.lastBlobStoredMs = self.lastBlobStoredMs
        sample.blobsInline = self.inlineCount
        sample.blobsDownloaded = self.downloadedCount
        sample.blobBytes = self.totalBytes
        sample.maxInlineBlobBytes = self.maxInlineBytes
        sample.minDownloadedBlobBytes = self.minDownloadedBytes
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
