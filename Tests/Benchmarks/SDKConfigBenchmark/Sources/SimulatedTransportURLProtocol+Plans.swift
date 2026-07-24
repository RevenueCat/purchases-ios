import Foundation

// MARK: - Deterministic request plans

extension SimulatedTransportURLProtocol {

    /// Identity of one simulated request. Plans derive from this key alone, so the same key
    /// always produces the same plan, in any process, in any request order.
    struct PlanKey {

        let seed: UInt64
        let iteration: Int
        let url: URL
        let attempt: Int

        /// FNV-1a over the request identity, mixed with the run seed.
        var hashValue64: UInt64 {
            var hash: UInt64 = 0xCBF29CE484222325
            func mix(_ byte: UInt8) {
                hash ^= UInt64(byte)
                hash = hash &* 0x100000001B3
            }
            func mix(_ value: UInt64) {
                for shift in stride(from: 0, to: 64, by: 8) {
                    mix(UInt8(truncatingIfNeeded: value >> shift))
                }
            }
            mix(self.seed)
            mix(UInt64(bitPattern: Int64(self.iteration)))
            for byte in self.url.absoluteString.utf8 {
                mix(byte)
            }
            mix(UInt64(bitPattern: Int64(self.attempt)))
            return hash
        }

    }

    struct RequestPlan {
        let rttMs: Double
        let fails: Bool
        let chunkDelaysMs: [Double]
    }

    /// Computes the full network timeline of one request from its stable key.
    static func requestPlan(
        key: PlanKey,
        bodyCount: Int,
        profile: NetworkProfile,
        loss: LossModel
    ) -> RequestPlan {
        var rng = SeededRandom(seed: key.hashValue64)

        let rttMs = profile.rttMs(for: RequestKind(url: key.url), rng: &rng)
        let fails = loss.shouldFailRequest(rng: &rng)
        var chunkDelaysMs: [Double] = []
        // Loss-free plans skip the per-chunk delay array entirely (delivery treats an empty
        // array as zero delay everywhere).
        if !fails && loss.lossPercent > 0 {
            var offset = 0
            while offset < bodyCount {
                chunkDelaysMs.append(loss.chunkRetransmitDelayMs(rttMs: rttMs, rng: &rng))
                offset += Self.chunkSize
            }
        }
        return RequestPlan(rttMs: rttMs, fails: fails, chunkDelaysMs: chunkDelaysMs)
    }

}
