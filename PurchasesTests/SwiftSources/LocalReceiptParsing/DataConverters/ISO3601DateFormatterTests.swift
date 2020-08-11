import XCTest
import Nimble

@testable import Purchases

class ISO3601DateFormatterTests: XCTestCase {
    
    func testDateFromBytesReturnsCorrectValueIfPossible() {
        let timeZone = TimeZone(identifier: "UTC")
        let dateComponents = DateComponents(timeZone: timeZone,
                                            year: 2020,
                                            month: 7,
                                            day: 14,
                                            hour: 19,
                                            minute: 36,
                                            second: 40)
        let date = Calendar.current.date(from: dateComponents)
        guard let dateBytes = "2020-07-14T19:36:40+0000".data(using: .ascii) else { fatalError() }
        expect(ISO3601DateFormatter.shared.date(fromBytes: ArraySlice(dateBytes))) == date
    }

    func testDateFromBytesReturnsNilIfItCantBeParsedAsString() {
        expect(ISO3601DateFormatter.shared.date(fromBytes: ArraySlice([0b11]))).to(beNil())
    }

    func testDateFromBytesReturnsNilIfItCantBeParsedIntoDate() {
        guard let stringAsBytes = "some string that isn't a date".data(using: .ascii) else { fatalError() }
        expect(ISO3601DateFormatter.shared.date(fromBytes: ArraySlice(stringAsBytes))).to(beNil())
    }
}
