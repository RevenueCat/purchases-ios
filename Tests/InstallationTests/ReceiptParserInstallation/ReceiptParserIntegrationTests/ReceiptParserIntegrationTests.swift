//
//  ReceiptParserIntegrationTests.swift
//  ReceiptParserIntegrationTests
//
//  Created by Nacho Soto on 11/29/22.
//

import ReceiptParser
import ReceiptParserIntegration
import XCTest

final class ReceiptParserIntegrationTests: XCTestCase {

    func testParsingEmptyReceiptThrowsError() throws {
        do {
            _ = try PurchasesReceiptParser.default.parse(from: Data())
            XCTFail("Expected error")
        } catch PurchasesReceiptParser.Error.asn1ParsingError {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

}
