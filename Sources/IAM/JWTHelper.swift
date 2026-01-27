//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  JWTHelper.swift
//
//  Created by RevenueCat on 1/27/26.

import Foundation

/// Lightweight JWT helper for extracting claims from JWT tokens
enum JWTHelper {

    /// Extract the "sub" (subject) claim from a JWT token
    /// - Parameter jwt: The JWT token string
    /// - Returns: The subject claim value (app_user_id), or nil if extraction fails
    static func extractSubject(from jwt: String) -> String? {
        guard let payload = decodePayload(from: jwt) else {
            return nil
        }

        // Extract "sub" claim
        return payload["sub"] as? String
    }

    /// Decode the payload section of a JWT token
    /// - Parameter jwt: The JWT token string (format: header.payload.signature)
    /// - Returns: Dictionary containing the payload claims, or nil if decoding fails
    private static func decodePayload(from jwt: String) -> [String: Any]? {
        let segments = jwt.split(separator: ".")
        guard segments.count == 3 else {
            Logger.error("Invalid JWT format: expected 3 segments, got \(segments.count)")
            return nil
        }

        let payloadSegment = String(segments[1])
        guard let payloadData = base64UrlDecode(payloadSegment) else {
            Logger.error("Failed to base64-decode JWT payload")
            return nil
        }

        do {
            let json = try JSONSerialization.jsonObject(with: payloadData, options: [])
            return json as? [String: Any]
        } catch {
            Logger.error("Failed to parse JWT payload as JSON: \(error)")
            return nil
        }
    }

    /// Decode a base64url-encoded string
    /// JWT uses base64url encoding which differs slightly from standard base64:
    /// - '+' is replaced with '-'
    /// - '/' is replaced with '_'
    /// - Padding '=' characters are optional
    private static func base64UrlDecode(_ base64UrlString: String) -> Data? {
        var base64 = base64UrlString
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding if needed
        let paddingLength = (4 - base64.count % 4) % 4
        base64 += String(repeating: "=", count: paddingLength)

        return Data(base64Encoded: base64)
    }

}
