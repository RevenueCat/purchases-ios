//
// Created by Andrés Boedo on 8/11/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
@testable import Purchases

class MockReceiptParser: ReceiptParser {

    var invokedParse = false
    var invokedParseCount = 0
    var invokedParseParameters: Data?
    var invokedParseParametersList = [Data]()
    var stubbedParseError: Error?
    var stubbedParseResult = AppleReceipt(bundleId: "com.revenuecat.test",
                                          applicationVersion: "5.6.7",
                                          originalApplicationVersion: "3.4.5",
                                          opaqueValue: Data(),
                                          sha1Hash: Data(),
                                          creationDate: Date(),
                                          expirationDate: nil,
                                          inAppPurchases: [])

    override func parse(from receiptData: Data) throws -> AppleReceipt {
        invokedParse = true
        invokedParseCount += 1
        invokedParseParameters = receiptData
        invokedParseParametersList.append(receiptData)
        if let error = stubbedParseError {
            throw error
        }
        return stubbedParseResult
    }
}