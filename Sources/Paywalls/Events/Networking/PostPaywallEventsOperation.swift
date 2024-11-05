//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostPaywallEventsOperation.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation

/// A `NetworkOperation` for posting ``PaywallEvent``s.
final class PostPaywallEventsOperation: NetworkOperation {

    private let configuration: Configuration
    private let request: EventsRequest
    private let responseHandler: CustomerAPI.SimpleResponseHandler?

    init(
        configuration: Configuration,
        request: EventsRequest,
        responseHandler: CustomerAPI.SimpleResponseHandler?
    ) {
        self.request = request
        self.configuration = configuration
        self.responseHandler = responseHandler

        super.init(configuration: configuration)
    }

    override func begin(completion: @escaping () -> Void) {
        let request = HTTPRequest(method: .post(self.request), path: .postEvents)

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<HTTPEmptyResponseBody>.Result) in
            defer {
                completion()
            }

            self.responseHandler?(response.error.map(BackendError.networkError))
        }
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension PostPaywallEventsOperation: @unchecked Sendable {}
