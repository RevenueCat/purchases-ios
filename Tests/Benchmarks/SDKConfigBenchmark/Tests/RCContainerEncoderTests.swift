import XCTest

@testable import SDKConfigBenchmarkCore

final class RCContainerEncoderTests: BenchmarkTestCase {

    private let config = Data(#"{"domain":"app","manifest":"m1"}"#.utf8)
    private let blobA = Data(#"{"id":"blob-a"}"#.utf8)
    private let blobB = Data(String(repeating: "x", count: 300).utf8)

    func testEncodedContainerRoundTripsThroughSDKParser() throws {
        let encoded = RCContainerEncoder.container(config: self.config, contentElements: [self.blobA, self.blobB])

        let parsed = try RCContainer(data: encoded)

        XCTAssertEqual(parsed.elements.count, 3)
        XCTAssertEqual(try parsed.elements[0].withDecodedPayloadBytes { Data($0) }, self.config)
        XCTAssertEqual(try parsed.elements[1].withDecodedPayloadBytes { Data($0) }, self.blobA)
        XCTAssertEqual(try parsed.elements[2].withDecodedPayloadBytes { Data($0) }, self.blobB)
    }

    func testEncodedElementChecksumsMatchBlobRefs() throws {
        let encoded = RCContainerEncoder.container(config: self.config, contentElements: [self.blobA])

        let parsed = try RCContainer(data: encoded)

        XCTAssertEqual(parsed.elements[1].checksum, RCContainerEncoder.blobRef(for: self.blobA))
        XCTAssertNotNil(parsed.elementsByChecksum[RCContainerEncoder.blobRef(for: self.blobA)])
    }

    func testBlobRefShape() {
        let ref = RCContainerEncoder.blobRef(for: self.blobA)

        XCTAssertEqual(ref.count, 32)
        XCTAssertNil(ref.rangeOfCharacter(from: CharacterSet(charactersIn: "+/=")))
    }

    func testConfigOnlyContainerParses() throws {
        let encoded = RCContainerEncoder.container(config: self.config, contentElements: [])

        let parsed = try RCContainer(data: encoded)

        XCTAssertEqual(parsed.elements.count, 1)
    }

    func testSeededRandomIsDeterministic() {
        var first = SeededRandom(seed: 7)
        var second = SeededRandom(seed: 7)
        var other = SeededRandom(seed: 8)

        let firstValues = (0..<8).map { _ in first.next() }
        let secondValues = (0..<8).map { _ in second.next() }
        let otherValues = (0..<8).map { _ in other.next() }

        XCTAssertEqual(firstValues, secondValues)
        XCTAssertNotEqual(firstValues, otherValues)
    }

    func testSeededRandomUniformDoubleStaysInRange() {
        var rng = SeededRandom(seed: 1)

        for _ in 0..<1_000 {
            let value = Double.random(in: 0..<1, using: &rng)
            XCTAssertGreaterThanOrEqual(value, 0)
            XCTAssertLessThan(value, 1)
        }
    }

}
