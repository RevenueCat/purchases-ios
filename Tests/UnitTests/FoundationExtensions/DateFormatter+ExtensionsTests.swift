import Nimble
import XCTest

@testable import RevenueCat

class DateFormatterExtensionTests: TestCase {

    func testDateFromBytesReturnsCorrectValueIfPossible() throws {
        let timeZone = TimeZone(identifier: "UTC")
        let dateComponents = DateComponents(timeZone: timeZone,
                                            year: 2020,
                                            month: 7,
                                            day: 14,
                                            hour: 19,
                                            minute: 36,
                                            second: 40)
        let date = try XCTUnwrap(Calendar.current.date(from: dateComponents))
        let dateBytes = try XCTUnwrap("2020-07-14T19:36:40Z".data(using: .ascii))

        expect(ArraySlice(dateBytes).toDate()) == date
    }

    func testDateWithMillisecondsFromBytesReturnsCorrectValueIfPossible() throws {
        let timeZone = TimeZone(identifier: "UTC")
        let dateComponents = DateComponents(timeZone: timeZone,
                                            year: 2020,
                                            month: 7,
                                            day: 14,
                                            hour: 19,
                                            minute: 36,
                                            second: 40,
                                            nanosecond: 202_000_000)
        let date = try XCTUnwrap(Calendar.current.date(from: dateComponents))
        let dateBytes = try XCTUnwrap("2020-07-14T19:36:40.202Z".data(using: .ascii))
        let receivedDate = try XCTUnwrap(ArraySlice(dateBytes).toDate())

        expect(receivedDate.timeIntervalSince1970).to(beCloseTo(date.timeIntervalSince1970))
    }

    func testISODateFormatterDecodesDateWithMilliseconds() throws {
        let timeZone = TimeZone(identifier: "UTC")
        let dateComponents = DateComponents(timeZone: timeZone,
                                            year: 2020,
                                            month: 7,
                                            day: 14,
                                            hour: 19,
                                            minute: 36,
                                            second: 40,
                                            nanosecond: 202_000_000)

        let result = try XCTUnwrap(ISO8601DateFormatter.default.date(from: "2020-07-14T19:36:40.202Z"))
        let expected = try XCTUnwrap(Calendar.current.date(from: dateComponents))

        expect(result.timeIntervalSince1970).to(beCloseTo(expected.timeIntervalSince1970))
    }

    func testISODateFormatterDecodesDateWithNoMilliseconds() throws {
        let timeZone = TimeZone(identifier: "UTC")
        let dateComponents = DateComponents(timeZone: timeZone,
                                            year: 2020,
                                            month: 7,
                                            day: 14,
                                            hour: 19,
                                            minute: 36,
                                            second: 40,
                                            nanosecond: 0)

        let result = try XCTUnwrap(ISO8601DateFormatter.default.date(from: "2020-07-14T19:36:40Z"))
        let expected = try XCTUnwrap(Calendar.current.date(from: dateComponents))

        expect(result.timeIntervalSince1970).to(beCloseTo(expected.timeIntervalSince1970))
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
        expect(DateFormatter().date(from: "asdb")).to(beNil())
        expect(ISO8601DateFormatter().date(from: "asdf")).to(beNil())
    }

    func testDateFromStringReturnsNilIfStringIsNil() {
        expect(DateFormatter().date(from: nil)).to(beNil())
        expect(ISO8601DateFormatter().date(from: nil)).to(beNil())
    }

}
