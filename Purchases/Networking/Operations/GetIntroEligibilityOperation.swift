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
    private let productIdentifiers: [String]
    private let responseHandler: IntroEligibilityResponseHandler

    init(configuration: UserSpecificConfiguration,
         receiptData: Data,
         productIdentifiers: [String],
         responseHandler: @escaping IntroEligibilityResponseHandler) {
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

private extension GetIntroEligibilityOperation {

    func getIntroEligibility(completion: @escaping () -> Void) {
        guard self.productIdentifiers.count > 0 else {
            self.responseHandler([:], nil)
            completion()

            return
        }

        if self.receiptData.count == 0 {
            if self.httpClient.systemInfo.isSandbox {
                Logger.appleWarning(Strings.receipt.no_sandbox_receipt_intro_eligibility)
            }

            var eligibilities: [String: IntroEligibility] = [:]

            for productID in self.productIdentifiers {
                eligibilities[productID] = IntroEligibility(eligibilityStatus: .unknown)
            }

            self.responseHandler(eligibilities, nil)
            completion()

            return
        }

        // Closure we can use for both missing appUserID as well as server error where we have an unknown
        // eligibility status.
        let unknownEligibilityClosure: () -> [String: IntroEligibility] = {
            let unknownEligibilities = [IntroEligibility](repeating: IntroEligibility(eligibilityStatus: .unknown),
                                                          count: self.productIdentifiers.count)
            let productIdentifiersToEligibility = zip(self.productIdentifiers, unknownEligibilities)

            return Dictionary(uniqueKeysWithValues: productIdentifiersToEligibility)
        }

        guard let appUserID = try? self.configuration.appUserID.escapedOrError() else {
            self.responseHandler(unknownEligibilityClosure(), ErrorUtils.missingAppUserIDError())
            completion()

            return
        }

        let fetchToken = self.receiptData.asFetchToken
        let path = "/subscribers/\(appUserID)/intro_eligibility"
        let body: [String: Any] = ["product_identifiers": self.productIdentifiers,
                                   "fetch_token": fetchToken]

        httpClient.performPOSTRequest(serially: true,
                                      path: path,
                                      requestBody: body,
                                      headers: authHeaders) { statusCode, response, error in
            let eligibilityResponse = IntroEligibilityResponse(response: response,
                                                               statusCode: statusCode,
                                                               error: error,
                                                               productIdentifiers: self.productIdentifiers,
                                                               unknownEligibilityClosure: unknownEligibilityClosure,
                                                               completion: self.responseHandler)
            self.handleIntroEligibility(response: eligibilityResponse)
            completion()
        }
    }

    func handleIntroEligibility(response: IntroEligibilityResponse) {
        var eligibilitiesByProductIdentifier = response.response
        if response.statusCode >= HTTPStatusCodes.redirect.rawValue || response.error != nil {
            eligibilitiesByProductIdentifier = [:]
        }

        guard let eligibilitiesByProductIdentifier = eligibilitiesByProductIdentifier else {
            response.completion(response.unknownEligibilityClosure(), nil)
            return
        }

        let eligibilities: [String: IntroEligibility] = Set(response.productIdentifiers)
            .dictionaryWithValues { productID in
                if let eligibility = eligibilitiesByProductIdentifier[productID] as? Bool {
                    return eligibility ? .eligible : .ineligible
                } else {
                    return .unknown
                }
            }
            .mapValues(IntroEligibility.init(eligibilityStatus:))
        response.completion(eligibilities, nil)
    }

}
