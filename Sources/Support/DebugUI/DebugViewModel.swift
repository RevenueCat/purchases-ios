//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DebugViewModel.swift
//
//  Created by Nacho Soto on 5/30/23.

import Foundation

#if DEBUG && swift(>=5.8) && (os(iOS) || os(macOS) || VISION_OS)

import SwiftUI

@MainActor
@available(iOS 16.0, macOS 13.0, *)
final class DebugViewModel: ObservableObject {

    struct Configuration: Codable {

        var sdkVersion: String = SystemInfo.frameworkVersion
        var observerMode: Bool
        var sandbox: Bool
        var storeKit2Enabled: Bool
        var locale: Locale
        var offlineCustomerInfoSupport: Bool
        var verificationMode: String
        var receiptURL: URL?

    }

    var configuration: LoadingState<Configuration, Never> = .loading

    @Published
    var diagnosticsResult: LoadingState<(), NSError> = .loading
    @Published
    var offerings: LoadingState<Offerings, NSError> = .loading
    #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
    @Published
    var customerInfo: LoadingState<CustomerInfo, NSError> = .loading
    @Published
    var currentAppUserID: String?
    #endif

    // We can't directly store instances of `NavigationPath`, since that causes runtime crashes when
    // loading this type in iOS <= 15, even with @available checks correctly in place.
    // See https://openradar.appspot.com/radar?id=4970535809187840 / https://github.com/apple/swift/issues/58099
    @Published
    private var _navigationPath: Any = NavigationPath()

    var navigationPath: NavigationPath {
        // swiftlint:disable:next force_cast
        get { return self._navigationPath as! NavigationPath }
        set { self._navigationPath = newValue }
    }

    @MainActor
    func load() async {
        self.configuration = .loaded(.create())

        self.diagnosticsResult = await .create { try await PurchasesDiagnostics.default.testSDKHealth() }
        self.offerings = await .create { try await Purchases.shared.offerings() }
        #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
        self.customerInfo = await .create { try await Purchases.shared.customerInfo() }
        self.currentAppUserID = Purchases.shared.appUserID

        for await info in Purchases.shared.customerInfoStream {
            self.customerInfo = .loaded(info)
        }
        #endif
    }

}

@available(iOS 16.0, macOS 13.0, *)
extension DebugViewModel {

    var diagnosticsStatus: String {
        switch self.diagnosticsResult {
        case .loading: return "Loading..."
        case .loaded: return "Configuration OK"
        case let .failed(error): return "Error: \(error.localizedDescription)"
        }
    }

    @ViewBuilder
    var diagnosticsIcon: some View {
        switch self.diagnosticsResult {
        case .loading:
            Image(systemName: "gear.circle")
                .foregroundColor(.gray)
        case .loaded:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
        }
    }

}

@available(iOS 16.0, macOS 13.0, *)
extension DebugViewModel.Configuration {

    var receiptStatus: String {
        switch self.receiptURL {
        case .none:
            return "no URL"
        case let .some(url):
            if FileManager.default.fileExists(atPath: url.relativePath) {
                return "present"
            } else {
                return "missing"
            }
        }
    }

}

// MARK: -

enum LoadingState<Value, Error: Swift.Error> {

    case loading
    case loaded(Value)
    case failed(Error)

}

extension LoadingState where Error == NSError {

    static func create(_ loader: @Sendable () async throws -> Value) async -> Self {
        do {
            return .loaded(try await loader())
        } catch {
            return .failed(error as NSError)
        }
    }

}

@available(iOS 16.0, macOS 13.0, *)
private extension DebugViewModel.Configuration {

    static func create(with purchases: Purchases = .shared) -> Self {
        return .init(
            observerMode: purchases.observerMode,
            sandbox: purchases.isSandbox,
            storeKit2Enabled: purchases.isStoreKit2EnabledAndAvailable,
            locale: .autoupdatingCurrent,
            offlineCustomerInfoSupport: purchases.offlineCustomerInfoEnabled,
            verificationMode: purchases.responseVerificationMode.display,
            receiptURL: purchases.receiptURL
        )
    }

}

private extension Signing.ResponseVerificationMode {

    var display: String {
        switch self {
        case .disabled: return "disabled"
        case .informational: return "informational"
        case .enforced: return "enforced"
        }
    }

}

#endif
