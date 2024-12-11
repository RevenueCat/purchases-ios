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

    private static let defaultAppIsLatestVersion = true

    typealias CurrentVersionFetcher = () -> String?

    private lazy var currentAppVersion: String? = currentVersionFetcher()
    @Published
    private(set) var purchaseInformation: PurchaseInformation?
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

    func loadPurchaseInformation() async {
        do {
            let customerInfo = try await purchasesProvider.customerInfo()
            let hasActiveProducts =
            !customerInfo.activeSubscriptions.isEmpty || !customerInfo.nonSubscriptions.isEmpty

            if !hasActiveProducts {
                self.purchaseInformation = nil
                self.state = .success
                return
            }

            guard let activeTransaction = findActiveTransaction(customerInfo: customerInfo) else {
                Logger.warning(Strings.could_not_find_subscription_information)
                self.purchaseInformation = nil
                throw CustomerCenterError.couldNotFindSubscriptionInformation
            }

            let entitlement = customerInfo.entitlements.all.values
                .first(where: { $0.productIdentifier == activeTransaction.productIdentifier })

            self.purchaseInformation = try await createPurchaseInformation(for: activeTransaction,
                                                                           entitlement: entitlement)

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
        let event = CustomerCenterEvent.impression(CustomerCenterEventCreationData(), eventData)

        purchasesProvider.track(customerCenterEvent: event)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
fileprivate extension CustomerCenterViewModel {

#if DEBUG

    convenience init(
        purchaseInformation: PurchaseInformation,
        configuration: CustomerCenterConfigData
    ) {
        self.init(customerCenterActionHandler: nil)
        self.purchaseInformation = purchaseInformation
        self.configuration = configuration
        self.state = .success
    }

#endif

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension CustomerCenterViewModel {

    func findActiveTransaction(customerInfo: CustomerInfo) -> Transaction? {
        let activeSubscriptions = customerInfo.subscriptionsByProductIdentifier.values
            .filter(\.isActive)
            .sorted(by: {
                guard let date1 = $0.expiresDate, let date2 = $1.expiresDate else {
                    return $0.expiresDate != nil
                }
                return date1 < date2
            })

        let (activeAppleSubscriptions, otherActiveSubscriptions) = (
            activeSubscriptions.filter { $0.store == .appStore },
            activeSubscriptions.filter { $0.store != .appStore }
        )

        let (appleNonSubscriptions, otherNonSubscriptions) = (
            customerInfo.nonSubscriptions.filter { $0.store == .appStore },
            customerInfo.nonSubscriptions.filter { $0.store != .appStore }
        )

        return activeAppleSubscriptions.first ??
        appleNonSubscriptions.first ??
        otherActiveSubscriptions.first ??
        otherNonSubscriptions.first
    }

    func createPurchaseInformation(for transaction: Transaction,
                                   entitlement: EntitlementInfo?) async throws -> PurchaseInformation {
        if transaction.store == .appStore {
            guard let product = await purchasesProvider.products([transaction.productIdentifier]).first else {
                Logger.warning(Strings.could_not_find_subscription_information)
                throw CustomerCenterError.couldNotFindSubscriptionInformation
            }
            return PurchaseInformation(
                entitlement: entitlement,
                subscribedProduct: product,
                transaction: transaction
            )
        } else {
            return PurchaseInformation(
                entitlement: entitlement,
                transaction: transaction
            )
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
