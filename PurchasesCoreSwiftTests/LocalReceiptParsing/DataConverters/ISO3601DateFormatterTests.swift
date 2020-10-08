import XCTest
import Nimble

@testable import PurchasesCoreSwift

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
        guard let dateBytes = "2020-07-14T19:36:40Z".data(using: .ascii) else { fatalError() }
        expect(ISO3601DateFormatter.shared.date(fromBytes: ArraySlice(dateBytes))) == date
    }

    func testDateWithMilisecondsFromBytesReturnsCorrectValueIfPossible() {
        let timeZone = TimeZone(identifier: "UTC")
        let dateComponents = DateComponents(timeZone: timeZone,
                                            year: 2020,
                                            month: 7,
                                            day: 14,
                                            hour: 19,
                                            minute: 36,
                                            second: 40,
                                            nanosecond: 202_000_000)
        let date = Calendar.current.date(from: dateComponents)
        guard let dateBytes = "2020-07-14T19:36:40.202Z".data(using: .ascii) else { fatalError() }
        let receivedDate = ISO3601DateFormatter.shared.date(fromBytes: ArraySlice(dateBytes))
        expect(receivedDate!.timeIntervalSince1970).to(beCloseTo(date!.timeIntervalSince1970))
    }

    func testDateFromBytesReturnsNilIfItCantBeParsedAsString() {
        expect(ISO3601DateFormatter.shared.date(fromBytes: ArraySlice([0b11]))).to(beNil())
    }

    func testDateFromBytesReturnsNilIfItCantBeParsedIntoDate() {
        guard let stringAsBytes = "some string that isn't a date".data(using: .ascii) else { fatalError() }
        expect(ISO3601DateFormatter.shared.date(fromBytes: ArraySlice(stringAsBytes))).to(beNil())
    }
    
    func testDateFromBytesReturnsNilIfEmptyData() {
        expect(ISO3601DateFormatter.shared.date(fromBytes: ArraySlice(Data()))).to(beNil())
    }

}
