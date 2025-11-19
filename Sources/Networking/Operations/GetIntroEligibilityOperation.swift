//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GetIntroEligibilityOperation.swift
//
//  Created by Joshua Liebowitz on 11/19/21.

import Foundation

class GetIntroEligibilityOperation: NetworkOperation {

    private let configuration: UserSpecificConfiguration
    private let receiptData: Data
    private let productIdentifiers: Set<String>
    private let responseHandler: OfferingsAPI.IntroEligibilityResponseHandler

    init(configuration: UserSpecificConfiguration,
         receiptData: Data,
         productIdentifiers: Set<String>,
         responseHandler: @escaping OfferingsAPI.IntroEligibilityResponseHandler) {
        self.configuration = configuration
        self.receiptData = receiptData
        self.productIdentifiers = productIdentifiers
        self.responseHandler = responseHandler

        super.init(configuration: configuration)
    }

    override func begin(completion: @escaping () -> Void) {
        self.getIntroEligibility(completion: completion)
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension GetIntroEligibilityOperation: @unchecked Sendable {}

private extension GetIntroEligibilityOperation {

    func getIntroEligibility(completion: @escaping () -> Void) {
        guard self.productIdentifiers.count > 0 else {
            self.responseHandler([:], nil)
            completion()

            return
        }

        // Requested products with unknown eligibilities
        let unknownEligibilities: [String: IntroEligibility] = self.productIdentifiers
            .dictionaryWithValues { _ in IntroEligibility(eligibilityStatus: .unknown) }

        guard !self.receiptData.isEmpty else {
            if self.httpClient.systemInfo.isSandbox {
                Logger.appleWarning(Strings.receipt.no_sandbox_receipt_intro_eligibility)
            }

            self.responseHandler(unknownEligibilities, nil)
            completion()

            return
        }

        let appUserID = self.configuration.appUserID

        guard appUserID.isNotEmpty else {
            self.responseHandler(unknownEligibilities, .missingAppUserID())
            completion()

            return
        }

        let request = HTTPRequest(method: .post(Body(productIdentifiers: self.productIdentifiers,
                                                     fetchToken: self.receiptData.asFetchToken)),
                                  path: .getIntroEligibility(appUserID: appUserID))

        httpClient.perform(
            request
        ) { (response: VerifiedHTTPResponse<GetIntroEligibilityResponse>.Result) in
            self.handleIntroEligibility(result: response,
                                        productIdentifiers: self.productIdentifiers,
                                        completion: self.responseHandler)
            completion()
        }
    }

    func handleIntroEligibility(
        result: VerifiedHTTPResponse<GetIntroEligibilityResponse>.Result,
        productIdentifiers: Set<String>,
        completion: OfferingsAPI.IntroEligibilityResponseHandler
    ) {
        let eligibilities = result.value?.body.eligibilityByProductIdentifier

        let result: [String: IntroEligibility] = productIdentifiers
            .dictionaryWithValues { productID in eligibilities?[productID] ?? .unknown }
            .mapValues(IntroEligibility.init)

        completion(result, nil)
    }

}

private extension GetIntroEligibilityOperation {

    struct Body: HTTPRequestBody {

        let productIdentifiers: [String]
        let fetchToken: String

        init(productIdentifiers: Set<String>, fetchToken: String) {
            let identifiers: [String]

            #if DEBUG
            identifiers = ProcessInfo.isRunningUnitTests
                // Sort for snapshot tests
                ? Array(productIdentifiers.sorted())
                : Array(productIdentifiers)
            #else
            identifiers = Array(productIdentifiers)
            #endif

            self.productIdentifiers = identifiers
            self.fetchToken = fetchToken
        }

    }

}
