//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SpendVirtualCurrenciesOperation.swift
//
//  Created by Dave DeLong on 8/20/26.

import Foundation

final class SpendVirtualCurrenciesOperation: NetworkOperation {

    private let amounts: [String: Int]
    private let reference: String?
    private let handler: VirtualCurrenciesAPI.VirtualCurrenciesResponseHandler
    private let idempotencyKey: String

    init(configuration: NetworkConfiguration,
         amounts: [String: Int],
         reference: String?,
         handler: @escaping VirtualCurrenciesAPI.VirtualCurrenciesResponseHandler) {
        self.amounts = amounts
        self.reference = reference
        self.handler = handler
        self.idempotencyKey = UUID().uuidString

        super.init(configuration: configuration)
    }

    override func begin(completion: @escaping () -> Void) {
        let body = Body(adjustments: amounts, reference: reference)
        let httpRequest = HTTPRequest(method: .post(body),
                                      path: .spendVirtualCurrencies,
                                      additionalHeaders: [
                                        "Idempotency-Key": self.idempotencyKey
                                      ])

        self.httpClient.perform(httpRequest) { (response: VerifiedHTTPResponse<VirtualCurrenciesResponse>.Result) in
            defer {
                completion()
            }

            let result = response.map(\.body).mapError(BackendError.networkError)
            self.handler(result)
        }
    }
}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension SpendVirtualCurrenciesOperation: @unchecked Sendable {}

extension SpendVirtualCurrenciesOperation {

    struct Body: Encodable, HTTPRequestBody {

        let adjustments: [String: Int]
        let reference: String?

    }

}
