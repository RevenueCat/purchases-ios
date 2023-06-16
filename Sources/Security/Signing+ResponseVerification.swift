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
        let requestDate = Self.parseRequestDate(headers: headers)
        let verificationResult = Self.verificationResult(
            body: body,
            statusCode: statusCode,
            headers: headers,
            requestDate: requestDate,
            request: request,
            publicKey: publicKey,
            signing: signing
        )

        #if DEBUG
        if verificationResult == .failed, ProcessInfo.isRunningRevenueCatTests {
            Logger.warn(Strings.signing.invalid_signature_data(request, body, headers, statusCode))
        }
        #endif

        return .init(
            statusCode: statusCode,
            responseHeaders: headers,
            body: body,
            requestDate: requestDate,
            verificationResult: verificationResult
        )
    }

    // swiftlint:disable:next function_parameter_count
    private static func verificationResult(
        body: Data,
        statusCode: HTTPStatusCode,
        headers: HTTPClient.ResponseHeaders,
        requestDate: Date?,
        request: HTTPRequest,
        publicKey: Signing.PublicKey?,
        signing: SigningType.Type
    ) -> VerificationResult {
        guard let nonce = request.nonce,
              let publicKey = publicKey,
              statusCode.isSuccessfulResponse,
              #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) else {
            return .notRequested
        }

        guard let signature = HTTPResponse.value(
            forCaseInsensitiveHeaderField: HTTPClient.ResponseHeader.signature.rawValue,
            in: headers
        ) else {
            Logger.warn(Strings.signing.signature_was_requested_but_not_provided(request))

            return .failed
        }

        guard let requestDate = requestDate else {
            Logger.warn(Strings.signing.request_date_missing_from_headers(request))

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
                            requestDate: requestDate.millisecondsSince1970
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
                return .failure(.signatureVerificationFailed(path: request.path, code: response.statusCode))
            } else {
                return .success(response.mapBody(Optional.some))
            }
        }
    }

}

extension HTTPResponse {

    /// Creates an `HTTPResponse` extracting the `requestDate` from its headers
    init(
        statusCode: HTTPStatusCode,
        responseHeaders: HTTPClient.ResponseHeaders,
        body: Body,
        verificationResult: VerificationResult
    ) {
        self.statusCode = statusCode
        self.responseHeaders = responseHeaders
        self.body = body
        self.requestDate = Self.parseRequestDate(headers: responseHeaders)
        self.verificationResult = verificationResult
    }

    static func parseRequestDate(headers: Self.Headers) -> Date? {
        guard let stringValue = Self.value(
            forCaseInsensitiveHeaderField: HTTPClient.ResponseHeader.requestDate.rawValue,
            in: headers
        ),
              let intValue = UInt64(stringValue) else { return nil }

        return .init(millisecondsSince1970: intValue)
    }

}
