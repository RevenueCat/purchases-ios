//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostAttributionDataOperation.swift
//
//  Created by Joshua Liebowitz on 11/19/21.

import Foundation

class PostAttributionDataOperation: NetworkOperation {

    private let configuration: UserSpecificConfiguration
    private let postAttributionDataResponseHandler: NoContentResponseHandler
    private let attributionData: [String: Any]
    private let network: AttributionNetwork
    private let maybeCompletion: SimpleResponseHandler?

    init(configuration: UserSpecificConfiguration,
         attributionData: [String: Any],
         network: AttributionNetwork,
         maybeCompletion: SimpleResponseHandler?,
         postAttributionDataResponseHandler: NoContentResponseHandler = NoContentResponseHandler()) {
        self.postAttributionDataResponseHandler = postAttributionDataResponseHandler
        self.attributionData = attributionData
        self.network = network
        self.configuration = configuration
        self.maybeCompletion = maybeCompletion

        super.init(configuration: configuration)
    }

    override func begin() {
        self.post()
    }

    private func post() {
        guard let appUserID = try? self.configuration.appUserID.escapedOrError() else {
            self.maybeCompletion?(ErrorUtils.missingAppUserIDError())
            return
        }

        let path = "/subscribers/\(appUserID)/attribution"
        let body: [String: Any] = ["network": self.network.rawValue, "data": self.attributionData]
        self.httpClient.performPOSTRequest(serially: true,
                                           path: path,
                                           requestBody: body,
                                           headers: self.authHeaders) { statusCode, response, error in
            guard let completion = self.maybeCompletion else {
                return
            }

            self.postAttributionDataResponseHandler.handle(maybeResponse: response,
                                                           statusCode: statusCode,
                                                           maybeError: error,
                                                           completion: completion)
        }
    }

}
