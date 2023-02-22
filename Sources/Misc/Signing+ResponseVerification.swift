//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Signing+ResponseVerification.swift
//
//  Created by Nacho Soto on 2/8/23.

import Foundation

extension HTTPResponse where Body == Data {

    static func create(with response: HTTPURLResponse,
                       body: Data,
                       request: HTTPRequest,
                       publicKey: Signing.PublicKey?,
                       signing: SigningType.Type = Signing.self) -> Self {
        return Self.create(with: body,
                           statusCode: .init(rawValue: response.statusCode),
                           headers: response.allHeaderFields,
                           request: request,
                           publicKey: publicKey,
                           signing: signing)
    }

    static func create(with body: Data,
                       statusCode: HTTPStatusCode,
                       headers: HTTPClient.ResponseHeaders,
                       request: HTTPRequest,
                       publicKey: Signing.PublicKey?,
                       signing: SigningType.Type = Signing.self) -> Self {
        return .init(
            statusCode: statusCode,
            responseHeaders: headers,
            body: body,
            verificationResult: Self.verificationResult(
                body: body,
                headers: headers,
                request: request,
                publicKey: publicKey,
                signing: signing
            )
        )
    }

    private static func verificationResult(
        body: Data,
        headers: HTTPClient.ResponseHeaders,
        request: HTTPRequest,
        publicKey: Signing.PublicKey?,
        signing: SigningType.Type
    ) -> VerificationResult {
        guard let nonce = request.nonce,
              let publicKey = publicKey,
              #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) else {
            return .notVerified
        }

        guard let signature = HTTPResponse.value(forCaseInsensitiveHeaderField: HTTPClient.responseSignatureHeaderName,
                                                 in: headers) else {
            Logger.warn(Strings.signing.signature_was_requested_but_not_provided(request))

            return .failed
        }

        if signing.verify(message: body,
                          nonce: nonce,
                          hasValidSignature: signature,
                          with: publicKey) {
            return .verified
        } else {
            return .failed
        }
    }

}

extension Result where Success == Data?, Failure == NetworkError {

    /// Converts a `Result<Data?, NetworkError>` into `Result<HTTPResponse<Data?>, NetworkError>`
    func mapToResponse(
        response: HTTPURLResponse,
        request: HTTPRequest,
        signing: SigningType.Type,
        verificationMode: Signing.ResponseVerificationMode
    ) -> Result<HTTPResponse<Data?>, Failure> {
        return self.flatMap { body in
            if let body = body {
                let response = HTTPResponse.create(
                    with: response,
                    body: body,
                    request: request,
                    publicKey: verificationMode.publicKey,
                    signing: signing
                )

                if response.verificationResult == .failed, case .enforced = verificationMode {
                    return .failure(.signatureVerificationFailed(path: request.path))
                } else {
                    return .success(response.mapBody(Optional.some))
                }
            } else {
                // No body means that the status code `HTTPStatusCode.notModified`
                // so the response will be fetched from `ETagManager`.
                return .success(
                    .init(
                        statusCode: HTTPStatusCode(rawValue: response.statusCode),
                        responseHeaders: response.allHeaderFields,
                        body: body,
                        verificationResult: .notVerified
                    )
                )
            }
        }
    }

}
