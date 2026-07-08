import Foundation

/// A named network condition applied by `SimulatedTransportURLProtocol`.
///
/// API endpoints (dynamic backend calls) and CDN endpoints (static blob downloads) get separate
/// round-trip ranges because the config system's premise is that blobs are served from cheap,
/// cacheable CDN edges while `/v1/config` and `/v1/subscribers/.../offerings` hit the backend.
/// A flat per-request latency would structurally bias results against whichever mode issues
/// more requests, regardless of what those requests cost in production.
struct NetworkProfile {

    let name: String
    /// Round-trip time range for dynamic API requests, in milliseconds. Sampled uniformly.
    let apiRTTMs: ClosedRange<Double>
    /// Round-trip time range for CDN blob requests, in milliseconds. Sampled uniformly.
    let cdnRTTMs: ClosedRange<Double>
    /// Downlink throughput; `nil` means body transfer time is not modeled.
    let bandwidthBytesPerSec: Double?

    static let ideal = NetworkProfile(
        name: "ideal",
        apiRTTMs: 0...0,
        cdnRTTMs: 0...0,
        bandwidthBytesPerSec: nil
    )

    /// Good home wifi: low RTT, ~50 Mbit/s downlink.
    static let wifi = NetworkProfile(
        name: "wifi",
        apiRTTMs: 25...40,
        cdnRTTMs: 10...20,
        bandwidthBytesPerSec: 50_000_000 / 8
    )

    /// Typical LTE: higher and jitterier RTT, ~12 Mbit/s downlink.
    static let lte = NetworkProfile(
        name: "lte",
        apiRTTMs: 55...110,
        cdnRTTMs: 30...70,
        bandwidthBytesPerSec: 12_000_000 / 8
    )

    static func named(_ name: String) -> NetworkProfile? {
        switch name {
        case Self.ideal.name: return .ideal
        case Self.wifi.name: return .wifi
        case Self.lte.name: return .lte
        default: return nil
        }
    }

    /// RTT class follows the request kind, the same classification everything else uses:
    /// offerings and config are dynamic API calls, blobs are CDN downloads.
    func rttMs(for kind: RequestKind, rng: inout SeededRandom) -> Double {
        let range: ClosedRange<Double>
        switch kind {
        case .offerings, .config: range = self.apiRTTMs
        case .blob: range = self.cdnRTTMs
        }
        guard range.lowerBound < range.upperBound else { return range.lowerBound }
        return Double.random(in: range, using: &rng)
    }

    /// Transfer time for `byteCount` at the profile's bandwidth, in milliseconds.
    func transferTimeMs(forByteCount byteCount: Int) -> Double {
        guard let bandwidth = self.bandwidthBytesPerSec, bandwidth > 0 else { return 0 }
        return Double(byteCount) / bandwidth * 1_000
    }

}

/// Approximates packet loss for the simulated transport.
///
/// This deliberately does NOT model real TCP behavior. Loss on a real connection shows up as
/// retransmission delays, stalled transfers, and occasional timeouts, not as a proportional
/// request failure rate. The approximation here:
/// - per delivered chunk, with probability `lossPercent`, one retransmission delay of 1x-2x RTT
///   is added before the chunk arrives;
/// - per request, with probability `(lossPercent/100)^3` (all retries of a critical packet
///   lost), the whole request fails with `URLError(.timedOut)` after one RTO so the SDK's
///   retry and fallback-host paths are exercised at a plausible rate.
/// Good enough to compare the two fetch systems under identical degraded conditions; not a
/// substitute for link-conditioner testing when absolute numbers matter.
struct LossModel {

    let lossPercent: Int

    var lossProbability: Double {
        return Double(self.lossPercent) / 100
    }

    var requestFailureProbability: Double {
        let loss = self.lossProbability
        return loss * loss * loss
    }

    /// Extra delay (ms) to add before a chunk of the response body, given the connection RTT.
    func chunkRetransmitDelayMs(rttMs: Double, rng: inout SeededRandom) -> Double {
        guard self.lossPercent > 0 else { return 0 }
        guard Double.random(in: 0..<1, using: &rng) < self.lossProbability else { return 0 }
        return rttMs * Double.random(in: 1...2, using: &rng)
    }

    func shouldFailRequest(rng: inout SeededRandom) -> Bool {
        guard self.lossPercent > 0 else { return false }
        return Double.random(in: 0..<1, using: &rng) < self.requestFailureProbability
    }

}
