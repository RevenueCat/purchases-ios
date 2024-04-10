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

typealias DiagnosticsEntries = [String]

final class DiagnosticsPostOperation: NetworkOperation {

    private let configuration: BackendConfiguration
    private let entries: DiagnosticsEntries
    private let responseHandler: DiagnosticsAPI.ResponseHandler

    init(
        configuration: BackendConfiguration,
        entries: DiagnosticsEntries,
        responseHandler: @escaping DiagnosticsAPI.ResponseHandler
    ) {
        self.configuration = configuration
        self.entries = entries
        self.responseHandler = responseHandler

        super.init(configuration: configuration)
    }

    override func begin(completion: @escaping () -> Void) {
        self.postDiagnostics(completion: completion)
    }

    private func postDiagnostics(completion: @escaping () -> Void) {
        let request = HTTPRequest(method: .post(Body(entries: self.entries)),
                                  path: .postDiagnostics)

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<HTTPEmptyResponseBody>.Result) in
            defer {
                completion()
            }
            self.responseHandler(
                response
                    .map { _ in () }
                    .mapError(BackendError.networkError)
            )
        }
    }

}

extension DiagnosticsPostOperation {

    struct Body: Encodable, HTTPRequestBody {

        let data: AnyEncodable

        init(entries: DiagnosticsEntries) {
            self.data = AnyEncodable(entries)
        }

    }

}
