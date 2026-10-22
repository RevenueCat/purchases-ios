//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockTrialOrIntroPriceEligibilityChecker.swift
//
//  Created by César de la Vega on 9/1/21.

@testable import RevenueCat

// swiftlint:disable identifier_name line_length
class MockTrialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityChecker {

    convenience init() {
        let platformInfo = Purchases.PlatformInfo(flavor: "xyz", version: "123")
        let systemInfo = MockSystemInfo(platformInfo: platformInfo, finishTransactions: true)
        let productsManager = MockProductsManager(diagnosticsTracker: nil,
                                                  systemInfo: systemInfo,
                                                  requestTimeout: Configuration.storeKitRequestTimeoutDefault)
        self.init(systemInfo: systemInfo,
                  receiptFetcher: MockReceiptFetcher(requestFetcher: MockRequestFetcher(), systemInfo: systemInfo),
                  introEligibilityCalculator: MockIntroEligibilityCalculator(productsManager: productsManager,
                                                                             receiptParser: MockReceiptParser()),
                  backend: MockBackend(),
                  currentUserProvider: MockCurrentUserProvider(mockAppUserID: "app_user"),
                  operationDispatcher: MockOperationDispatcher(),
                  productsManager: MockProductsManager(diagnosticsTracker: nil,
                                                       systemInfo: systemInfo,
                                                       requestTimeout: Configuration.storeKitRequestTimeoutDefault),
                  diagnosticsTracker: nil)
    }

    var invokedCheckTrialOrIntroPriceEligibilityFromOptimalStore = false
    var invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount = 0
    var invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParameters: Set<String>?
    var invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParametersList: [Set<String>] = []
    var stubbedCheckTrialOrIntroPriceEligibilityFromOptimalStoreReceiveEligibilityResult: [String: IntroEligibility] = [:]
    private let checkEligibilityLock = Lock()

    override func checkEligibility(productIdentifiers: Set<String>,
                                   completion: @escaping ReceiveIntroEligibilityBlock) {
        let result = self.checkEligibilityLock.perform {
            invokedCheckTrialOrIntroPriceEligibilityFromOptimalStore = true
            invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount += 1
            invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParameters = productIdentifiers
            invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParametersList.append(Set(productIdentifiers))
            return stubbedCheckTrialOrIntroPriceEligibilityFromOptimalStoreReceiveEligibilityResult
        }
        completion(result)
    }

    var invokedSk1checkTrialOrIntroPriceEligibility = false
    var invokedSk1checkTrialOrIntroPriceEligibilityCount = 0
    var invokedSk1checkTrialOrIntroPriceEligibilityParameters: (productIdentifiers: Set<String>, Void)?
    var invokedSk1checkTrialOrIntroPriceEligibilityParametersList = [(productIdentifiers: Set<String>, Void)]()
    var stubbedSk1checkTrialOrIntroPriceEligibilityResult: ([String: IntroEligibility], Error?) = ([:], nil)

    override func sk1CheckEligibility(_ productIdentifiers: Set<String>,
                                      completion: @escaping ([String: IntroEligibility], Error?) -> Void) {
        invokedSk1checkTrialOrIntroPriceEligibility = true
        invokedSk1checkTrialOrIntroPriceEligibilityCount += 1
        invokedSk1checkTrialOrIntroPriceEligibilityParameters = (productIdentifiers, ())
        invokedSk1checkTrialOrIntroPriceEligibilityParametersList.append((productIdentifiers, ()))
        let stubbedResult = stubbedSk1checkTrialOrIntroPriceEligibilityResult
        completion(stubbedResult.0, stubbedResult.1)
    }

    var invokedSk2checkTrialOrIntroPriceEligibility = false
    var invokedSk2checkTrialOrIntroPriceEligibilityCount = 0
    var invokedSk2checkTrialOrIntroPriceEligibilityParameters: (productIdentifiers: Set<String>, Void)?
    var invokedSk2checkTrialOrIntroPriceEligibilityParametersList = [(productIdentifiers: Set<String>, Void)]()
    var stubbedSk2checkTrialOrIntroPriceEligibilityReceiveEligibilityResult: [String: IntroEligibility] = [:]

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    override func sk2CheckEligibility(_ productIdentifiers: Set<String>) async -> [String: IntroEligibility] {
        invokedSk2checkTrialOrIntroPriceEligibility = true
        invokedSk2checkTrialOrIntroPriceEligibilityCount += 1
        invokedSk2checkTrialOrIntroPriceEligibilityParameters = (productIdentifiers, ())
        invokedSk2checkTrialOrIntroPriceEligibilityParametersList.append((productIdentifiers, ()))

        return stubbedSk2checkTrialOrIntroPriceEligibilityReceiveEligibilityResult
    }

}

extension MockTrialOrIntroPriceEligibilityChecker: @unchecked Sendable {}

final class DelayedIntroEligibilityChecker: TrialOrIntroPriceEligibilityCheckerType,
                                           @unchecked Sendable {

    private struct State {
        var invocations: [Set<String>] = []
        var completions: [Set<String>: [ReceiveIntroEligibilityBlock]] = [:]
        var completesImmediately = false
    }

    private let state = Atomic(State())

    var invocations: [Set<String>] {
        return self.state.value.invocations
    }

    func checkEligibility(
        productIdentifiers: Set<String>,
        completion: @escaping ReceiveIntroEligibilityBlock
    ) {
        let completesImmediately = self.state.modify {
            $0.invocations.append(productIdentifiers)
            if !$0.completesImmediately {
                $0.completions[productIdentifiers, default: []].append(completion)
            }
            return $0.completesImmediately
        }
        if completesImmediately { completion([:]) }
    }

    func complete(
        productIdentifiers: Set<String>,
        with result: [String: IntroEligibility]
    ) {
        let completion: ReceiveIntroEligibilityBlock? = self.state.modify { state in
            guard var completions = state.completions[productIdentifiers], !completions.isEmpty else {
                return nil
            }

            let completion = completions.removeFirst()
            state.completions[productIdentifiers] = completions.isEmpty ? nil : completions
            return completion
        }
        completion?(result)
    }

    /// Releases outstanding checks and any subsequent checks, including when a test fails before releasing its gates.
    func completeAll() {
        let completions = self.state.modify {
            $0.completesImmediately = true
            let completions = $0.completions.values.flatMap { $0 }
            $0.completions.removeAll()
            return completions
        }
        completions.forEach { $0([:]) }
    }

}
