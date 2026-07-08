import Foundation

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
    /// Statuses seen, for warm-scenario verification (304/204).
    let statusCodes: [Int]

    init(totalMs: Double, events: [TransportEvent]) {
        self.totalMs = totalMs
        self.offeringsMs = Self.span(of: events.filter { $0.path.hasSuffix("/offerings") })
        self.configMs = Self.span(of: events.filter { $0.path.hasSuffix("/config/app") })
        self.blobMs = Self.span(of: events.filter { $0.path.contains("/blobs/") })
        self.requestCount = events.count
        self.bytesReceived = events.reduce(0) { $0 + $1.bytesReceived }
        self.failedRequestCount = events.filter(\.failed).count
        self.fallbackHostRequestCount = events
            .filter { $0.host.contains("8-lives-cat") || $0.host.contains("rc-backup") }
            .count
        self.statusCodes = events.map(\.statusCode)
    }

    private static func span(of events: [TransportEvent]) -> Double? {
        guard let first = events.map(\.startedAt.uptimeNanoseconds).min(),
              let last = events.map(\.endedAt.uptimeNanoseconds).max() else {
            return nil
        }
        return Double(last - first) / 1_000_000
    }

}

/// Aggregates measured iterations into one JSONL row. The first `warmupIterations` recorded
/// measurements are excluded from the statistics but counted in `warmup_discarded`, so one-time
/// process costs (lazy statics, first JSON decoder use) don't pollute the distribution.
struct BenchmarkMetrics {

    private var measurements: [IterationMeasurement] = []
    private var errors: [String] = []

    mutating func record(_ measurement: IterationMeasurement) {
        self.measurements.append(measurement)
    }

    mutating func record(error: Error) {
        self.errors.append("\(error)")
    }

    var allStatusCodes: [Int] {
        return self.measurements.flatMap(\.statusCodes)
    }

    var errorCount: Int {
        return self.errors.count
    }

    func jsonlRow(for command: BenchmarkCommand) -> String {
        let measured = Array(self.measurements.dropFirst(command.warmupIterations))
        let totals = measured.map(\.totalMs).sorted()

        var row: [String: Any] = [
            "mode": command.mode.rawValue,
            "scenario": command.scenario.rawValue,
            "profile": command.profileName,
            "loss_percent": command.lossPercent,
            "paywalls": command.paywallCount,
            "workflows": command.workflowCount,
            "seed": command.seed,
            "iterations": command.iterations,
            "warmup_discarded": min(command.warmupIterations, self.measurements.count),
            "error_count": self.errors.count
        ]

        if !totals.isEmpty {
            row["mean_ms"] = Self.rounded(totals.reduce(0, +) / Double(totals.count))
            row["min_ms"] = Self.rounded(totals[0])
            row["max_ms"] = Self.rounded(totals[totals.count - 1])
            for percentile in [50, 90, 95, 99] {
                row["p\(percentile)_ms"] = Self.rounded(Self.percentile(percentile, of: totals))
            }
        }

        if !measured.isEmpty {
            let count = Double(measured.count)
            row["request_count_mean"] = Self.rounded(Double(measured.reduce(0) { $0 + $1.requestCount }) / count)
            row["bytes_received_mean"] = Self.rounded(Double(measured.reduce(0) { $0 + $1.bytesReceived }) / count)
            row["failed_requests_total"] = measured.reduce(0) { $0 + $1.failedRequestCount }
            row["fallback_host_requests_total"] = measured.reduce(0) { $0 + $1.fallbackHostRequestCount }

            for (key, values) in [
                ("offerings_ms_mean", measured.compactMap(\.offeringsMs)),
                ("config_ms_mean", measured.compactMap(\.configMs)),
                ("blob_ms_mean", measured.compactMap(\.blobMs))
            ] where !values.isEmpty {
                row[key] = Self.rounded(values.reduce(0, +) / Double(values.count))
            }
        }

        if !self.errors.isEmpty {
            row["first_error"] = self.errors[0]
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
