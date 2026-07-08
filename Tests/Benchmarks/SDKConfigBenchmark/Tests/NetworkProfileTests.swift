import XCTest

@testable import SDKConfigBenchmarkCore

final class NetworkProfileTests: BenchmarkTestCase {

    func testProfileLookupByName() {
        XCTAssertEqual(NetworkProfile.named("ideal")?.name, "ideal")
        XCTAssertEqual(NetworkProfile.named("wifi")?.name, "wifi")
        XCTAssertEqual(NetworkProfile.named("lte")?.name, "lte")
        XCTAssertNil(NetworkProfile.named("5g"))
    }

    func testCDNLatencyIsBelowAPILatencyForRealProfiles() {
        for profile in [NetworkProfile.wifi, .lte] {
            XCTAssertLessThan(profile.cdnRTTMs.upperBound, profile.apiRTTMs.upperBound, profile.name)
        }
    }

    func testRTTSamplingIsDeterministicForSameSeed() {
        var first = SeededRandom(seed: 9)
        var second = SeededRandom(seed: 9)

        let firstSamples = (0..<32).map { _ in NetworkProfile.lte.rttMs(forHost: "api.revenuecat.com", rng: &first) }
        let secondSamples = (0..<32).map { _ in NetworkProfile.lte.rttMs(forHost: "api.revenuecat.com", rng: &second) }

        XCTAssertEqual(firstSamples, secondSamples)
        for sample in firstSamples {
            XCTAssertTrue(NetworkProfile.lte.apiRTTMs.contains(sample))
        }
    }

    func testCDNHostsSampleFromCDNRange() {
        var rng = SeededRandom(seed: 9)

        for _ in 0..<32 {
            let sample = NetworkProfile.lte.rttMs(forHost: "cdn.revenuecat.local", rng: &rng)
            XCTAssertTrue(NetworkProfile.lte.cdnRTTMs.contains(sample))
        }
    }

    func testIdealProfileAddsNoDelay() {
        var rng = SeededRandom(seed: 1)

        XCTAssertEqual(NetworkProfile.ideal.rttMs(forHost: "api.revenuecat.com", rng: &rng), 0)
        XCTAssertEqual(NetworkProfile.ideal.transferTimeMs(forByteCount: 10_000_000), 0)
    }

    func testTransferTimeScalesWithBytes() {
        let profile = NetworkProfile.lte

        let small = profile.transferTimeMs(forByteCount: 15_000)
        let large = profile.transferTimeMs(forByteCount: 1_500_000)

        XCTAssertGreaterThan(large, small * 90)
        XCTAssertEqual(profile.transferTimeMs(forByteCount: 1_500_000), 1_000, accuracy: 1)
    }

    func testZeroLossAddsNoDelaysAndNeverFails() {
        var rng = SeededRandom(seed: 3)
        let loss = LossModel(lossPercent: 0)

        for _ in 0..<10_000 {
            XCTAssertEqual(loss.chunkRetransmitDelayMs(rttMs: 80, rng: &rng), 0)
            XCTAssertFalse(loss.shouldFailRequest(rng: &rng))
        }
    }

    func testLossFailureRateMatchesHeuristic() {
        var rng = SeededRandom(seed: 4)
        let loss = LossModel(lossPercent: 30)
        let trials = 10_000

        let failures = (0..<trials).filter { _ in loss.shouldFailRequest(rng: &rng) }.count

        // Heuristic: (0.3)^3 = 2.7% of requests fail. Allow generous sampling tolerance.
        let rate = Double(failures) / Double(trials)
        XCTAssertEqual(rate, 0.027, accuracy: 0.008)
    }

    func testLossChunkDelaysAreDeterministicForSameSeed() {
        let loss = LossModel(lossPercent: 20)
        var first = SeededRandom(seed: 5)
        var second = SeededRandom(seed: 5)

        let firstDelays = (0..<256).map { _ in loss.chunkRetransmitDelayMs(rttMs: 80, rng: &first) }
        let secondDelays = (0..<256).map { _ in loss.chunkRetransmitDelayMs(rttMs: 80, rng: &second) }

        XCTAssertEqual(firstDelays, secondDelays)
        XCTAssertTrue(firstDelays.contains { $0 > 0 }, "20% loss over 256 chunks should add some delay")
    }

}
