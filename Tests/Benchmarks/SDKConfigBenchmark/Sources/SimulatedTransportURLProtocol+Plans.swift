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
            func mix(_ bytes: [UInt8]) {
                for byte in bytes {
                    hash ^= UInt64(byte)
                    hash = hash &* 0x100000001B3
                }
            }
            mix(Array(withUnsafeBytes(of: self.seed.littleEndian) { Data($0) }))
            mix(Array(withUnsafeBytes(of: UInt64(bitPattern: Int64(self.iteration)).littleEndian) { Data($0) }))
            mix(Array(self.url.absoluteString.utf8))
            mix(Array(withUnsafeBytes(of: UInt64(bitPattern: Int64(self.attempt)).littleEndian) { Data($0) }))
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
        let host = key.url.host ?? ""

        let rttMs = profile.rttMs(forHost: host, rng: &rng)
        let fails = loss.shouldFailRequest(rng: &rng)
        var chunkDelaysMs: [Double] = []
        if !fails {
            var offset = 0
            while offset < max(bodyCount, 1) {
                chunkDelaysMs.append(loss.chunkRetransmitDelayMs(rttMs: rttMs, rng: &rng))
                offset += Self.chunkSize
            }
        }
        return RequestPlan(rttMs: rttMs, fails: fails, chunkDelaysMs: chunkDelaysMs)
    }

}
