//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AppLaunchMetrics.swift
//
//  Created by Facundo Menzella on 9/7/26.

import Foundation

/// Aggregates per-launch `LaunchSample`s into one JSONL row compatible with the CLI
/// benchmark's `compare.py` (same key fields, same nearest-rank percentiles). Compiled into
/// both the XCUITest runner and the benchmark unit-test target.
enum AppLaunchMetrics {

    /// One row per (mode, scenario) configuration. `samples` has one entry per launch in
    /// order; `nil` means the launch produced no readable result. Launches with an `error`
    /// or a missing phase count as errors and never enter the statistics. The first
    /// `warmupDiscarded` entries are excluded from statistics by index.
    // swiftlint:disable:next function_body_length
    static func row(
        mode: String,
        scenario: String,
        profile: String,
        projectID: String,
        warmupDiscarded: Int,
        samples: [LaunchSample?]
    ) -> String {
        let indexed = samples.enumerated()
        let errors: [(index: Int, message: String)] = indexed.compactMap { index, sample in
            if let message = Self.errorMessage(for: sample) {
                return (index, message)
            }
            return nil
        }
        let measured: [LaunchSample] = indexed.compactMap { index, sample in
            guard index >= warmupDiscarded,
                  let sample,
                  Self.errorMessage(for: sample) == nil else {
                return nil
            }
            return sample
        }

        var row: [String: Any] = [
            "mode": mode,
            "transport": "live",
            "scenario": scenario,
            "profile": profile,
            "loss_percent": 0,
            "paywalls": 0,
            "workflows": 0,
            "seed": 0,
            "iterations": samples.count,
            "warmup_discarded": warmupDiscarded,
            "project_id": projectID,
            "measured_iterations": measured.count,
            "error_count": errors.count,
            "post_warmup_error_count": errors.filter { $0.index >= warmupDiscarded }.count
        ]

        // Headline statistic: `Purchases.configure` + `getOfferings` completed, with or
        // without workflows compiled in. This matches the CLI tier's total (offerings
        // delivered), so the two tiers answer the same question; the paywall marks stay in
        // the row as secondary phase means.
        let totals = measured.compactMap(\.offeringsMs).sorted()
        if !totals.isEmpty {
            row["mean_ms"] = Self.rounded(totals.reduce(0, +) / Double(totals.count))
            row["min_ms"] = Self.rounded(totals[0])
            row["max_ms"] = Self.rounded(totals[totals.count - 1])
            for percentile in [50, 90, 95, 99] {
                row["p\(percentile)_ms"] = Self.rounded(Self.percentile(percentile, of: totals))
            }
        }

        for (key, values) in [
            ("configured_ms_mean", measured.compactMap(\.configuredMs)),
            ("customer_info_ms_mean", measured.compactMap(\.customerInfoMs)),
            ("offerings_ms_mean", measured.compactMap(\.offeringsMs)),
            ("paywall_appeared_ms_mean", measured.compactMap(\.paywallAppearedMs)),
            ("paywall_impression_ms_mean", measured.compactMap(\.paywallImpressionMs)),
            ("config_persisted_ms_mean", measured.compactMap(\.configPersistedMs)),
            ("last_blob_stored_ms_mean", measured.compactMap(\.lastBlobStoredMs)),
            ("blobs_inline_mean", measured.map { Double($0.blobsInline) }),
            ("blobs_downloaded_mean", measured.map { Double($0.blobsDownloaded) }),
            ("blob_bytes_mean", measured.map { Double($0.blobBytes) })
        ] where !values.isEmpty {
            row[key] = Self.rounded(values.reduce(0, +) / Double(values.count))
        }

        // Size extremes across the run: together they bracket the backend's inline-size
        // budget (largest blob seen inline vs smallest blob that needed a CDN download).
        if let maxInline = measured.compactMap(\.maxInlineBlobBytes).max() {
            row["max_inline_blob_bytes"] = maxInline
        }
        if let minDownloaded = measured.compactMap(\.minDownloadedBlobBytes).min() {
            row["min_downloaded_blob_bytes"] = minDownloaded
        }

        if let firstError = errors.first {
            row["first_error"] = "iteration \(firstError.index): \(firstError.message)"
        }

        guard let data = try? JSONSerialization.data(withJSONObject: row, options: [.sortedKeys]),
              let json = String(data: data, encoding: .utf8) else {
            return "{\"error\":\"row-encoding-failed\"}"
        }
        return json
    }

    /// Non-nil when a launch cannot contribute to the statistics: it failed outright,
    /// produced nothing, or is missing a phase (a partially measured launch could otherwise
    /// look faster than a complete one).
    static func errorMessage(for sample: LaunchSample?) -> String? {
        guard let sample else { return "no benchmark-result element" }
        if let error = sample.error { return error }
        for (phase, value) in [
            ("configuredMs", sample.configuredMs),
            ("customerInfoMs", sample.customerInfoMs),
            ("offeringsMs", sample.offeringsMs),
            ("paywallAppearedMs", sample.paywallAppearedMs),
            ("paywallImpressionMs", sample.paywallImpressionMs)
        ] where value == nil {
            return "sample missing \(phase)"
        }
        return nil
    }

    /// Nearest-rank percentile over an already-sorted array; same formula as the CLI
    /// benchmark's `BenchmarkMetrics.percentile` so rows are comparable.
    static func percentile(_ percentile: Int, of sorted: [Double]) -> Double {
        precondition(!sorted.isEmpty)
        let rank = Int((Double(percentile) / 100 * Double(sorted.count)).rounded(.up))
        return sorted[max(0, min(sorted.count - 1, rank - 1))]
    }

    private static func rounded(_ value: Double) -> Double {
        return (value * 1_000).rounded() / 1_000
    }

}
