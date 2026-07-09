//
//  RemoteConfigSignatureContextProvider.swift
//  RevenueCat
//
//  Created by RevenueCat.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

/// Provides the signature inputs for remote config responses.
///
/// RC Container responses sign the config element's decoded payload bytes. JSON responses sign
/// the raw response body. A `204 No Content` response verifies the request context with an empty payload.
struct RemoteConfigSignatureContextProvider: ResponseSignatureContextProvider {

    private let responseFormat: RemoteConfigResponseFormat

    init(responseFormat: RemoteConfigResponseFormat = .rcContainer) {
        self.responseFormat = responseFormat
    }

    func responsePayloadForSignature(from body: Data?, statusCode: HTTPStatusCode) throws -> Data? {
        guard statusCode != .noContent else {
            return Data()
        }

        switch self.responseFormat {
        case .rcContainer:
            return try Self.configPayload(from: body)
        case .json:
            return try Self.jsonPayload(from: body)
        }
    }

    func requestBodyForSignature(for request: HTTPRequest) -> HTTPRequestBody? {
        return nil
    }

}

private extension RemoteConfigSignatureContextProvider {

    /// Extracts the signed payload from a remote config RC Container response.
    ///
    /// Remote config defines the first RC Container element as the config element. The backend signs
    /// that element's payload bytes, not the full container body or stored checksum. This intentionally
    /// parses only the first element so verification can fail before the full response is decoded later.
    static func configPayload(from data: Data?) throws -> Data {
        guard let data = data else {
            throw RCContainer.Parser.FormatError.missingBody
        }

        let configElement = try RemoteConfigContainer.configElement(from: data)

        return try configElement.withDecodedPayloadBytes { bytes in
            Data(bytes)
        }
    }

    static func jsonPayload(from data: Data?) throws -> Data {
        guard let data = data else {
            throw RCContainer.Parser.FormatError.missingBody
        }

        return data
    }

}
