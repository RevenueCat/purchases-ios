//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HTTPRequestBody.swift
//
//  Created by Nacho Soto on 7/5/23.

import Foundation

/// The content of an `HTTPRequest` for `HTTPRequest.Method.post`
protocol HTTPRequestBody: Encodable {

    /// The keys and values that will be included in the signature.
    /// - Note: this is not `[String: String]` because we need to preserve ordering.
    var contentForSignature: [(key: String, value: String?)] { get }

}

extension HTTPRequestBody {

    // Default implementation for endpoints which don't support signing.
    var contentForSignature: [(key: String, value: String?)] {
        return []
    }

}
