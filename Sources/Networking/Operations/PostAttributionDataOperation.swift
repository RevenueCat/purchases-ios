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
    private let attributionData: [String: Any]
    private let network: AttributionNetwork
    private let responseHandler: CustomerAPI.SimpleResponseHandler?

    init(configuration: UserSpecificConfiguration,
         attributionData: [String: Any],
         network: AttributionNetwork,
         responseHandler: CustomerAPI.SimpleResponseHandler?) {
        self.attributionData = attributionData
        self.network = network
        self.configuration = configuration
        self.responseHandler = responseHandler

        super.init(configuration: configuration)
    }

    override func begin(completion: @escaping () -> Void) {
        self.post(completion: completion)
    }

    private func post(completion: @escaping () -> Void) {
        guard let appUserID = try? self.configuration.appUserID.escapedOrError() else {
            self.responseHandler?(.missingAppUserID())
            completion()

            return
        }

        let request = HTTPRequest(method: .post(Body(network: self.network, attributionData: self.attributionData)),
                                  path: .postAttributionData(appUserID: appUserID))

        self.httpClient.perform(request) { (response: HTTPResponse<HTTPEmptyResponseBody>.Result) in
            defer {
                completion()
            }

            self.responseHandler?(response.error.map(BackendError.networkError))
        }
    }

}

private extension PostAttributionDataOperation {

    struct Body: Encodable {

        let network: AttributionNetwork
        let data: AnyEncodable

        init(network: AttributionNetwork, attributionData: [String: Any]) {
            self.network = network
            self.data = AnyEncodable(attributionData)
        }

    }

}
