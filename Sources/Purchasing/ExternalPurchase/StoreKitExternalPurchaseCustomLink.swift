//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKitExternalPurchaseCustomLink.swift
//
//  Created by Antonio Pallares on 3/9/26.

import Foundation
import StoreKit

/// ``ExternalPurchaseCustomLinkType`` backed by StoreKit's `ExternalPurchaseCustomLink`.
///
/// `ExternalPurchaseCustomLink` was introduced in the iOS 18.1 SDK, which ships with Xcode 16.1 / Swift 6.0.2, so
/// every use of it is gated on the compiler version as well as the OS version. Older toolchains build this type as
/// permanently unavailable.
internal struct StoreKitExternalPurchaseCustomLink: ExternalPurchaseCustomLinkType {

    var isAPIAvailable: Bool {
        #if compiler(>=6.0.2)
        guard #available(iOS 18.1, macOS 15.1, tvOS 18.1, watchOS 11.1, visionOS 2.1, *) else {
            return false
        }

        return true
        #else
        return false
        #endif
    }

    func isEligible() async -> Bool {
        #if compiler(>=6.0.2)
        guard #available(iOS 18.1, macOS 15.1, tvOS 18.1, watchOS 11.1, visionOS 2.1, *) else {
            return false
        }

        return await ExternalPurchaseCustomLink.isEligible
        #else
        return false
        #endif
    }

    func token(for tokenType: ExternalPurchaseTokenType) async throws -> String? {
        #if compiler(>=6.0.2)
        guard #available(iOS 18.1, macOS 15.1, tvOS 18.1, watchOS 11.1, visionOS 2.1, *) else {
            throw ExternalPurchaseError.apiUnavailable
        }

        return try await ExternalPurchaseCustomLink.token(for: tokenType.rawValue)?.value
        #else
        throw ExternalPurchaseError.apiUnavailable
        #endif
    }

    func showNotice(type: ExternalPurchaseNoticeType) async throws -> ExternalPurchaseNoticeResult {
        #if compiler(>=6.0.2)
        guard #available(iOS 18.1, macOS 15.1, tvOS 18.1, watchOS 11.1, visionOS 2.1, *) else {
            throw ExternalPurchaseError.apiUnavailable
        }

        let result = try await ExternalPurchaseCustomLink.showNotice(type: type.storeKitNoticeType)
        return ExternalPurchaseNoticeResult(result)
        #else
        throw ExternalPurchaseError.apiUnavailable
        #endif
    }

}

#if compiler(>=6.0.2)

@available(iOS 18.1, macOS 15.1, tvOS 18.1, watchOS 11.1, visionOS 2.1, *)
internal extension ExternalPurchaseNoticeType {

    var storeKitNoticeType: StoreKit.ExternalPurchaseCustomLink.NoticeType {
        switch self {
        case .browser: return .browser
        case .withinApp: return .withinApp
        }
    }

}

@available(iOS 18.1, macOS 15.1, tvOS 18.1, watchOS 11.1, visionOS 2.1, *)
internal extension ExternalPurchaseNoticeResult {

    init(_ result: StoreKit.ExternalPurchaseCustomLink.NoticeResult) {
        switch result {
        case .continued: self = .continued
        case .cancelled: self = .cancelled
        // A result this version of the SDK does not recognise must not route the customer to a purchase.
        @unknown default: self = .cancelled
        }
    }

}

#endif
