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

#if DEBUG
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
        case .notAuthorizedToMakePayments:
            return """
            This device is not authorized to make purchases. This can happen if Content & Privacy Restrictions are \
            enabled in Screen Time, or if the device has a mobile device management (MDM) profile that prevents \
            purchases. Please check your Screen Time settings or contact your device administrator, or try again \
            from a different device.
            """

        case let .unknown(error):
            return """
            We encountered an unknown error that prevented the operation from completing. This is likely a \
            temporary issue. Please try again in a few moments and, if the problem persists, contact support \
            with this error: \(error.localizedDescription).
            """

        case .invalidAPIKey:
            return """
            Your API key is not valid or has been revoked. This prevents your app from accessing RevenueCat \
            services and among other things, retrieving products. Please verify your API key in the RevenueCat \
            website and update your app's configuration.
            """

        case .noOfferings:
            return """
            Your app doesn't have any offerings configured in RevenueCat. This means users can't see available \
            product options through offerings. If you plan on using offerings to show products to your users, \
            please configure them in the RevenueCat website.
            """

        case let .offeringConfiguration(payload):
            guard let offendingOffering = payload.first(where: { $0.status == .failed }) else {
                let offeringsWithWarnings = payload.filter { $0.status == .warning }
                let offeringDescription = offeringsWithWarnings.isEmpty ?
                    "Some offerings" :
                    "The offerings \(offeringsWithWarnings.map { "'\($0.identifier)'" }.joined(separator: ", "))"
                return """
                \(offeringDescription) have configuration issues that may prevent users from seeing product \
                options or making purchases.
                """
            }

            let offeringIdentifier = offendingOffering.identifier
            let offendingPackageCount = offendingOffering.packages.filter { $0.status != .valid }.count

            if offendingOffering.packages.isEmpty {
                return """
                Offering '\(offeringIdentifier)' has no packages configured, so users won't see any product \
                options. Please add packages to this offering in the RevenueCat website.
                """
            } else {
                return """
                Offering '\(offeringIdentifier)' uses \(offendingPackageCount) products that are not approved \
                in App Store Connect yet. While such products may work while testing, users won't be able to \
                make purchases in production. Please ensure all products are approved and available in App Store \
                Connect.
                """
            }

        case let .invalidBundleId(payload):
            guard let payload else {
                return """
                Your app's Bundle ID doesn't match the one configured in RevenueCat. This will cause the SDK \
                to not show any products and won't allow users to make purchases. Please update your Bundle ID \
                in either your app or the RevenueCat website to match.
                """
            }
            let sdkBundleId = payload.sdkBundleId
            let appBundleId = payload.appBundleId
            return """
            Your app's Bundle ID '\(sdkBundleId)' doesn't match the RevenueCat configuration '\(appBundleId)'. \
            This will cause the SDK to not show any products and won't allow users to make purchases. Please \
            update your Bundle ID in either your app or the RevenueCat website to match.
            """

        case let .invalidProducts(products):
            if products.isEmpty {
                return """
                Your app doesn't have any products set up, so users can't make any purchases. Please create \
                and configure products in the RevenueCat website.
                """
            } else {
                return """
                Your products are configured in RevenueCat but aren't approved in App Store Connect yet. This \
                prevents users from making purchases in production. Please ensure all products are approved and \
                available for sale in App Store Connect.
                """
            }
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
#endif
