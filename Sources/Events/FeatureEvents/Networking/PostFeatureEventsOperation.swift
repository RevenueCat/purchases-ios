//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostFeatureEventsOperation.swift
//
//  Created by RevenueCat on 1/20/25.

import Foundation

/// A `NetworkOperation` for posting feature events to the feature events endpoint.
final class PostFeatureEventsOperation: NetworkOperation {

    private let configuration: Configuration
    private let request: FeatureEventsRequest
    private let path: HTTPRequestPath
    private let responseHandler: CustomerAPI.SimpleResponseHandler?

    init(
        configuration: Configuration,
        request: FeatureEventsRequest,
        path: HTTPRequestPath,
        responseHandler: CustomerAPI.SimpleResponseHandler?
    ) {
        self.request = request
        self.configuration = configuration
        self.path = path
        self.responseHandler = responseHandler

        super.init(configuration: configuration)
    }

    override func begin(completion: @escaping () -> Void) {
        let httpRequest = HTTPRequest(method: .post(self.request), requestPath: self.path)

        self.httpClient.perform(httpRequest) { (response: VerifiedHTTPResponse<HTTPEmptyResponseBody>.Result) in
            defer {
                completion()
            }

            self.responseHandler?(response.error.map(BackendError.networkError))
        }
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension PostFeatureEventsOperation: @unchecked Sendable {}
