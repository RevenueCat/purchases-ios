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

    typealias CurrentVersionFetcher = () -> String?

    private lazy var currentAppVersion: String? = currentVersionFetcher()

    @Published
    private(set) var hasActiveProducts: Bool = false
    @Published
    private(set) var hasAppleEntitlement: Bool = false
    @Published
    private(set) var appIsLatestVersion: Bool = defaultAppIsLatestVersion
    private(set) var purchasesProvider: CustomerCenterPurchasesType

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

    private let currentVersionFetcher: CurrentVersionFetcher
    internal let customerCenterActionHandler: CustomerCenterActionHandler?

    private var error: Error?

    init(
        customerCenterActionHandler: CustomerCenterActionHandler?,
        currentVersionFetcher: @escaping CurrentVersionFetcher = {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        },
        purchasesProvider: CustomerCenterPurchasesType = CustomerCenterPurchases()
    ) {
        self.state = .notLoaded
        self.currentVersionFetcher = currentVersionFetcher
        self.customerCenterActionHandler = customerCenterActionHandler
        self.purchasesProvider = purchasesProvider
    }

    #if DEBUG

    convenience init(
        hasActiveProducts: Bool = false,
        hasAppleEntitlement: Bool = false
    ) {
        self.init(customerCenterActionHandler: nil)
        self.hasActiveProducts = hasActiveProducts
        self.hasAppleEntitlement = hasAppleEntitlement
        self.state = .success
    }

    #endif

    func loadHasActivePurchases() async {
        do {
            let customerInfo = try await purchasesProvider.customerInfo()
            self.hasActiveProducts = customerInfo.activeSubscriptions.count > 0 ||
                                customerInfo.nonSubscriptions.count > 0
            self.hasAppleEntitlement = customerInfo.entitlements.active.contains { entitlement in
                entitlement.value.store == .appStore
            }
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

    func trackImpression(darkMode: Bool, displayMode: CustomerCenterPresentationMode) {
        let isSandbox = purchasesProvider.isSandbox
        let eventData = CustomerCenterEvent.Data(locale: .current,
                                                 darkMode: darkMode,
                                                 isSandbox: isSandbox,
                                                 displayMode: displayMode)
        let event = CustomerCenterEvent.impression(CustomerCenterEvent.CreationData(), eventData)

        Task.detached(priority: .background) { [purchasesProvider = self.purchasesProvider] in
            try await purchasesProvider.track(customerCenterEvent: event)
        }
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
