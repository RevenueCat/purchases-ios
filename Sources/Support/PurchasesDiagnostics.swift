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
public final class PurchasesDiagnostics: NSObject {

    typealias SDK = PurchasesType & InternalPurchasesType

    private let purchases: SDK

    init(purchases: SDK) {
        self.purchases = purchases
    }

    /// Default instance of `PurchasesDiagnostics`.
    /// Note: you must call ``Purchases/configure(with:)-6oipy`` before using this.
    @objc
    public static let `default`: PurchasesDiagnostics = .init(purchases: Purchases.shared)
}

extension PurchasesDiagnostics {
    
    public enum ProductStatus: String {
        case ok
        case couldNotCheck = "could_not_check"
        case notFound = "not_found"
        case actionInProgress = "action_in_progress"
        case needsAction = "needs_action"
        case unknown
    }
    
    public struct InvalidProductErrorPayload {
        let identifier: String
        let title: String?
        let status: ProductStatus
        let description: String
    }
    
    public struct InvalidBundleIdErrorPayload {
        let appBundleId: String
        let sdkBundleId: String
    }
    
    public enum SDKHealthCheckStatus {
        case passed
        case failed
        case warning
    }

    public struct OfferingConfigurationErrorPayload {
        let identifier: String
        let packages: [Package]
        let status: SDKHealthCheckStatus
        
        public struct Package {
            let identifier: String
            let title: String?
            let status: ProductStatus
            let description: String
            let productIdentifier: String
            let productTitle: String?
        }
    }

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
        
        /// Version of the SDK is not supported
        case invalidSDKVersion
        
        /// There are no offerings in project
        case noOfferings
        
        /// Offerings are not configured correctly
        case offeringConfiguration([OfferingConfigurationErrorPayload])
        
        /// App bundle ID does not match the one set in the dashboard
        case invalidBundleId(InvalidBundleIdErrorPayload?)
        
        /// One or more products are not configured correctly
        case invalidProducts([InvalidProductErrorPayload])
        
        /// The person is not authorized to make In-App Purchases
        case notAuthorizedToMakePayments

        /// Any other not identifier error. You can check the undelying error for details.
        case unknown(Swift.Error)

    }

}

extension PurchasesDiagnostics {
    public enum SDKHealthStatus {
        case healthy(warnings: [PurchasesDiagnostics.Error])
        case unhealthy(PurchasesDiagnostics.Error)
    }
    
    public func testSDKHealth() async throws {
        switch await self.healthReport() {
        case let .unhealthy(error): throw error
        default: break
        }
    }
    
    private var canMakePayments: Bool {
        if #available(iOS 15.0, macOS 12.0, *) {
            return AppStore.canMakePayments
        } else {
            return SKPaymentQueue.canMakePayments()
        }
    }
    
    public func healthReport() async -> SDKHealthStatus {
        do {
            if !canMakePayments {
                return .unhealthy(.notAuthorizedToMakePayments)
            }
            return try await self.purchases.healthReportRequest().validate()
        } catch let error as BackendError {
            if case .networkError(let networkError) = error,
               case .errorResponse(let response, _, _) = networkError, response.code == .invalidAPIKey {
                return .unhealthy(.invalidAPIKey)
            }
            return .unhealthy(.unknown(error))
        } catch {
            return .unhealthy(.unknown(error))
        }
    }
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
        case .notAuthorizedToMakePayments: return "The person is not authorized to make payments on this device."
        case let .unknown(error): return "Unknown error: \(error.localizedDescription)"
        case let .failedConnectingToAPI(error): return "Error connecting to API: \(error.localizedDescription)"
        case let .failedFetchingOfferings(error): return "Failed fetching offerings: \(error.localizedDescription)"
        case let .failedMakingSignedRequest(error): return "Failed making signed request: \(error.localizedDescription)"
        case .invalidAPIKey: return "API key is not valid"
        case .invalidSDKVersion: return "SDK Version is not supported"
        case .noOfferings: return "No offerings configured"
        case let .offeringConfiguration(payload):
            guard let offendingOffering = payload.first(where: { $0.status == .failed }) else {
                return "Default offering is not configured correctly"
            }
            
            return offendingOffering.packages.isEmpty ? 
                "Offering '\(offendingOffering.identifier)' has no packages" :
            "Offering '\(offendingOffering.identifier)' uses \(offendingOffering.packages.filter({ $0.status != .ok }).count) products that are not ready in App Store Connect."
        case let .invalidBundleId(payload):
            guard let payload else {
                return "Bundle ID in your app does not match the Bundle ID in the RevenueCat dashboard"
            }
            return "Bundle ID in your app '\(payload.sdkBundleId)' does not match the RevenueCat app Bundle ID '\(payload.appBundleId)'"
        case let .invalidProducts(products):
            if products.isEmpty {
                return "Your app has no products"
            }
            
            return "You must have at least one product approved in App Store Connect."
        }
    }

    private var underlyingError: Swift.Error? {
        switch self {
        case let .unknown(error): return error
        case let .failedConnectingToAPI(error): return error
        case let .failedFetchingOfferings(error): return error
        case let .failedMakingSignedRequest(error): return error
        case .invalidAPIKey, .offeringConfiguration, .invalidSDKVersion, .noOfferings, .invalidBundleId, .invalidProducts, .notAuthorizedToMakePayments:
            return nil
        }
    }

}
