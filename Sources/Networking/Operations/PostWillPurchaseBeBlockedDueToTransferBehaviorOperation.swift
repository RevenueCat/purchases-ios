//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostWillPurchaseBeBlockedDueToTransferBehaviorOperation.swift
//
//  Created by RevenueCat.

import Foundation

// swiftlint:disable:next type_name
final class PostWillPurchaseBeBlockedDueToTransferBehaviorOperation: NetworkOperation {

    typealias ResponseHandler = Backend.ResponseHandler<WillPurchaseBeBlockedByTransferBehaviorResponse>

    private let configuration: UserSpecificConfiguration
    private let postData: PostData
    private let responseHandler: ResponseHandler

    init(
        configuration: UserSpecificConfiguration,
        postData: PostData,
        responseHandler: @escaping ResponseHandler
    ) {
        self.configuration = configuration
        self.postData = postData
        self.responseHandler = responseHandler

        super.init(configuration: configuration)
    }

    override func begin(completion: @escaping () -> Void) {
        self.post(completion: completion)
    }

    private func post(completion: @escaping () -> Void) {

        guard self.postData.appUserID.isNotEmpty else {
            self.responseHandler(.failure(.missingAppUserID()))
            completion()
            return
        }

        guard self.postData.transactionJWS.isNotEmpty else {
            self.responseHandler(.failure(.missingTransactionJWS()))
            completion()
            return
        }

        let request = HTTPRequest(
            method: .post(self.postData),
            path: .willPurchaseBeBlockedDueToTranferBehavior
        )

        // swiftlint:disable:next line_length
        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<WillPurchaseBeBlockedByTransferBehaviorResponse>.Result) in
            let result = response
                .map { $0.body }
                .mapError(BackendError.networkError)

            self.responseHandler(result)
            completion()
        }
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension PostWillPurchaseBeBlockedDueToTransferBehaviorOperation: @unchecked Sendable {}

extension PostWillPurchaseBeBlockedDueToTransferBehaviorOperation {

    struct PostData {
        let appUserID: String
        let transactionJWS: String
    }

}

// MARK: - Codable

extension PostWillPurchaseBeBlockedDueToTransferBehaviorOperation.PostData: Encodable {

    private enum CodingKeys: String, CodingKey {
        case appUserID = "appUserId"
        case transactionJWS = "transactionJWS"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.appUserID, forKey: .appUserID)
        try container.encode(self.transactionJWS, forKey: .transactionJWS)
    }

}

// MARK: - HTTPRequestBody

extension PostWillPurchaseBeBlockedDueToTransferBehaviorOperation.PostData: HTTPRequestBody {

    var contentForSignature: [(key: String, value: String?)] {
        return [
            (CodingKeys.appUserID.stringValue, self.appUserID),
            (CodingKeys.transactionJWS.stringValue, self.transactionJWS)
        ]
    }

}
