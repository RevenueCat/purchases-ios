import Nimble
import XCTest

@testable import RevenueCat

class ASN1ContainerBuilderTests: TestCase {
    var containerBuilder: ASN1ContainerBuilder!
    let mockContainerPayload: [UInt8] = [0b01, 0b01, 0b01, 0b01, 0b01, 0b01, 0b01, 0b01, 0b01]
    let lengthByteForIndefiniteLengthContainers = 0b10000000

    override func setUp() {
        super.setUp()
        containerBuilder = ASN1ContainerBuilder()
    }

    func testBuildFromContainerExtractsClassCorrectly() throws {
        let universalClassByte: UInt8 = 0b00000000
        var payloadArray = mockContainerPayload
        payloadArray.insert(universalClassByte, at: 0)
        var payload = ArraySlice(payloadArray)
        try expect(self.containerBuilder.build(fromPayload: payload).containerClass) == .universal

        let applicationClassByte: UInt8 = 0b01000000
        payloadArray = mockContainerPayload
        payloadArray.insert(applicationClassByte, at: 0)
        payload = ArraySlice(payloadArray)
        try expect(self.containerBuilder.build(fromPayload: payload).containerClass) == .application

        let contextSpecificClassByte: UInt8 = 0b10000000
        payloadArray = mockContainerPayload
        payloadArray.insert(contextSpecificClassByte, at: 0)
        payload = ArraySlice(payloadArray)
        try expect(self.containerBuilder.build(fromPayload: payload).containerClass) == .contextSpecific

        let privateClassByte: UInt8 = 0b11000000
        payloadArray = mockContainerPayload
        payloadArray.insert(privateClassByte, at: 0)
        payload = ArraySlice(payloadArray)
        try expect(self.containerBuilder.build(fromPayload: payload).containerClass) == .private
    }

    func testBuildFromContainerExtractsEncodingTypeCorrectly() throws {
        let primitiveEncodingByte: UInt8 = 0b00000000
        var payloadArray = mockContainerPayload
        payloadArray.insert(primitiveEncodingByte, at: 0)
        var payload = ArraySlice(payloadArray)
        try expect(self.containerBuilder.build(fromPayload: payload).encodingType) == .primitive

        let constructedEncodingByte: UInt8 = 0b00100000
        payloadArray = mockContainerPayload
        payloadArray.insert(constructedEncodingByte, at: 0)

        let containerLenghtByte: UInt8 = UInt8(3)
        payloadArray.insert(containerLenghtByte, at: 1)

        payload = ArraySlice(payloadArray)
        try expect(self.containerBuilder.build(fromPayload: payload).encodingType) == .constructed
    }

    func testBuildFromContainerExtractsIdentifierCorrectly() throws {
        for expectedIdentifier in ASN1Identifier.allCases {
            let identifierByte = UInt8(expectedIdentifier.rawValue)

            var payloadArray = mockContainerPayload
            payloadArray.insert(identifierByte, at: 0)
            let payload = ArraySlice(payloadArray)
            try expect(self.containerBuilder.build(fromPayload: payload).containerIdentifier) == expectedIdentifier
        }
    }

    func testBuildFromContainerExtractsShortLengthCorrectly() throws {
        let shortLengthValue: UInt8 = UInt8(mockContainerPayload.count - 1)

        var payloadArray = mockContainerPayload
        payloadArray.insert(shortLengthValue, at: 1)
        let payload = ArraySlice(payloadArray)

        let container = try self.containerBuilder.build(fromPayload: payload)
        expect(container.length.value) == Int(shortLengthValue)
        expect(container.length.bytesUsedForLength) == 1
        expect(container.internalPayload.count) == Int(shortLengthValue)
        expect(container.internalPayload) == payload.dropFirst(2).prefix(Int(shortLengthValue))
    }

    func testBuildFromContainerExtractsLongLengthCorrectly() throws {
        // first 1 indicates long length, the next 7 bits are the number of bytes used for length
        let totalLengthBytes: [UInt8] = [0b10000011]

        // bytes after the first indicate the actual length value.
        let lengthBytes: [UInt8] = [0b1, 0b1, 0b11]
        let expectedLengthValue = ArraySlice(lengthBytes).toInt()

        let lengthArray = totalLengthBytes + lengthBytes

        var payloadArray: [UInt8] = Array(repeating: 0, count: 100000)
        payloadArray.insert(contentsOf: lengthArray, at: 1)
        let payload = ArraySlice(payloadArray)

        let container = try self.containerBuilder.build(fromPayload: payload)

        expect(container.length.value) == expectedLengthValue
        expect(container.length.bytesUsedForLength) == 4
        expect(container.internalPayload.count) == Int(expectedLengthValue)

        expect(container.internalPayload) == payload.dropFirst(lengthArray.count + 1).prefix(Int(expectedLengthValue))
    }

    func testBuildFromContainerRaisesIfPayloadSizeSmallerThanLengthWithShortLength() {
        let shortLengthValue: UInt8 =  55

        var payloadArray = mockContainerPayload
        payloadArray.insert(shortLengthValue, at: 1)
        let payload = ArraySlice(payloadArray)
        expect { try self.containerBuilder.build(fromPayload: payload).length.value }.to(throwError())
    }

    func testBuildFromContainerRaisesIfPayloadSizeSmallerThanLengthWithLongLength() {
        // first 1 indicates long length, the next 7 bits are the number of bytes used for length
        let totalLengthBytes: [UInt8] = [0b10000011]

        // bytes after the first indicate the actual length value.
        let lengthBytes: [UInt8] = [0b1, 0b1, 0b11]

        let lengthArray = totalLengthBytes + lengthBytes

        var payloadArray: [UInt8] = [0b1, 0b1]
        payloadArray.insert(contentsOf: lengthArray, at: 1)
        let payload = ArraySlice(payloadArray)

        expect { try self.containerBuilder.build(fromPayload: payload).length.value }.to(throwError())
    }

    func testBuildFromContainerCalculatesTotalBytesCorrectlyForShortLength() throws {
        let lengthByte: UInt8 = 0b00000111

        var payloadArray: [UInt8] = Array(repeating: 0, count: 100)
        payloadArray.insert(lengthByte, at: 1)
        let payload = ArraySlice(payloadArray)

        let container = try self.containerBuilder.build(fromPayload: payload)

        expect(container.totalBytesUsed) == 1 + 1 + container.internalPayload.count
        expect(container.internalPayload.count) == Int(container.length.value)
    }

    func testBuildFromContainerCalculatesTotalBytesCorrectlyForLongLength() throws {
        // first 1 indicates long length, the next 7 bits are the number of bytes used for length
        let totalLengthBytes: [UInt8] = [0b10000011]

        let lengthBytes: [UInt8] = [0b1, 0b1, 0b11]

        let lengthArray = totalLengthBytes + lengthBytes

        var payloadArray: [UInt8] = Array(repeating: 0, count: 100000)
        payloadArray.insert(contentsOf: lengthArray, at: 1)
        let payload = ArraySlice(payloadArray)

        let container = try self.containerBuilder.build(fromPayload: payload)

        expect(container.totalBytesUsed) == 1 + lengthArray.count + container.internalPayload.count
    }

    func testBuildFromContainerThatIsTooSmallThrows() {
        expect { try self.containerBuilder.build(fromPayload: ArraySlice([0b1])) }.to(throwError())
    }

    func testBuildFromContainerBuildsInternalContainersCorrectlyIfTypeIsConstructed() throws {
        let constructedEncodingByte: UInt8 = 0b00100000

        let subContainer1InternalPayload = Array(repeating: UInt8(0b1), count: 4)
        let subContainer2InternalPayload = Array(repeating: UInt8(0b1), count: 6)
        let subContainer1Payload: [UInt8] = [UInt8(0b1),
                                             UInt8(subContainer1InternalPayload.count)]
                                             + subContainer1InternalPayload
        let subContainer2Payload: [UInt8] = [UInt8(0b1),
                                             UInt8(subContainer2InternalPayload.count)]
                                             + subContainer2InternalPayload

        let containerPayload: [UInt8] = [constructedEncodingByte, // id byte
                                         UInt8(subContainer1Payload.count + subContainer2Payload.count)] // length byte
                                         + subContainer1Payload + subContainer2Payload // payload

        let payload = ArraySlice(containerPayload)
        let container = try self.containerBuilder.build(fromPayload: payload)

        expect(container.internalContainers.count) == 2
    }

    func testBuildFromContainerDoesntBuildInternalContainersIfTypeIsPrimitive() throws {
        let primitiveEncodingByte: UInt8 = 0b00000000
        var payloadArray = mockContainerPayload
        payloadArray.insert(primitiveEncodingByte, at: 0)
        let payload = ArraySlice(payloadArray)

        let container = try self.containerBuilder.build(fromPayload: payload)
        expect(container.encodingType) == .primitive
        expect(container.internalContainers).to(beEmpty())
    }

    func testBuildFromContainerRaisesIfTypeIsConstructedButContainerCantBeBuiltFromPayload() {
        let constructedEncodingByte: UInt8 = 0b00100000
        var payloadArray = mockContainerPayload
        payloadArray.insert(constructedEncodingByte, at: 0)
        let payload = ArraySlice(payloadArray)

        expect { try self.containerBuilder.build(fromPayload: payload) }.to(throwError())
    }

    func testBuildFromContainerExtractsLengthCorrectlyForIndefiniteLength() throws {
        let constructedEncodingByte: UInt8 = 0b00100000

        let subContainer1InternalPayload = Array(repeating: UInt8(0b1), count: 4)
        let subContainer2InternalPayload = Array(repeating: UInt8(0b1), count: 6)
        let subContainer1Payload: [UInt8] = [UInt8(0b1),
                                             UInt8(subContainer1InternalPayload.count)]
                                             + subContainer1InternalPayload
        let subContainer2Payload: [UInt8] = [UInt8(0b1),
                                             UInt8(subContainer2InternalPayload.count)]
                                             + subContainer2InternalPayload

        let containerPayload: [UInt8] = [constructedEncodingByte, // id byte
                                         UInt8(lengthByteForIndefiniteLengthContainers)] // length byte
                                         + subContainer1Payload + subContainer2Payload // payload

        let payload = ArraySlice(containerPayload)
        let container = try self.containerBuilder.build(fromPayload: payload)

        expect(container.length.value) == 14
        expect(container.length.bytesUsedForLength) == 1
        expect(container.length.definition) == .indefinite
    }

    func testBuildFromContainerExtractsInnerContainersCorrectlyForIndefiniteLength() throws {
        let constructedEncodingByte: UInt8 = 0b00100000

        let subContainer1InternalPayload = Array(repeating: UInt8(0b1), count: 4)
        let subContainer2InternalPayload = Array(repeating: UInt8(0b1), count: 6)
        let subContainer1Payload: [UInt8] = [UInt8(0b1),
                                             UInt8(subContainer1InternalPayload.count)]
                                             + subContainer1InternalPayload
        let subContainer2Payload: [UInt8] = [UInt8(0b1),
                                             UInt8(subContainer2InternalPayload.count)]
                                             + subContainer2InternalPayload

        let containerPayload: [UInt8] = [constructedEncodingByte, // id byte
                                         UInt8(lengthByteForIndefiniteLengthContainers)] // length byte
                                         + subContainer1Payload + subContainer2Payload // payload

        let payload = ArraySlice(containerPayload)
        let container = try self.containerBuilder.build(fromPayload: payload)

        expect(container.internalContainers.count) == 2
    }

}
