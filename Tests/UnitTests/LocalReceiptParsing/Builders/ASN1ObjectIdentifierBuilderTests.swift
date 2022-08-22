import Nimble
import XCTest

@testable import RevenueCat

class ASN1ObjectIdentifierBuilderTests: TestCase {

    let encoder = ASN1ObjectIdentifierEncoder()
    func testBuildFromPayloadBuildsCorrectlyForDataPayload() {
        let payload = encoder.objectIdentifierPayload(.data)
        expect(try ASN1ObjectIdentifierBuilder.build(fromPayload: payload)) == .data
    }

    func testBuildFromPayloadBuildsCorrectlyForSignedDataPayload() {
        let payload = encoder.objectIdentifierPayload(.signedData)
        expect(try ASN1ObjectIdentifierBuilder.build(fromPayload: payload)) == .signedData
    }

    func testBuildFromPayloadBuildsCorrectlyForEnvelopedDataPayload() {
        let payload = encoder.objectIdentifierPayload(.envelopedData)
        expect(try ASN1ObjectIdentifierBuilder.build(fromPayload: payload)) == .envelopedData
    }

    func testBuildFromPayloadBuildsCorrectlyForSignedAndEnvelopedDataPayload() {
        let payload = encoder.objectIdentifierPayload(.signedAndEnvelopedData)
        expect(try ASN1ObjectIdentifierBuilder.build(fromPayload: payload)) == .signedAndEnvelopedData
    }

    func testBuildFromPayloadBuildsCorrectlyForDigestedDataPayload() {
        let payload = encoder.objectIdentifierPayload(.digestedData)
        expect(try ASN1ObjectIdentifierBuilder.build(fromPayload: payload)) == .digestedData
    }

    func testBuildFromPayloadBuildsCorrectlyForEncryptedDataPayload() {
        let payload = encoder.objectIdentifierPayload(.encryptedData)
        expect(try ASN1ObjectIdentifierBuilder.build(fromPayload: payload)) == .encryptedData
    }

    func testBuildFromPayloadReturnsNilIfIdentifierNotRecognized() {
        let unknownObjectID = [1, 3, 23, 534643, 7454, 1, 7, 2]
        let payload = encoder.encodeASN1ObjectIdentifier(numbers: unknownObjectID)
        expect(try ASN1ObjectIdentifierBuilder.build(fromPayload: payload)).to(beNil())
    }

    func testBuildFromPayloadReturnsNilIfIdentifierPayloadEmpty() {
        let payload: ArraySlice<UInt8> = ArraySlice([])
        expect(try ASN1ObjectIdentifierBuilder.build(fromPayload: payload)).to(beNil())
    }
}
