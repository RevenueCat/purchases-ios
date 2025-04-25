//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SDKHealthError+CustomNSError.swift
//
//  Created by Pol Piella Abadia on 25/04/2025.

import Foundation

extension PurchasesDiagnostics.SDKHealthError: CustomNSError {

    // swiftlint:disable:next missing_docs
    public var errorUserInfo: [String: Any] {
        return [
            NSUnderlyingErrorKey: self.underlyingError as NSError? ?? NSNull(),
            NSLocalizedDescriptionKey: self.localizedDescription
        ]
    }

    var localizedDescription: String {
        switch self {
        case .notAuthorizedToMakePayments: return "The person is not authorized to make payments on this device"
        case let .unknown(error): return "Unknown error: \(error.localizedDescription)"
        case .invalidAPIKey: return "API key is not valid"
        case .noOfferings: return "No offerings configured"
        case let .offeringConfiguration(payload):
            guard let offendingOffering = payload.first(where: { $0.status == .failed }) else {
                return "Default offering is not configured correctly"
            }

            let offeringIdentifier = offendingOffering.identifier
            let offendingPackageCount = offendingOffering.packages.filter({ $0.status != .valid }).count
            let noPackages = "Offering '\(offeringIdentifier)' has no packages"
            let packagesNotReady = """
            Offering '\(offeringIdentifier)' uses \(offendingPackageCount) products \
            that are not ready in App Store Connect
            """

            return offendingOffering.packages.isEmpty ? noPackages : packagesNotReady
        case let .invalidBundleId(payload):
            guard let payload else {
                return "Bundle ID in your app does not match the Bundle ID in the RevenueCat Website"
            }
            let sdkBundleId = payload.sdkBundleId
            let appBundleId = payload.appBundleId
            return "Bundle ID in your app '\(sdkBundleId)' does not match the RevenueCat app Bundle ID '\(appBundleId)'"
        case let .invalidProducts(products):
            if products.isEmpty {
                return "Your app has no products"
            }

            return "You must have at least one product approved in App Store Connect"
        }
    }

    private var underlyingError: Swift.Error? {
        switch self {
        case let .unknown(error): return error
        case .invalidAPIKey,
                .offeringConfiguration,
                .noOfferings,
                .invalidBundleId,
                .invalidProducts,
                .notAuthorizedToMakePayments:
            return nil
        }
    }

}
