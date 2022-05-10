import Nimble
import XCTest

@testable import RevenueCat

class UInt8ExtensionsTests: TestCase {

    func testBitAtIndexGetsCorrectValue() {
        expect(try UInt8(0b10000000).bitAtIndex(0)) == 1
        expect(try UInt8(0b10000000).bitAtIndex(1)) == 0
        expect(try UInt8(0b00100000).bitAtIndex(2)) == 1
        expect(try UInt8(0b00010100).bitAtIndex(3)) == 1
        expect(try UInt8(0b01100000).bitAtIndex(4)) == 0
        expect(try UInt8(0b10001111).bitAtIndex(5)) == 1
        expect(try UInt8(0b10000000).bitAtIndex(6)) == 0
        expect(try UInt8(0b10000001).bitAtIndex(7)) == 1
    }

    func testBitAtIndexRaisesIfInvalidIndex() {
        expect { _ = try UInt8(0b1).bitAtIndex(7) }.notTo(throwError())
        expect { _ = try UInt8(0b1).bitAtIndex(8) }.to(throwError(BitShiftError.invalidIndex(8)))
    }

    func testValueInRangeGetsCorrectValue() {
        expect(try UInt8(0b10000000).valueInRange(from: 0, to: 1)) == 0b10
        expect(try UInt8(0b10000000).valueInRange(from: 0, to: 4)) == 0b10000
        expect(try UInt8(0b00100000).valueInRange(from: 1, to: 7)) == 0b0100000
        expect(try UInt8(0b11111111).valueInRange(from: 3, to: 5)) == 0b111
        expect(try UInt8(0b01100000).valueInRange(from: 5, to: 7)) == 0b000
        expect(try UInt8(0b10001111).valueInRange(from: 2, to: 5)) == 0b0011
        expect(try UInt8(0b10000010).valueInRange(from: 6, to: 6)) == 0b1
    }

    func testValueInRangeRaisesIfInvalidRange() {
        expect { _ = try UInt8(0b10000010).valueInRange(from: 1, to: 6)}.notTo(throwError())
        expect {
            _ = try UInt8(0b10000010).valueInRange(from: 6, to: 1)
        }
        .to(throwError(BitShiftError.rangeFlipped(from: 6, to: 1)))
        expect { _ = try UInt8(0b10000010).valueInRange(from: 6, to: 8)}.to(throwError(BitShiftError.invalidIndex(8)))
    }
}
