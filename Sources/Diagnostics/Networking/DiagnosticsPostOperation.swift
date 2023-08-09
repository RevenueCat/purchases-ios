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
//  Created by Nacho Soto on 6/16/23.

import Foundation

final class DiagnosticsPostOperation: NetworkOperation {

    private let configuration: BackendConfiguration
    private let responseHandler: DiagnosticsAPI.ResponseHandler

    init(
        configuration: BackendConfiguration,
        responseHandler: @escaping DiagnosticsAPI.ResponseHandler
    ) {
        self.configuration = configuration
        self.responseHandler = responseHandler

        super.init(configuration: configuration)
    }

    override func begin(completion: @escaping () -> Void) {
        self.postDiagnostics(completion: completion)
    }

}

private extension DiagnosticsPostOperation {

    func postDiagnostics(completion: @escaping () -> Void) {
        let body = DiagnosticsPostBody(entries: [])

        let request = HTTPRequest(method: .post(body),
                                  path: .postDiagnostics)

        self.httpClient.perform(request) { (response: HTTPResponse<HTTPEmptyResponseBody>.Result) in
            self.responseHandler(
                response
                    .map { _ in () }
                    .mapError(BackendError.networkError)
            )
            
            completion()
        }
    }

}
