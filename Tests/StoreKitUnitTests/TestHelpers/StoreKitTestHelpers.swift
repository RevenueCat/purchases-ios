//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKitTestHelpers.swift
//
//  Created by Nacho Soto on 1/24/22.

import Nimble
@testable import RevenueCat
import StoreKit
import StoreKitTest
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension XCTestCase {

    private enum Error: Swift.Error {
        case invalidTransactions([StoreKit.VerificationResult<Transaction>])
    }

    func verifyNoUnfinishedTransactions(file: StaticString = #file, line: UInt = #line) async {
        let unfinished = await StoreKit.Transaction.unfinished.extractValues()
        expect(file: file, line: line, unfinished).to(beEmpty())
    }

    func verifyUnfinishedTransaction(
        withId identifier: Transaction.ID,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let unfinishedTransactions = await self.unfinishedTransactions

        expect(file: file, line: line, unfinishedTransactions).to(haveCount(1))

        guard let transaction = unfinishedTransactions.onlyElement,
              case let .verified(verified) = transaction else {
            throw Error.invalidTransactions(unfinishedTransactions)
        }

        expect(file: file, line: line, verified.id) == identifier
    }

    func waitUntilUnfinishedTransactions(
        condition: @Sendable @escaping (Int) -> Bool,
        file: FileString = #fileID,
        line: UInt = #line
    ) async throws {
        try await asyncWait(
            description: { "Transaction expectation never met: \($0 ?? [])" },
            file: file,
            line: line,
            until: { await Transaction.unfinished.extractValues() },
            condition: { condition($0.count) }
        )
    }

    func waitUntilNoUnfinishedTransactions(file: FileString = #fileID, line: UInt = #line) async throws {
        try await self.waitUntilUnfinishedTransactions { $0 == 0 }
    }

    func deleteAllTransactions(session: SKTestSession) async {
        let sk1Transactions = session.allTransactions()
        if !sk1Transactions.isEmpty {
            Logger.debug(StoreKitTestMessage.deletingTransactions(count: sk1Transactions.count))

            for transaction in sk1Transactions {
                try? session.deleteTransaction(identifier: transaction.identifier)
            }
        }

        let sk2Transactions = await self.unfinishedTransactions
        if !sk2Transactions.isEmpty {
            Logger.debug(StoreKitTestMessage.finishingTransactions(count: sk2Transactions.count))

            for transaction in sk2Transactions.map(\.underlyingTransaction) {
                await transaction.finish()
                try? session.deleteTransaction(identifier: UInt(transaction.id))
            }
        }
    }

    private var unfinishedTransactions: [StoreKit.VerificationResult<Transaction>] {
        get async { return await StoreKit.Transaction.unfinished.extractValues() }
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension Product.PurchaseResult {

    var verificationResult: StoreKit.VerificationResult<Transaction>? {
        switch self {
        case let .success(verificationResult): return verificationResult
        case .userCancelled: return nil
        case .pending: return nil
        @unknown default: return nil
        }
    }

}

enum StoreKitTestMessage: LogMessage {

    case delayingTest(TimeInterval)
    case errorRemovingReceipt(URL, Error)
    case deletingTransactions(count: Int)
    case finishingTransactions(count: Int)

    var description: String {
        switch self {
        case let .delayingTest(waitTime):
            return "Delaying tests for \(waitTime) seconds for StoreKit initialization..."
        case let .errorRemovingReceipt(url, error):
            return "Error attempting to remove receipt URL '\(url)': \(error)"
        case let .deletingTransactions(count):
            return "Deleting \(count) transactions"
        case let .finishingTransactions(count):
            return "Finishing \(count) transactions"
        }
    }

    var category: String { return "StoreKitConfigTestCase" }

}
