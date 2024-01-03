//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ReceiptFetcher.swift
//
//  Created by Nacho Soto on 1/10/23.

import Foundation

public extension PurchasesReceiptParser {

    // Note: this is a simplified version of `ReceiptFetcher`
    // available for public use.

    /// Fetches and parses the local receipt
    /// - Returns: ``AppleReceipt`` of the parsed local receipt.
    /// - Throws: ``PurchasesReceiptParser/Error`` if fetching or parsing failed.
    ///
    /// - Note: this method won't use ``SKReceiptRefreshRequest`` to
    ///  fetch the receipt if it's not already available.
    ///
    /// ### Related Symbols
    /// - ``SKReceiptRefreshRequest``
    /// - ``Bundle/appStoreReceiptURL``
    /// - ``PurchasesReceiptParser/parse(from:)``
    func fetchAndParseLocalReceipt() throws -> AppleReceipt {
        return try self.fetchAndParseLocalReceipt(reader: DefaultFileReader(),
                                                  bundle: .main)
    }
}
