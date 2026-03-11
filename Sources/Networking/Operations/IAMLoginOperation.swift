//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IAMLoginOperation.swift
//
//  Created by RevenueCat.

import Foundation

/// Network operation that calls the IAM `/auth/login` endpoint.
final class IAMLoginOperation: NetworkOperation {

    typealias Completion = (Result<IAMSession, BackendError>) -> Void

    private let loginMethod: IAMLoginMethod
    private let completion: Completion

    init(
        configuration: NetworkConfiguration,
        loginMethod: IAMLoginMethod,
        completion: @escaping Completion
    ) {
        self.loginMethod = loginMethod
        self.completion = completion

        super.init(configuration: configuration)
    }

    override func begin(completion: @escaping () -> Void) {
        self.performLogin(completion: completion)
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension IAMLoginOperation: @unchecked Sendable {}

private extension IAMLoginOperation {

    func performLogin(completion: @escaping () -> Void) {
        let body = Body(loginMethod: self.loginMethod)
        let request = HTTPRequest(method: .post(body), requestPath: HTTPRequest.IAMAuthPath.login)

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<IAMAuthResponse>.Result) in
            switch response {
            case let .success(verifiedResponse):
                let authResponse = verifiedResponse.body
                let session = IAMSession(
                    accessToken: authResponse.accessToken,
                    refreshToken: authResponse.refreshToken,
                    idToken: authResponse.idToken
                )
                self.completion(.success(session))

            case let .failure(error):
                self.completion(.failure(.networkError(error)))
            }
            completion()
        }
    }

}

// MARK: - Request body

extension IAMLoginOperation {

    /// Encodable body for the `/auth/login` request.
    /// Encodes different payloads depending on the login method.
    struct Body: Encodable, HTTPRequestBody {

        let loginMethod: IAMLoginMethod

        var contentForSignature: [(key: String, value: String?)] { [] }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch loginMethod.methodType {
            case let .anonymous(reference):
                try container.encode("anonymous", forKey: .method)
                try container.encodeIfPresent(reference, forKey: .reference)

            case let .oidc(idToken):
                try container.encode("oidc", forKey: .method)
                try container.encode(idToken, forKey: .idToken)

            case let .google(idToken):
                try container.encode("google", forKey: .method)
                try container.encode(idToken, forKey: .idToken)

            case let .apple(idToken):
                try container.encode("apple", forKey: .method)
                var appleContainer = container.nestedContainer(
                    keyedBy: AppleCodingKeys.self,
                    forKey: .apple
                )
                try appleContainer.encode(idToken, forKey: .idToken)
            }
        }

        private enum CodingKeys: String, CodingKey {
            case method
            case reference
            case idToken = "id_token"
            case apple
        }

        private enum AppleCodingKeys: String, CodingKey {
            case idToken = "id_token"
        }

    }

}
