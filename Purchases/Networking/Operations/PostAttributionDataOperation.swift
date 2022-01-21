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
    private let postAttributionDataResponseHandler: PostAttributionDataResponseHandler
    private let attributionData: [String: Any]
    private let network: AttributionNetwork
    private let maybeCompletion: PostRequestResponseHandler?

    init(configuration: UserSpecificConfiguration,
         attributionData: [String: Any],
         network: AttributionNetwork,
         maybeCompletion: PostRequestResponseHandler?,
         // swiftlint:disable:next line_length
         postAttributionDataResponseHandler: PostAttributionDataResponseHandler = PostAttributionDataResponseHandler()) {
        self.postAttributionDataResponseHandler = postAttributionDataResponseHandler
        self.attributionData = attributionData
        self.network = network
        self.configuration = configuration
        self.maybeCompletion = maybeCompletion

        super.init(configuration: configuration)
    }

    override func main() {
        if self.isCancelled {
            return
        }

        self.post(attributionData: self.attributionData,
                  network: self.network,
                  appUserID: self.configuration.appUserID,
                  maybeCompletion: self.maybeCompletion)
    }

    func post(attributionData: [String: Any],
              network: AttributionNetwork,
              appUserID: String,
              maybeCompletion: PostRequestResponseHandler?) {
        guard let appUserID = try? appUserID.escapedOrError() else {
            maybeCompletion?(ErrorUtils.missingAppUserIDError())
            return
        }

        let path = "/subscribers/\(appUserID)/attribution"
        let body: [String: Any] = ["network": network.rawValue, "data": attributionData]
        self.httpClient.performPOSTRequest(serially: true,
                                           path: path,
                                           requestBody: body,
                                           headers: self.authHeaders) { statusCode, response, error in
            guard let completion = maybeCompletion else {
                return
            }

            self.postAttributionDataResponseHandler.handle(maybeResponse: response,
                                                           statusCode: statusCode,
                                                           maybeError: error,
                                                           completion: completion)
        }
    }

}
