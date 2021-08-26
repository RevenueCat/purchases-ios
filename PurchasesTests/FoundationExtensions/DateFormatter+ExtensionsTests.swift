import XCTest
import Nimble

@testable import PurchasesCoreSwift

class DateFormatterExtensionTests: XCTestCase {
    
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
        expect(ArraySlice(dateBytes).toDate()) == date
    }

    func testDateWithMillisecondsFromBytesReturnsCorrectValueIfPossible() {
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
        let receivedDate = ArraySlice(dateBytes).toDate()
        expect(receivedDate!.timeIntervalSince1970).to(beCloseTo(date!.timeIntervalSince1970))
    }

    func testDateFromBytesReturnsNilIfItCantBeParsedAsString() {
        expect(ArraySlice([0b11]).toDate()).to(beNil())
    }

    func testDateFromBytesReturnsNilIfItCantBeParsedIntoDate() {
        guard let stringAsBytes = "some string that isn't a date".data(using: .ascii) else { fatalError() }
        expect(ArraySlice(stringAsBytes).toDate()).to(beNil())
    }
    
    func testDateFromBytesReturnsNilIfEmptyData() {
        expect(ArraySlice(Data()).toDate()).to(beNil())
    }

    func testDateFromStringReturnsNilIfStringCantBeParsed() {
        expect(DateFormatter().date(fromString: "asdb")).to(beNil())
        expect(DateFormatter.iso8601SecondsDateFormatter.date(fromString:"asdf")).to(beNil())
    }

    func testDateFromStringReturnsNilIfStringIsNil() {
        expect(DateFormatter().date(fromString: nil)).to(beNil())
        expect(DateFormatter.iso8601SecondsDateFormatter.date(fromString: nil)).to(beNil())
    }
    
}
