import XCTest
import Nimble

@testable import PurchasesCoreSwift

class UInt8ExtensionsTests: XCTestCase {
    
    func testBitAtIndexGetsCorrectValue() {
        expect(UInt8(0b10000000).bitAtIndex(0)) == 1
        expect(UInt8(0b10000000).bitAtIndex(1)) == 0
        expect(UInt8(0b00100000).bitAtIndex(2)) == 1
        expect(UInt8(0b00010100).bitAtIndex(3)) == 1
        expect(UInt8(0b01100000).bitAtIndex(4)) == 0
        expect(UInt8(0b10001111).bitAtIndex(5)) == 1
        expect(UInt8(0b10000000).bitAtIndex(6)) == 0
        expect(UInt8(0b10000001).bitAtIndex(7)) == 1
    }

    func testBitAtIndexRaisesIfInvalidIndex() {
        // throwAssertion isn't supported on 32-bit simulators
        // https://github.com/Quick/Nimble/blob/master/Sources/Nimble/Matchers/ThrowAssertion.swift#L46
        #if arch(x86_64)
        expect { _ = UInt8(0b1).bitAtIndex(7) }.notTo(throwAssertion())
        expect { _ = UInt8(0b1).bitAtIndex(8) }.to(throwAssertion())
        #endif
    }
    
    func testValueInRangeGetsCorrectValue() {
        expect(UInt8(0b10000000).valueInRange(from: 0, to: 1)) == 0b10
        expect(UInt8(0b10000000).valueInRange(from: 0, to: 4)) == 0b10000
        expect(UInt8(0b00100000).valueInRange(from: 1, to: 7)) == 0b0100000
        expect(UInt8(0b11111111).valueInRange(from: 3, to: 5)) == 0b111
        expect(UInt8(0b01100000).valueInRange(from: 5, to: 7)) == 0b000
        expect(UInt8(0b10001111).valueInRange(from: 2, to: 5)) == 0b0011
        expect(UInt8(0b10000010).valueInRange(from: 6, to: 6)) == 0b1
    }
    
    func testValueInRangeRaisesIfInvalidRange() {
        // throwAssertion isn't supported on 32-bit simulators
        // https://github.com/Quick/Nimble/blob/master/Sources/Nimble/Matchers/ThrowAssertion.swift#L46
        #if arch(x86_64)
        expect{ _ = UInt8(0b10000010).valueInRange(from: 1, to: 6)}.notTo(throwAssertion())
        expect{ _ = UInt8(0b10000010).valueInRange(from: 6, to: 1)}.to(throwAssertion())
        expect{ _ = UInt8(0b10000010).valueInRange(from: 6, to: 8)}.to(throwAssertion())
        #endif
    }
}
