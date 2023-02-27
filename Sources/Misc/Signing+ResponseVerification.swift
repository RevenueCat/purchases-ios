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
                statusCode: statusCode,
                headers: headers,
                request: request,
                publicKey: publicKey,
                signing: signing
            )
        )
    }

    // swiftlint:disable:next function_parameter_count
    private static func verificationResult(
        body: Data,
        statusCode: HTTPStatusCode,
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

        guard let signature = HTTPResponse.value(
            forCaseInsensitiveHeaderField: HTTPClient.ResponseHeader.signature.rawValue,
            in: headers
        ) else {
            Logger.warn(Strings.signing.signature_was_requested_but_not_provided(request))

            return .failed
        }

        guard let requestTimeString = HTTPResponse.value(
            forCaseInsensitiveHeaderField: HTTPClient.ResponseHeader.requestTime.rawValue,
            in: headers
        ), let requestTime = Int(requestTimeString) else {
            Logger.warn(Strings.signing.request_time_missing_from_headers(request))

            return .failed
        }

        let eTag = HTTPResponse.value(forCaseInsensitiveHeaderField: HTTPClient.ResponseHeader.eTag.rawValue,
                                      in: headers)

        let messageToSign = statusCode == .notModified
            ? eTag?.asData ?? .init()
            : body

        if signing.verify(signature: signature,
                          with: .init(
                            message: messageToSign,
                            nonce: nonce,
                            requestTime: requestTime
                          ),
                          publicKey: publicKey) {
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
            let response = HTTPResponse.create(
                with: response,
                body: body ?? .init(),
                request: request,
                publicKey: verificationMode.publicKey,
                signing: signing
            )

            if response.verificationResult == .failed, case .enforced = verificationMode {
                return .failure(.signatureVerificationFailed(path: request.path))
            } else {
                return .success(response.mapBody(Optional.some))
            }
        }
    }

}
