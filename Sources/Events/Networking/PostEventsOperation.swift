//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostEventsOperation.swift
//
//  Created by RevenueCat on 1/20/25.

import Foundation

/// A `NetworkOperation` for posting events to various endpoints.
///
/// This generic operation can post events to different endpoints by accepting
/// a path parameter, eliminating code duplication between specific event types.
final class PostEventsOperation: NetworkOperation {

    private let configuration: Configuration
    private let request: EventsRequest
    private let path: HTTPRequestPath
    private let responseHandler: CustomerAPI.SimpleResponseHandler?

    init(
        configuration: Configuration,
        request: EventsRequest,
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
extension PostEventsOperation: @unchecked Sendable {}
