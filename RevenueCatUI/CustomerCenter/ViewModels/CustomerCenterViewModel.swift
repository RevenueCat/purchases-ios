//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterViewModel.swift
//
//
//  Created by Cesar de la Vega on 27/5/24.
//

import Foundation
import RevenueCat

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor class CustomerCenterViewModel: ObservableObject {
    // We fail open.
    private static let defaultAppIsLatestVersion = true

    typealias CustomerInfoFetcher = @Sendable () async throws -> CustomerInfo
    typealias CurrentVersionFetcher = () -> String?

    private lazy var currentAppVersion: String? = currentVersionFetcher()

    @Published
    private(set) var hasSubscriptions: Bool = false
    @Published
    private(set) var subscriptionsAreFromApple: Bool = false
    @Published
    private(set) var appIsLatestVersion: Bool = defaultAppIsLatestVersion

    // @PublicForExternalTesting
    @Published
    var state: CustomerCenterViewState {
        didSet {
            if case let .error(stateError) = state {
                self.error = stateError
            }
        }
    }
    @Published
    var configuration: CustomerCenterConfigData? {
        didSet {
            guard
                let currentVersionString = currentAppVersion?.versionString(),
                let latestVersionString = configuration?.lastPublishedAppVersion?.versionString(),
                let currentVersion = try? SemanticVersion(currentVersionString),
                let latestVersion = try? SemanticVersion(latestVersionString)
            else {
                self.appIsLatestVersion = Self.defaultAppIsLatestVersion
                return
            }

            self.appIsLatestVersion = currentVersion >= latestVersion
      }
    }

    var isLoaded: Bool {
        return state != .notLoaded && configuration != nil
    }

    private var customerInfoFetcher: CustomerInfoFetcher
    private let currentVersionFetcher: CurrentVersionFetcher
    internal let customerCenterActionHandler: CustomerCenterActionHandler?

    private var error: Error?

    init(
        customerCenterActionHandler: CustomerCenterActionHandler?,
        customerInfoFetcher: @escaping CustomerInfoFetcher = {
            guard Purchases.isConfigured else { throw PaywallError.purchasesNotConfigured }
            return try await Purchases.shared.customerInfo()
        },
        currentVersionFetcher: @escaping CurrentVersionFetcher = {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        }
    ) {
        self.state = .notLoaded
        self.customerInfoFetcher = customerInfoFetcher
        self.currentVersionFetcher = currentVersionFetcher
        self.customerCenterActionHandler = customerCenterActionHandler
    }

    #if DEBUG

    convenience init(
        hasSubscriptions: Bool = false,
        areSubscriptionsFromApple: Bool = false
    ) {
        self.init(customerCenterActionHandler: nil)
        self.hasSubscriptions = hasSubscriptions
        self.subscriptionsAreFromApple = areSubscriptionsFromApple
        self.state = .success
    }

    #endif

    func loadHasSubscriptions() async {
        do {
            // swiftlint:disable:next todo
            // TODO: support non-consumables
            let customerInfo = try await self.customerInfoFetcher()
            let hasSubscriptions = customerInfo.activeSubscriptions.count > 0

            let subscriptionsAreFromApple = customerInfo.entitlements.active.contains(where: { entitlement in
                entitlement.value.store == .appStore || entitlement.value.store == .macAppStore &&
                customerInfo.activeSubscriptions.contains(entitlement.value.productIdentifier)
            })

            self.hasSubscriptions = hasSubscriptions
            self.subscriptionsAreFromApple = subscriptionsAreFromApple
            self.state = .success
        } catch {
            self.state = .error(error)
        }
    }

    func loadCustomerCenterConfig() async {
        do {
            self.configuration = try await Purchases.shared.loadCustomerCenter()
        } catch {
            self.state = .error(error)
        }
    }

    func performRestore() async -> RestorePurchasesAlert.AlertType {
        self.customerCenterActionHandler?(.restoreStarted)
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            self.customerCenterActionHandler?(.restoreCompleted(customerInfo))
            let hasEntitlements = customerInfo.entitlements.active.count > 0
            return hasEntitlements ? .purchasesRecovered : .purchasesNotFound
        } catch {
            self.customerCenterActionHandler?(.restoreFailed(error))
            return .purchasesNotFound
        }
    }

    func onAppUpdateClick() {
        // swiftlint:disable:next todo
        // TODO: implement opening the App Store
    }
}

fileprivate extension String {
    /// Takes the first characters of this string, if they conform to Major.Minor.Patch. Returns nil otherwise.
    /// Note that Minor and Patch are optional. So if this string starts with a single number, that number is returned.
    func versionString() -> String? {
        do {
            let pattern = #"^(\d+)(?:\.\d+)?(?:\.\d+)?"#
            let regex = try NSRegularExpression(pattern: pattern)
            let match = regex.firstMatch(in: self, range: NSRange(self.startIndex..., in: self))
            return match.map { String(self[Range($0.range, in: self)!]) }
        } catch {
            return nil
        }
    }
}

#endif
