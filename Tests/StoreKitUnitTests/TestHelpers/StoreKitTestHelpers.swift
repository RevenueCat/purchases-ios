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

    func setShortestTestSessionTimeRate(_ testSession: SKTestSession) {
        if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
            #if swift(>=5.8)
            testSession.timeRate = .oneRenewalEveryTwoSeconds
            #else
            testSession.timeRate = SKTestSession.TimeRate.monthlyRenewalEveryThirtySeconds
            #endif
        } else if #available(iOS 15.2, tvOS 15.2, macOS 12.1, watchOS 8.3, *) {
            testSession.timeRate = SKTestSession.TimeRate.monthlyRenewalEveryThirtySeconds
        }
    }

    func setLongestTestSessionTimeRate(_ testSession: SKTestSession) {
        if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
            #if swift(>=5.8)
            testSession.timeRate = .oneRenewalEveryFifteenMinutes
            #else
            testSession.timeRate = SKTestSession.TimeRate.monthlyRenewalEveryHour
            #endif
        } else if #available(iOS 15.2, tvOS 15.2, macOS 12.1, watchOS 8.3, *) {
            testSession.timeRate = SKTestSession.TimeRate.monthlyRenewalEveryHour
        }
    }

    // Some tests were randomly failing on CI when using `.oneRenewalEveryTwoSeconds` due to a race condition where the
    // purchase would expire before the receipt was posted.
    // This time rate is used to work around that issue by having a longer time rate.
    func setOneSecondIsOneDayTimeRate(_ testSession: SKTestSession) {
        // Using rawValue: 6 because the compiler shows this warning for `.oneSecondIsOneDay`:
        // 'oneSecondIsOneDay' was deprecated in iOS 15.2: renamed to
        // 'SKTestSession.TimeRate.monthlyRenewalEveryThirtySeconds'
        // However, we've found that their behavior is not equivalent since using `monthlyRenewalEveryThirtySeconds`
        // results in a crash in our tests.
        testSession.timeRate = .init(rawValue: 6)! // == .oneSecondIsOneDay
    }

    func verifyNoUnfinishedTransactions(file: FileString = #filePath, line: UInt = #line) async {
        let unfinished = await StoreKit.Transaction.unfinished.extractValues()
        expect(file: file, line: line, unfinished).to(beEmpty())
    }

    func verifyUnfinishedTransaction(
        withId identifier: Transaction.ID,
        file: FileString = #filePath,
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
        file: FileString = #filePath,
        line: UInt = #line
    ) async throws {
        try await asyncWait(
            file: file,
            line: line,
            description: { "Transaction expectation never met: \($0 ?? [])" },
            until: { await Transaction.unfinished.extractValues() },
            condition: { condition($0.count) }
        )
    }

    func waitUntilNoUnfinishedTransactions(file: FileString = #fileID, line: UInt = #line) async throws {
        try await self.waitUntilUnfinishedTransactions { $0 == 0 }
    }

    func deleteAllTransactions(session: SKTestSession) async throws {
        let sk2Transactions = await self.unfinishedTransactions
        if !sk2Transactions.isEmpty {
            Logger.debug(StoreKitTestMessage.finishingTransactions(count: sk2Transactions.count))

            for transaction in sk2Transactions.map(\.underlyingTransaction) {
                await transaction.finish()
            }
        }

        session.clearTransactions()
        try await session.spinUntilNoActiveTransactions()
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

// Greatly inspired by https://github.com/dropbox/StoreKitTestHelpers
@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension SKTestSession {
    @MainActor
    @discardableResult func spinUntilNoActiveTransactions(
        maxTries: Int = 1_000,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> Int {
        let allTransactions = allTransactions()
        XCTAssertTrue(
            allTransactions.isEmpty,
            "Precondition failed: non-empty transactions. Make sure to clearTransactions() in the test session first.")

        let attempts = try await Task.spinUntilCondition(condition: {
            let activeProductIDs = await Transaction.activeProductIDs()
            return activeProductIDs.isEmpty
        }, maxTries: maxTries, file: file, line: line)

        return attempts
    }
}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension Task where Failure == Never, Success == Never {
    enum SpinError: Error { case exceededTimeout(String) }

    @MainActor
    @discardableResult static func spinUntilCondition(
        condition: () async throws -> Bool,
        maxTries: Int = 1_000,
        minimumConsecutiveConsistency: Int = 3,
        sleepDuration: TimeInterval = 0.025,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> Int {
        let start = Date()

        var lastConditionResults: [Bool] = []
        for attempt in 0 ... maxTries {
            let prefix = "\(((file.description) as NSString).lastPathComponent) L\(line)"

            if !lastConditionResults.isEmpty, lastConditionResults.count > minimumConsecutiveConsistency {
                _ = lastConditionResults.removeFirst()
            }
            let conditionResult = try await condition()
            lastConditionResults.append(conditionResult)
            if lastConditionResults.count >= minimumConsecutiveConsistency,
               lastConditionResults.allSatisfy({ $0 }) {
                let end = Date()
                let duration = end.timeIntervalSince(start)
                let formattedDuration = "(\(duration.formatted(.number.precision(.fractionLength(1)))) seconds)"
                if attempt > minimumConsecutiveConsistency {
                    print(
                        "\(prefix): Took \(attempt + 1) tries \(formattedDuration) until conditions are what we expect"
                    )
                } else {
                    print(
                        "\(prefix): condition hit on the first \(minimumConsecutiveConsistency) tries " +
                        "\(formattedDuration), nice!"
                    )
                }
                return attempt
            }
            if attempt > maxTries / 2 {
                if #available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *) {
                    try await Task.sleep(for: .seconds(sleepDuration))
                } else {
                    try await Task.sleep(nanoseconds: UInt64(TimeInterval(NSEC_PER_SEC) * sleepDuration))
                }
            } else {
                await Task.yield()
            }
        }
        let end = Date()
        let duration = end.timeIntervalSince(start)
        let failureMessage = "Internal state failed to update after \(maxTries) tries " +
        "(\(duration.formatted(.number.precision(.fractionLength(1)))) seconds), this is a known flake"
        throw SpinError.exceededTimeout(failureMessage)
    }
}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension Transaction {
    static func activeProductIDs() async -> [String] {
        await currentTransactions().map(\.productID)
    }

    /// This includes `Transaction.currentEntitlements` which is limited to subscribed or inGracePeriod,
    /// however it does not check validity
    static func currentTransactions() async -> [Transaction] {
        var transactions = [Transaction]()
        // Iterate through all of the user's purchased products.
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try result.payloadValue
                transactions.append(transaction)
            } catch {
                print(
                    "currentTransactions transaction error, " +
                    "skipping: \(result.unsafePayloadValue.productID) \(error)"
                )
            }
        }
        return transactions
    }
}
