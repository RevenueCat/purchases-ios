//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ReceiptParsingError.swift
//  Purchases
//
//  Created by Andrés Boedo on 7/30/20.
//

import Foundation

extension PurchasesReceiptParser {

    /// An error thrown by ``PurchasesReceiptParser``
    public enum Error: Swift.Error, Equatable {

        /// The data object identifier couldn't be found on the receipt.
        case dataObjectIdentifierMissing

        /// Unable to parse ASN1 container.
        case asn1ParsingError(description: String)

        /// Internal container was empty.
        case receiptParsingError

        /// Failed to parse IAP.
        case inAppPurchaseParsingError

    }
}

extension PurchasesReceiptParser.Error: LocalizedError {

    // swiftlint:disable:next missing_docs
    public var errorDescription: String? {
        switch self {
        case .dataObjectIdentifierMissing:
            return "Couldn't find an object identifier of type data in the receipt"
        case let .asn1ParsingError(description):
            return "Error while parsing, payload can't be interpreted as ASN1. details: \(description)"
        case .receiptParsingError:
            return "Error while parsing the receipt. One or more attributes are missing."
        case .inAppPurchaseParsingError:
            return "Error while parsing in-app purchase. One or more attributes are missing or in the wrong format."
        }
    }

}
