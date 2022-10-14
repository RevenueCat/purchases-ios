//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SDKTester.swift
//
//  Created by Nacho Soto on 9/21/22.

import Foundation

/// `SDKTester` allows you to ensure that the SDK is set up correctly by diagnosing configuration errors.
/// To run the test, simply call ``SDKTester/test()``.
///
/// #### Example:
/// ```swift
/// let tester = SDKTester.default
/// do {
///     try await tester.test()
/// } catch {
///     print("SDKTester failed: \(error.localizedDescription)")
/// }
/// ```
@objc(RCSDKTester)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
public final class SDKTester: NSObject {

    typealias SDK = PurchasesType & InternalPurchasesType

    private let purchases: SDK

    init(purchases: SDK) {
        self.purchases = purchases
    }

    /// Default instance of `SDKTester`.
    /// Note: you must call ``Purchases/configure(with:)-6oipy`` before using this.
    @objc
    public static let `default`: SDKTester = .init(purchases: Purchases.shared)
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
extension SDKTester {

    /// An error that represents a failing step in ``SDKTester``
    public enum Error: Swift.Error {

        /// Connection to the API failed
        case failedConnectingToAPI(Swift.Error)

        /// API key is invalid
        case invalidAPIKey

        /// Fetching offerings failed due to the underlying error
        case failedFetchingOfferings(Swift.Error)

        /// Any other not identifier error. You can check the undelying error for details.
        case unknown(Swift.Error)

    }

}

// MARK: - Implementation

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
extension SDKTester {

    /// Perform tests to ensure SDK is configured correctly.
    /// - `Throws`: ``SDKTester/Error`` if any step fails
    @objc(testWithCompletion:)
    public func test() async throws {
        do {
            try await self.unauthenticatedRequest()
            try await self.authenticatedRequest()
            try await self.offeringsRequest()
        } catch let error as Error {
            throw error
        } catch let error {
            // Catch every other error to ensure that we only throw `Error`s from here.
            throw Error.unknown(error)
        }
    }

}

// MARK: - Private

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
private extension SDKTester {

    /// Makes a request to the backend, to verify connectivity, firewalls, or anything blocking network traffic.
    func unauthenticatedRequest() async throws {
        do {
            try await self.purchases.healthRequest()
        } catch {
            throw Error.failedConnectingToAPI(error)
        }
    }

    func authenticatedRequest() async throws {
        do {
            _ = try await self.purchases.customerInfo()
        } catch let error as ErrorCode {
            throw self.convert(error)
        } catch {
            throw Error.unknown(error)
        }
    }

    func offeringsRequest() async throws {
        do {
            _ = try await self.purchases.offerings(fetchPolicy: .failIfProductsAreMissing)
        } catch {
            throw Error.failedFetchingOfferings(error)
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

        default:
            return Error.unknown(error)
        }
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
extension SDKTester.Error: CustomNSError {

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
        case .invalidAPIKey: return "API key is not valid"
        }
    }

    private var underlyingError: Swift.Error? {
        switch self {
        case let .unknown(error): return error
        case let .failedConnectingToAPI(error): return error
        case let .failedFetchingOfferings(error): return error
        case .invalidAPIKey: return nil
        }
    }

}
