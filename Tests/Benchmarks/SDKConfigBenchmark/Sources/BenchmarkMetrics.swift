import Foundation

/// Blobs stored during one iteration, split by how they arrived: written from the config
/// container (inline) vs fetched from a blob source (downloaded). The size extremes bracket
/// the backend's inline-size budget empirically: the largest blob seen inline and the
/// smallest blob that needed a download.
struct BlobAccounting {

    let inlineCount: Int
    let downloadedCount: Int
    let totalBytes: Int
    let maxInlineBytes: Int?
    let minDownloadedBytes: Int?

    static let empty = BlobAccounting(
        inlineCount: 0,
        downloadedCount: 0,
        totalBytes: 0,
        maxInlineBytes: nil,
        minDownloadedBytes: nil
    )

    /// Attributes newly stored refs: a new ref that has a successful blob request this
    /// iteration was downloaded; any other new ref can only have come from the container.
    init(newRefSizes: [String: Int], downloadedRefs: Set<String>) {
        var inlineCount = 0
        var downloadedCount = 0
        var totalBytes = 0
        var maxInlineBytes: Int?
        var minDownloadedBytes: Int?

        for (ref, byteCount) in newRefSizes {
            totalBytes += byteCount
            if downloadedRefs.contains(ref) {
                downloadedCount += 1
                minDownloadedBytes = min(minDownloadedBytes ?? .max, byteCount)
            } else {
                inlineCount += 1
                maxInlineBytes = max(maxInlineBytes ?? .min, byteCount)
            }
        }

        self.inlineCount = inlineCount
        self.downloadedCount = downloadedCount
        self.totalBytes = totalBytes
        self.maxInlineBytes = maxInlineBytes
        self.minDownloadedBytes = minDownloadedBytes
    }

    private init(
        inlineCount: Int,
        downloadedCount: Int,
        totalBytes: Int,
        maxInlineBytes: Int?,
        minDownloadedBytes: Int?
    ) {
        self.inlineCount = inlineCount
        self.downloadedCount = downloadedCount
        self.totalBytes = totalBytes
        self.maxInlineBytes = maxInlineBytes
        self.minDownloadedBytes = minDownloadedBytes
    }

}

/// One measured simulated launch, with phases attributed from the transport event log.
struct IterationMeasurement {

    /// Start of the iteration to delivery of the offerings completion.
    let totalMs: Double
    /// Span of the offerings request(s), nil if none were made.
    let offeringsMs: Double?
    /// Span of the `/v1/config` request(s), nil for legacy mode.
    let configMs: Double?
    /// First blob request start to last blob request end, nil if no blobs were fetched.
    let blobMs: Double?
    let requestCount: Int
    let bytesReceived: Int
    let failedRequestCount: Int
    let fallbackHostRequestCount: Int
    /// Per-kind statuses and blob traffic, for strict warm-scenario verification.
    let offeringsStatusCodes: [Int]
    let configStatusCodes: [Int]
    let blobRequestCount: Int
    /// Blobs stored this iteration, attributed inline vs downloaded via the blob store.
    let blobs: BlobAccounting

    init(totalMs: Double, events: [TransportEvent], blobAccounting: BlobAccounting = .empty) {
        self.totalMs = totalMs
        let byKind = Dictionary(grouping: events, by: \.kind)
        let offerings = byKind[.offerings] ?? []
        let config = byKind[.config] ?? []
        let blobs = byKind[.blob] ?? []
        self.offeringsMs = Self.span(of: offerings)
        self.configMs = Self.span(of: config)
        self.blobMs = Self.span(of: blobs)
        self.requestCount = events.count
        self.bytesReceived = events.reduce(0) { $0 + $1.bytesReceived }
        self.failedRequestCount = events.filter(\.failed).count
        self.fallbackHostRequestCount = events.filter(\.isFallbackHostRequest).count
        self.offeringsStatusCodes = offerings.map(\.statusCode)
        self.configStatusCodes = config.map(\.statusCode)
        self.blobRequestCount = blobs.count
        self.blobs = blobAccounting
    }

    private static func span(of events: [TransportEvent]) -> Double? {
        guard let first = events.map(\.startedAt.uptimeNanoseconds).min(),
              let last = events.map(\.endedAt.uptimeNanoseconds).max() else {
            return nil
        }
        return Double(last - first) / 1_000_000
    }

}

/// Aggregates measured iterations into one JSONL row. Iterations with index below
/// `warmupIterations` are excluded from the statistics (by index, so a failed warmup iteration
/// never shifts a slow measured one into the discarded window), and errors are reported both in
/// total and for the post-warmup window: a run whose candidate "wins" by erroring out of its
/// slowest iterations must be visibly invalid, not quietly faster.
struct BenchmarkMetrics {

    private var measurementsByIteration: [Int: IterationMeasurement] = [:]
    private var errorsByIteration: [Int: String] = [:]

    mutating func record(_ measurement: IterationMeasurement, iteration: Int) {
        self.measurementsByIteration[iteration] = measurement
    }

    mutating func record(error: Error, iteration: Int) {
        self.errorsByIteration[iteration] = "\(error)"
    }

    /// Errors in the measured (post-warmup) window. Nonzero means the row's timing statistics
    /// are not valid comparison input, and the process must exit nonzero so automation notices.
    func postWarmupErrorCount(warmupIterations: Int) -> Int {
        return self.errorsByIteration.filter { $0.key >= warmupIterations }.count
    }

    func jsonlRow(for command: BenchmarkCommand) -> String {
        let measured = self.measurementsByIteration
            .filter { $0.key >= command.warmupIterations }
            .sorted { $0.key < $1.key }
            .map(\.value)
        let totals = measured.map(\.totalMs).sorted()

        var row: [String: Any] = [
            "mode": command.mode.rawValue,
            "transport": command.transport.rawValue,
            "scenario": command.scenario.rawValue,
            "profile": command.profileName,
            "loss_percent": command.lossPercent,
            "paywalls": command.paywallCount,
            "workflows": command.workflowCount,
            "seed": command.seed,
            "iterations": command.iterations,
            "warmup_discarded": command.warmupIterations,
            "measured_iterations": measured.count,
            "error_count": self.errorsByIteration.count,
            "post_warmup_error_count": self.postWarmupErrorCount(warmupIterations: command.warmupIterations)
        ]

        if !totals.isEmpty {
            row["mean_ms"] = Self.rounded(totals.reduce(0, +) / Double(totals.count))
            row["min_ms"] = Self.rounded(totals[0])
            row["max_ms"] = Self.rounded(totals[totals.count - 1])
            for percentile in [50, 90, 95, 99] {
                row["p\(percentile)_ms"] = Self.rounded(Self.percentile(percentile, of: totals))
            }
        }

        row += Self.aggregates(of: measured)

        if let projectID = command.projectID {
            row["project_id"] = projectID
        }

        if let firstError = self.errorsByIteration.min(by: { $0.key < $1.key }) {
            row["first_error"] = "iteration \(firstError.key): \(firstError.value)"
        }

        for (key, value) in command.annotations {
            row[key] = value
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: row, options: [.sortedKeys])
            return String(bytes: data, encoding: .utf8) ?? "{}"
        } catch {
            preconditionFailure("Could not serialize benchmark row: \(error)")
        }
    }

    private static func aggregates(of measured: [IterationMeasurement]) -> [String: Any] {
        guard !measured.isEmpty else { return [:] }

        let count = Double(measured.count)
        var aggregates: [String: Any] = [
            "request_count_mean": Self.rounded(Double(measured.reduce(0) { $0 + $1.requestCount }) / count),
            "bytes_received_mean": Self.rounded(Double(measured.reduce(0) { $0 + $1.bytesReceived }) / count),
            "failed_requests_total": measured.reduce(0) { $0 + $1.failedRequestCount },
            "fallback_host_requests_total": measured.reduce(0) { $0 + $1.fallbackHostRequestCount }
        ]

        for (key, values) in [
            ("offerings_ms_mean", measured.compactMap(\.offeringsMs)),
            ("config_ms_mean", measured.compactMap(\.configMs)),
            ("blob_ms_mean", measured.compactMap(\.blobMs)),
            ("blobs_inline_mean", measured.map { Double($0.blobs.inlineCount) }),
            ("blobs_downloaded_mean", measured.map { Double($0.blobs.downloadedCount) }),
            ("blob_bytes_mean", measured.map { Double($0.blobs.totalBytes) })
        ] where !values.isEmpty {
            aggregates[key] = Self.rounded(values.reduce(0, +) / Double(values.count))
        }

        // Size extremes across the run bracket the backend's inline-size budget.
        if let maxInline = measured.compactMap(\.blobs.maxInlineBytes).max() {
            aggregates["max_inline_blob_bytes"] = maxInline
        }
        if let minDownloaded = measured.compactMap(\.blobs.minDownloadedBytes).min() {
            aggregates["min_downloaded_blob_bytes"] = minDownloaded
        }

        return aggregates
    }

    /// Nearest-rank percentile over an already-sorted array.
    static func percentile(_ percentile: Int, of sorted: [Double]) -> Double {
        precondition(!sorted.isEmpty)
        let rank = Int((Double(percentile) / 100 * Double(sorted.count)).rounded(.up))
        return sorted[max(0, min(sorted.count - 1, rank - 1))]
    }

    private static func rounded(_ value: Double) -> Double {
        return (value * 1_000).rounded() / 1_000
    }

}
