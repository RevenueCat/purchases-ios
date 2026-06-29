//
//  RemoteConfigSignatureContextProvider.swift
//  RevenueCat
//
//  Created by RevenueCat.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

/// Provides the signature inputs for remote config RC Container responses.
///
/// The response signature covers the config element's payload bytes exactly as received. A `204 No Content`
/// response verifies the request context with an empty payload.
struct RemoteConfigSignatureContextProvider: ResponseSignatureContextProvider {

    func responsePayloadForSignature(from body: Data?, statusCode: HTTPStatusCode) throws -> Data? {
        guard statusCode != .noContent else {
            return Data()
        }

        return try Self.configPayload(from: body)
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

        return configElement.withPayloadBytes { bytes in
            Data(bytes)
        }
    }

}
