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
    private let completion: IntroEligibilityResponseHandler

    init(configuration: UserSpecificConfiguration,
         receiptData: Data,
         productIdentifiers: [String],
         completion: @escaping IntroEligibilityResponseHandler) {
        self.configuration = configuration
        self.receiptData = receiptData
        self.productIdentifiers = productIdentifiers
        self.completion = completion

        super.init(configuration: configuration)
    }

    override func main() {
        if self.isCancelled {
            return
        }

        self.getIntroEligibility()
    }

    private func getIntroEligibility() {
        guard self.productIdentifiers.count > 0 else {
            self.completion([:], nil)
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

            completion(eligibilities, nil)
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
            self.completion(unknownEligibilityClosure(), ErrorUtils.missingAppUserIDError())
            return
        }

        let fetchToken = self.receiptData.asFetchToken
        let path = "/subscribers/\(appUserID)/intro_eligibility"
        let body: [String: Any] = ["product_identifiers": self.productIdentifiers,
                                   "fetch_token": fetchToken]

        httpClient.performPOSTRequest(serially: true,
                                      path: path,
                                      requestBody: body,
                                      headers: authHeaders) { statusCode, maybeResponse, error in
            let eligibilityResponse = IntroEligibilityResponse(maybeResponse: maybeResponse,
                                                               statusCode: statusCode,
                                                               error: error,
                                                               productIdentifiers: self.productIdentifiers,
                                                               unknownEligibilityClosure: unknownEligibilityClosure,
                                                               completion: self.completion)
            self.handleIntroEligibility(response: eligibilityResponse)
        }
    }

}

private extension GetIntroEligibilityOperation {

    func handleIntroEligibility(response: IntroEligibilityResponse) {
        var eligibilitiesByProductIdentifier = response.maybeResponse
        if response.statusCode >= HTTPStatusCodes.redirect.rawValue || response.error != nil {
            eligibilitiesByProductIdentifier = [:]
        }

        guard let eligibilitiesByProductIdentifier = eligibilitiesByProductIdentifier else {
            response.completion(response.unknownEligibilityClosure(), nil)
            return
        }

        var eligibilities: [String: IntroEligibility] = [:]
        for productID in response.productIdentifiers {
            let status: IntroEligibilityStatus

            if let eligibility = eligibilitiesByProductIdentifier[productID] as? Bool {
                status = eligibility ? .eligible : .ineligible
            } else {
                status = .unknown
            }

            eligibilities[productID] = IntroEligibility(eligibilityStatus: status)
        }
        response.completion(eligibilities, nil)
    }

}
