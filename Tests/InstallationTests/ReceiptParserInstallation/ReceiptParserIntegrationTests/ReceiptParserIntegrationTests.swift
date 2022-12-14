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

    func testCanParseReceipts() throws {
        let receipt = try ReceiptParser.default.parse(from: Data())

        // TODO: check result here
    }

}
