//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesDiagnostics.swift
//
//  Created by Nacho Soto on 9/21/22.

import Foundation
import StoreKit

/// `PurchasesDiagnostics` allows you to ensure that the SDK is set up correctly by diagnosing configuration errors.
/// To run the test, simply call ``PurchasesDiagnostics/testSDKHealth()``.
///
/// #### Example:
/// ```swift
/// let diagnostics = PurchasesDiagnostics.default
/// do {
///     try await diagnostics.testSDKHealth()
/// } catch {
///     print("Diagnostics failed: \(error.localizedDescription)")
/// }
/// ```
@objc(RCPurchasesDiagnostics)
public final class PurchasesDiagnostics: NSObject, Sendable {

    typealias SDK = PurchasesType & InternalPurchasesType & Sendable

    private let purchases: SDK

    init(purchases: SDK) {
        self.purchases = purchases
    }

    /// Default instance of `PurchasesDiagnostics`.
    /// Note: you must call ``Purchases/configure(with:)-6oipy`` before using this.
    @objc
    public static let `default`: PurchasesDiagnostics = .init(purchases: Purchases.shared)
}

#if DEBUG
extension PurchasesDiagnostics {
    /// Enum representing the status of a product in the store
    public enum ProductStatus: Sendable {
        /// Product is configured correctly in App Store Connect
        case valid
        /// There was a problem checking the product state in App Store Connect
        case couldNotCheck
        /// The product does not exist in App Store Connect
        case notFound
        /// The product is in a state that requires action from Apple or the Developer before being ready for production
        case actionInProgress
        /// The product is in a state that requires action from the developer before being ready for production
        case needsAction
        /// The product state could not be determined
        case unknown
    }

    /// Additional information behind a configuration issue for a Product
    public struct ProductDiagnosticsPayload: Sendable {
        /// Product identifier that must match the product in App Store Connect
        public let identifier: String
        /// Title of the product as it appears on the RevenueCat website
        public let title: String?
        /// Status of the RevenueCat product derived from the App Store Connect product
        public let status: ProductStatus
        /// Explainer of the product status
        public let description: String
    }

    /// Additional information behind a configuration issue for the app's Bundle Id
    public struct InvalidBundleIdErrorPayload: Equatable {
        /// Bundle ID for the RevenueCat app
        public let appBundleId: String
        /// Bundle ID detected from the app at runtime by the RevenueCat SDK
        public let sdkBundleId: String
    }

    /// Health status for a specific validation check in the SDK's Health Report
    public enum SDKHealthCheckStatus: Sendable {
        /// SDK Health Check is valid
        case passed
        /// SDK Health Check is not valid
        case failed
        /// SDK Health Check is valid, but yielded some warnings
        case warning
    }

    /// Additional information behind a configuration issue for a specific offering
    public struct OfferingDiagnosticsPayload: Sendable {
        /// Offering identifier as set up in the RevenueCat website
        public let identifier: String
        /// Extra information for each of the packages in the offering
        public let packages: [OfferingPackageDiagnosticsPayload]
        /// Status of the offering health check
        public let status: SDKHealthCheckStatus
    }

    /// Additional information about a specific package in an offering that has a configuration issue.
    public struct OfferingPackageDiagnosticsPayload: Sendable {
        /// The identifier of the package as configured in the RevenueCat website.
        public let identifier: String
        /// The display name of the package, if available.
        public let title: String?
        /// The current configuration status of the underlying product in App Store Connect.
        public let status: ProductStatus
        /// A human-readable explanation of the product's configuration status.
        public let description: String
        /// The product identifier associated with this package.
        public let productIdentifier: String
        /// The reference name of the product from App Store Connect, if available.
        public let productTitle: String?
    }

    /// An error that represents a problem in the SDK's configuration
    public enum SDKHealthError: Swift.Error {
        /// API key is invalid
        case invalidAPIKey

        /// There are no offerings in project
        case noOfferings

        /// Offerings are not configured correctly
        case offeringConfiguration([OfferingDiagnosticsPayload])

        /// App bundle ID does not match the one set in the dashboard
        case invalidBundleId(InvalidBundleIdErrorPayload?)

        /// One or more products are not configured correctly
        case invalidProducts([ProductDiagnosticsPayload])

        /// The person is not authorized to make In-App Purchases
        case notAuthorizedToMakePayments

        /// Any other not identifier error. You can check the undelying error for details.
        case unknown(Swift.Error)
    }

    /// A report that encapsulates the result of the SDK configuration health check.
    /// Use this to programmatically inspect the SDK's health status after calling `healthReport()`.
    public struct SDKHealthReport: Sendable {
        /// The overall status of the SDK's health.
        public let status: SDKHealthStatus
        /// The RevenueCat project identifier associated with the current SDK configuration, if available.
        public let projectId: String?
        /// The RevenueCat app identifier associated with the current SDK configuration, if available.
        public let appId: String?
        /// The report for each of your app's products set up in the RevenueCat website
        public let products: [ProductDiagnosticsPayload]
        /// The report for each of your app's offerings set up in the RevenueCat website
        public let offerings: [OfferingDiagnosticsPayload]

        init(
            status: SDKHealthStatus,
            projectId: String? = nil,
            appId: String? = nil,
            products: [ProductDiagnosticsPayload] = [],
            offerings: [OfferingDiagnosticsPayload] = []
        ) {
            self.status = status
            self.projectId = projectId
            self.appId = appId
            self.products = products
            self.offerings = offerings
        }
    }

    /// Status of the SDK Health report
    public enum SDKHealthStatus: Sendable {
        /// SDK configuration is valid but might have some non-blocking issues
        case healthy(warnings: [PurchasesDiagnostics.SDKHealthError])
        /// SDK configuration is not valid and has issues that must be resolved
        case unhealthy(PurchasesDiagnostics.SDKHealthError)
    }
}
#endif

extension PurchasesDiagnostics {

    /// An error that represents a failing step in ``PurchasesDiagnostics``
    public enum Error: Swift.Error {

        /// Connection to the API failed
        case failedConnectingToAPI(Swift.Error)

        /// API key is invalid
        case invalidAPIKey

        /// Fetching offerings failed due to the underlying error
        case failedFetchingOfferings(Swift.Error)

        /// Failure performing a signed request
        case failedMakingSignedRequest(Swift.Error)

        /// Any other not identifier error. You can check the undelying error for details.
        case unknown(Swift.Error)

    }

}

extension PurchasesDiagnostics {

    /// Checks if the SDK is configured correctly.
    /// - Important: This method is intended solely for debugging configuration issues with the SDK implementation.
    /// It should not be invoked in production builds.
    /// - Throws: ``PurchasesDiagnostics/Error`` if any step fails
    @available(*, deprecated, message: """
    Use the `PurchasesDiagnostics.shared.checkSDKHealth()` method instead.
    """)
    @objc(testSDKHealthWithCompletion:)
    public func testSDKHealth() async throws {
        do {
            try await self.unauthenticatedRequest()
            #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
            try await self.authenticatedRequest()
            #endif
            try await self.offeringsRequest()
            try await self.signatureVerification()
        } catch let error as Error {
            throw error
        } catch let error {
            // Catch every other error to ensure that we only throw `Error`s from here.
            throw Error.unknown(error)
        }
    }

    #if DEBUG
    /// Performs a full SDK configuration health check and throws an error if the configuration is not valid.
    /// - Important: This method can not be invoked in production builds.
    /// - Throws: ``SDKHealthError`` indicating the specific configuration issue that needs to be solved.
    public func checkSDKHealth() async throws {
        switch await self.healthReport().status {
        case let .unhealthy(error): throw error
        default: break
        }
    }

    /// Performs a full SDK configuration health check and returns its status.
    /// - Important: This method is intended solely for debugging configuration issues with the SDK implementation.
    /// It should not be invoked in production builds.
    /// - Returns: The result of the SDK configuration health check.
    public func healthReport() async -> SDKHealthReport {
        await purchases.healthReport()
    }
    #endif
}

// MARK: - Private

private extension PurchasesDiagnostics {

    /// Makes a request to the backend, to verify connectivity, firewalls, or anything blocking network traffic.
    func unauthenticatedRequest() async throws {
        do {
            try await self.purchases.healthRequest(signatureVerification: false)
        } catch {
            throw Error.failedConnectingToAPI(error)
        }
    }

    #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
    func authenticatedRequest() async throws {
        do {
            _ = try await self.purchases.customerInfo()
        } catch let error as ErrorCode {
            throw self.convert(error)
        } catch {
            throw Error.unknown(error)
        }
    }
    #endif

    func offeringsRequest() async throws {
        do {
            _ = try await self.purchases.offerings(fetchPolicy: .failIfProductsAreMissing)
        } catch {
            throw Error.failedFetchingOfferings(error)
        }
    }

    func signatureVerification() async throws {
        guard self.purchases.responseVerificationMode.isEnabled else { return }

        do {
            try await self.purchases.healthRequest(signatureVerification: true)
        } catch {
            throw Error.failedMakingSignedRequest(error)
        }
    }

    func convert(_ error: ErrorCode) -> Error {
        switch error {
        case .unknownError:
            return Error.unknown(error)

        case .offlineConnectionError:
            return Error.failedConnectingToAPI(error)

        case .invalidCredentialsError:
            return Error.invalidAPIKey

        case .signatureVerificationFailed:
            return Error.failedMakingSignedRequest(error)

        default:
            return Error.unknown(error)
        }
    }

}

extension PurchasesDiagnostics.Error: CustomNSError {

    // swiftlint:disable:next missing_docs
    public var errorUserInfo: [String: Any] {
        return [
            NSUnderlyingErrorKey: self.underlyingError as NSError? ?? NSNull(),
            NSLocalizedDescriptionKey: self.localizedDescription
        ]
    }

    var localizedDescription: String {
        switch self {
        case let .unknown(error): return "Unknown error: \(error.localizedDescription)"
        case let .failedConnectingToAPI(error): return "Error connecting to API: \(error.localizedDescription)"
        case let .failedFetchingOfferings(error): return "Failed fetching offerings: \(error.localizedDescription)"
        case let .failedMakingSignedRequest(error): return "Failed making signed request: \(error.localizedDescription)"
        case .invalidAPIKey: return "API key is not valid"
        }
    }

    private var underlyingError: Swift.Error? {
        switch self {
        case let .unknown(error): return error
        case let .failedConnectingToAPI(error): return error
        case let .failedFetchingOfferings(error): return error
        case let .failedMakingSignedRequest(error): return error
        case .invalidAPIKey:
            return nil
        }
    }

}
