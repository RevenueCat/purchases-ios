//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockOfferingsManager.swift
//
//  Created by Juanpe Catalán on 8/8/21.

import Foundation
@testable import RevenueCat

// swiftlint:disable identifier_name

// Note: this class is implicitly `@unchecked Sendable` through its parent
// even though it's not actually thread safe.
class MockOfferingsManager: OfferingsManager {

typealias OfferingsCompletion = @MainActor @Sendable (Result<Offerings, Error>) -> Void

    var invokedOfferings = false
    var invokedOfferingsCount = 0
    var invokedOfferingsParameters: (appUserID: String,
                                     fetchPolicy: FetchPolicy,
                                     completion: OfferingsCompletion?)?
    var invokedOfferingsParametersList = [(appUserID: String,
                                           fetchPolicy: FetchPolicy,
                                           completion: OfferingsCompletion??)]()
    var stubbedOfferingsCompletionResult: Result<Offerings, Error> = .failure(
        .configurationError("Stub not setup", underlyingError: nil)
    )

    override func offerings(appUserID: String,
                            fetchPolicy: FetchPolicy,
                            completion: (@MainActor @Sendable (Result<Offerings, Error>) -> Void)?) {
        self.invokedOfferings = true
        self.invokedOfferingsCount += 1
        self.invokedOfferingsParameters = (appUserID, fetchPolicy, completion)
        self.invokedOfferingsParametersList.append((appUserID, fetchPolicy, completion))

        OperationDispatcher.dispatchOnMainActor { [result = self.stubbedOfferingsCompletionResult] in
            completion?(result)
        }
    }

    struct InvokedUpdateOfferingsCacheParameters {
        let appUserID: String
        let isAppBackgrounded: Bool
        let fetchPolicy: OfferingsManager.FetchPolicy
    }

    var invokedUpdateOfferingsCache = false
    var invokedUpdateOfferingsCacheCount = 0
    var invokedUpdateOfferingsCacheParameters: InvokedUpdateOfferingsCacheParameters?
    var invokedUpdateOfferingsCachesParametersList = [InvokedUpdateOfferingsCacheParameters]()
    var stubbedUpdateOfferingsCompletionResult: Result<Offerings, Error> = .failure(
        .configurationError("Stub not setup", underlyingError: nil)
    )

    override func updateOfferingsCache(
        appUserID: String,
        isAppBackgrounded: Bool,
        fetchPolicy: OfferingsManager.FetchPolicy,
        completion: (@MainActor @Sendable (Result<Offerings, Error>) -> Void)?
    ) {
        self.invokedUpdateOfferingsCache = true
        self.invokedUpdateOfferingsCacheCount += 1

        let parameters = InvokedUpdateOfferingsCacheParameters(
            appUserID: appUserID,
            isAppBackgrounded: isAppBackgrounded,
            fetchPolicy: fetchPolicy
        )

        self.invokedUpdateOfferingsCacheParameters = parameters
        self.invokedUpdateOfferingsCachesParametersList.append(parameters)

        OperationDispatcher.dispatchOnMainActor { [result = self.stubbedUpdateOfferingsCompletionResult] in
            completion?(result)
        }
    }

    var invokedInvalidateAndReFetchCachedOfferingsIfAppropiate = false
    var invokedInvalidateAndReFetchCachedOfferingsIfAppropiateCount = 0
    var invokedInvalidateAndReFetchCachedOfferingsIfAppropiateParameters: String?
    var invokedInvalidateAndReFetchCachedOfferingsIfAppropiateParametersList = [String]()

    override func invalidateAndReFetchCachedOfferingsIfAppropiate(appUserID: String) {
        invokedInvalidateAndReFetchCachedOfferingsIfAppropiate = true
        invokedInvalidateAndReFetchCachedOfferingsIfAppropiateCount += 1
        invokedInvalidateAndReFetchCachedOfferingsIfAppropiateParameters = appUserID
        invokedInvalidateAndReFetchCachedOfferingsIfAppropiateParametersList.append(appUserID)
    }

}
