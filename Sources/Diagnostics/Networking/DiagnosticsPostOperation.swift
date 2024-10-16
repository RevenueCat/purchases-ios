//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiagnosticsPostOperation.swift
//
//  Created by Cesar de la Vega on 8/4/24.

import Foundation

final class DiagnosticsPostOperation: NetworkOperation {

    private let configuration: Configuration
    private let request: DiagnosticsEventsRequest
    private let responseHandler: CustomerAPI.SimpleResponseHandler?

    init(
        configuration: Configuration,
        request: DiagnosticsEventsRequest,
        responseHandler: CustomerAPI.SimpleResponseHandler?
    ) {
        self.configuration = configuration
        self.request = request
        self.responseHandler = responseHandler

        super.init(configuration: configuration)
    }

    override func begin(completion: @escaping () -> Void) {
        let request = HTTPRequest(method: .post(self.request), path: .postDiagnostics)

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<HTTPEmptyResponseBody>.Result) in
            defer {
                completion()
            }

            self.responseHandler?(response.error.map(BackendError.networkError))
        }
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension DiagnosticsPostOperation: @unchecked Sendable {}
