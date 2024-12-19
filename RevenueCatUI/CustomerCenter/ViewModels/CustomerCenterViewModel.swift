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
    private(set) var customerCenterStoreKitUtilities: CustomerCenterStoreKitUtilitiesType

    @Published
    private(set) var onUpdateAppClick: (() -> Void)?

    /// Whether or not the Customer Center should warn the customer that they're on an outdated version of the app.
    var shouldShowAppUpdateWarnings: Bool {
        return !appIsLatestVersion && (configuration?.support.shouldWarnCustomerToUpdate ?? true)
    }

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

    private let currentVersionFetcher: CurrentVersionFetcher
    internal let customerCenterActionHandler: CustomerCenterActionHandler?

    private var error: Error?

    init(
        customerCenterActionHandler: CustomerCenterActionHandler?,
        currentVersionFetcher: @escaping CurrentVersionFetcher = {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        },
        purchasesProvider: CustomerCenterPurchasesType = CustomerCenterPurchases(),
        customerCenterStoreKitUtilities: CustomerCenterStoreKitUtilitiesType = CustomerCenterStoreKitUtilities()
    ) {
        self.state = .notLoaded
        self.currentVersionFetcher = currentVersionFetcher
        self.customerCenterActionHandler = customerCenterActionHandler
        self.purchasesProvider = purchasesProvider
        self.customerCenterStoreKitUtilities = customerCenterStoreKitUtilities
    }

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

    func loadScreen() async {
        do {
            try await self.loadPurchaseInformation()
            try await self.loadCustomerCenterConfig()
            self.state = .success
        } catch {
            self.state = .error(error)
        }
    }

    func performRestore() async -> RestorePurchasesAlert.AlertType {
        self.customerCenterActionHandler?(.restoreStarted)
        do {
            let customerInfo = try await purchasesProvider.restorePurchases()
            self.customerCenterActionHandler?(.restoreCompleted(customerInfo))
            let hasPurchases = !customerInfo.activeSubscriptions.isEmpty || !customerInfo.nonSubscriptions.isEmpty
            return hasPurchases ? .purchasesRecovered : .purchasesNotFound
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
private extension CustomerCenterViewModel {

    func loadPurchaseInformation() async throws {
            let customerInfo = try await purchasesProvider.customerInfo(fetchPolicy: .fetchCurrent)

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
    }

    func loadCustomerCenterConfig() async throws {
        self.configuration = try await purchasesProvider.loadCustomerCenter()
        if let productId = configuration?.productId {
            self.onUpdateAppClick = {
                // productId is a positive integer, so it should be safe to construct a URL from it.
                let url = URL(string: "https://itunes.apple.com/app/id\(productId)")!
                URLUtilities.openURLIfNotAppExtension(url)
            }
        }
    }

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
            if let product = await purchasesProvider.products([transaction.productIdentifier]).first {
                return await PurchaseInformation.purchaseInformationUsingRenewalInfo(
                    entitlement: entitlement,
                    subscribedProduct: product,
                    transaction: transaction,
                    customerCenterStoreKitUtilities: customerCenterStoreKitUtilities
                )
            } else {
                Logger.warning(
                    Strings.could_not_find_product_loading_without_product_information(transaction.productIdentifier)
                )

                return PurchaseInformation(
                    entitlement: entitlement,
                    transaction: transaction
                )
            }
        }
        Logger.warning(Strings.active_product_is_not_apple_loading_without_product_information(transaction.store))

        return PurchaseInformation(
            entitlement: entitlement,
            transaction: transaction
        )
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
