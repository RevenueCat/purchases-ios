//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocalReceiptFetcher.swift
//
//  Created by Mark Villacampa on 8/1/24.

import Foundation

internal protocol LocalReceiptFetcherType: Sendable {

    func fetchAndParseLocalReceipt() throws -> AppleReceipt

}

internal final class LocalReceiptFetcher: LocalReceiptFetcherType {

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
                                                  bundle: .main,
                                                  receiptParser: .default)
    }

    internal func fetchAndParseLocalReceipt(
        reader: FileReader,
        bundle: Bundle,
        receiptParser: PurchasesReceiptParser
    ) throws -> AppleReceipt {
        return try receiptParser.parse(from: self.fetchReceipt(reader, bundle))
    }

}

private extension LocalReceiptFetcher {

    func fetchReceipt(_ reader: FileReader, _ bundle: Bundle) throws -> Data {
        guard let url = bundle.appStoreReceiptURL else {
            throw PurchasesReceiptParser.Error.receiptNotPresent
        }

        do {
            return try reader.contents(of: url)
        } catch {
            throw PurchasesReceiptParser.Error.failedToLoadLocalReceipt(error)
        }
    }

}
