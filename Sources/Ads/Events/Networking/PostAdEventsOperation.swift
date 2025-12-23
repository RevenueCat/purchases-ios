//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostAdEventsOperation.swift
//
//  Created by RevenueCat on 1/21/25.

import Foundation

#if ENABLE_AD_EVENTS_TRACKING

/// A `NetworkOperation` for posting ad events to the ad events endpoint.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PostAdEventsOperation: NetworkOperation {

    private let configuration: Configuration
    private let request: AdEventsRequest
    private let path: HTTPRequestPath
    private let responseHandler: CustomerAPI.SimpleResponseHandler?

    init(
        configuration: Configuration,
        request: AdEventsRequest,
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
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PostAdEventsOperation: @unchecked Sendable {}

#endif
