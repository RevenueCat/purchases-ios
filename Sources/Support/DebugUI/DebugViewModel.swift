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
    var diagnosticsResult: LoadingState<PurchasesDiagnostics.SDKHealthReport, Never> = .loading
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
        #if DEBUG && !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
        self.diagnosticsResult = .loaded(await PurchasesDiagnostics.default.healthReport())
        #endif
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
        case let .loaded(healthReport):
            switch healthReport.status {
            case .healthy: return "Configuration OK"
            case .unhealthy: return "Invalid Configuration"
            }
        }
    }

    var diagnosticsExplainer: String? {
        switch self.diagnosticsResult {
        case let .loaded(healthReport):
            switch healthReport.status {
            case let .healthy(warnings):
                return warnings.count > 0 ? """
                Your RevenueCat configuration is valid, however we encountered some potential issues \
                during validation. Feel free to ignore them if your configuration works as expected.
                """
                : nil
            case .unhealthy(let error): return error.localizedDescription
            }
        default: return nil
        }
    }

    var diagnosticsActionURL: URL? {
        switch self.diagnosticsResult {
        case let .loaded(healthReport):
            guard let appId = healthReport.appId, let projectId = healthReport.projectId else {
                return nil
            }
            switch healthReport.status {
            case .healthy: return nil
            case .unhealthy(let error):
                switch error {
                case .offeringConfiguration:
                    return URL(string: "https://app.revenuecat.com/projects/\(projectId)/offerings")
                case .invalidBundleId:
                    return URL(string: "https://app.revenuecat.com/projects/\(projectId)/apps/\(appId)")
                case .invalidProducts:
                    return URL(string: "https://app.revenuecat.com/projects/\(projectId)/products")
                default: return nil
                }
            }
        case .loading, .failed: return nil
        }
    }

    var diagnosticsActionTitle: String? {
        switch self.diagnosticsResult {
        case .loading, .failed: return nil
        case let .loaded(healthReport):
            switch healthReport.status {
            case .healthy: return nil
            case .unhealthy(let error):
                switch error {
                case .offeringConfiguration:
                    return "Open Offerings"
                case .invalidBundleId:
                    return "Open App Configuration"
                case .invalidProducts:
                    return "Open Products"
                default: return nil
                }
            }
        }
    }

    @ViewBuilder
    var diagnosticsIcon: some View {
        switch self.diagnosticsResult {
        case .loading:
            Image(systemName: "gear.circle")
                .foregroundColor(.gray)
        case let .loaded(healthReport):
            healthReport.status.icon
        }
    }

    var errorsToExpandOn: [PurchasesDiagnostics.SDKHealthError] {
        switch self.diagnosticsResult {
        case .loading: return []
        case let .loaded(healthReport):
            switch healthReport.status {
            case let .healthy(warnings): return warnings
            case let .unhealthy(error):
                switch error {
                case .invalidProducts, .offeringConfiguration: return [error]
                default: return []
                }
            }
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
