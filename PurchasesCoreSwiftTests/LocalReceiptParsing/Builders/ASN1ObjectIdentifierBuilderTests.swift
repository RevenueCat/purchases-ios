import XCTest
import Nimble

@testable import PurchasesCoreSwift

class ASN1ObjectIdentifierBuilderTests: XCTestCase {

    let encoder = ASN1ObjectIdentifierEncoder()
    func testBuildFromPayloadBuildsCorrectlyForDataPayload() {
        let payload = encoder.objectIdentifierPayload(.data)
        expect(ASN1ObjectIdentifierBuilder().build(fromPayload: payload)) == .data
    }

    func testBuildFromPayloadBuildsCorrectlyForSignedDataPayload() {
        let payload = encoder.objectIdentifierPayload(.signedData)
        expect(ASN1ObjectIdentifierBuilder().build(fromPayload: payload)) == .signedData
    }

    func testBuildFromPayloadBuildsCorrectlyForEnvelopedDataPayload() {
        let payload = encoder.objectIdentifierPayload(.envelopedData)
        expect(ASN1ObjectIdentifierBuilder().build(fromPayload: payload)) == .envelopedData
    }

    func testBuildFromPayloadBuildsCorrectlyForSignedAndEnvelopedDataPayload() {
        let payload = encoder.objectIdentifierPayload(.signedAndEnvelopedData)
        expect(ASN1ObjectIdentifierBuilder().build(fromPayload: payload)) == .signedAndEnvelopedData
    }

    func testBuildFromPayloadBuildsCorrectlyForDigestedDataPayload() {
        let payload = encoder.objectIdentifierPayload(.digestedData)
        expect(ASN1ObjectIdentifierBuilder().build(fromPayload: payload)) == .digestedData
    }

    func testBuildFromPayloadBuildsCorrectlyForEncryptedDataPayload() {
        let payload = encoder.objectIdentifierPayload(.encryptedData)
        expect(ASN1ObjectIdentifierBuilder().build(fromPayload: payload)) == .encryptedData
    }

    func testBuildFromPayloadReturnsNilIfIdentifierNotRecognized() {
        let unknownObjectID = [1, 3, 23, 534643, 7454, 1, 7, 2]
        let payload = encoder.encodeASN1ObjectIdentifier(numbers: unknownObjectID)
        expect(ASN1ObjectIdentifierBuilder().build(fromPayload: payload)).to(beNil())
    }

    func testBuildFromPayloadReturnsNilIfIdentifierPayloadEmpty() {
        let payload: ArraySlice<UInt8> = ArraySlice([])
        expect(ASN1ObjectIdentifierBuilder().build(fromPayload: payload)).to(beNil())
    }
}
