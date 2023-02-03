import Nimble
import XCTest

@testable import RevenueCat

class ArraySliceUInt8ExtensionsTests: TestCase {
    func testToUIntReturnsCorrectValue() {
        var arraySlice = ArraySlice([UInt8(0b10000000), UInt8(0b10000000)])
        expect(arraySlice.toUInt64()) == 0b10000000_10000000

        arraySlice = ArraySlice([UInt8(0b1), UInt8(0b01), UInt8(0b10)])
        expect(arraySlice.toUInt64()) == 0b00000001_00000001_00000010

        arraySlice = ArraySlice([UInt8(0b10010100)])
        expect(arraySlice.toUInt64()) == 0b10010100
    }
}
