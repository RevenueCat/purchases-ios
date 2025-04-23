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

    @Published
    private(set) var onUpdateAppClick: (() -> Void)?

    @Published
    var manageSubscriptionsSheet = false

    private(set) var purchasesProvider: CustomerCenterPurchasesType
    private(set) var customerCenterStoreKitUtilities: CustomerCenterStoreKitUtilitiesType

    /// Whether or not the Customer Center should warn the customer that they're on an outdated version of the app.
    var shouldShowAppUpdateWarnings: Bool {
        return !appIsLatestVersion && (configuration?.support.shouldWarnCustomerToUpdate ?? true)
    }

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

    /// The action wrapper that handles both the deprecated handler and the new preference system
    internal let actionWrapper: CustomerCenterActionWrapper

    /// Used to make testing easier
    internal var currentTask: Task<Void, Never>?

    private var error: Error?
    private var impressionData: CustomerCenterEvent.Data?

    init(
        actionWrapper: CustomerCenterActionWrapper,
        currentVersionFetcher: @escaping CurrentVersionFetcher = {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        },
        purchasesProvider: CustomerCenterPurchasesType = CustomerCenterPurchases(),
        customerCenterStoreKitUtilities: CustomerCenterStoreKitUtilitiesType = CustomerCenterStoreKitUtilities()
    ) {
        self.state = .notLoaded
        self.currentVersionFetcher = currentVersionFetcher
        self.actionWrapper = actionWrapper
        self.purchasesProvider = purchasesProvider
        self.customerCenterStoreKitUtilities = customerCenterStoreKitUtilities
    }

    convenience init(uiPreviewPurchaseProvider: CustomerCenterPurchasesType) {
        self.init(actionWrapper: CustomerCenterActionWrapper(legacyActionHandler: nil),
                  purchasesProvider: uiPreviewPurchaseProvider)
    }

    #if DEBUG

    convenience init(
        purchaseInformation: PurchaseInformation,
        configuration: CustomerCenterConfigData
    ) {
        self.init(actionWrapper: CustomerCenterActionWrapper(legacyActionHandler: nil))
        self.purchaseInformation = purchaseInformation
        self.configuration = configuration
        self.state = .success
    }

    #endif

    func loadScreen(shouldSync: Bool = false) async {
        do {
            let customerInfo = shouldSync ?
            try await self.purchasesProvider.syncPurchases() :
            try await purchasesProvider.customerInfo(fetchPolicy: .fetchCurrent)

            try await self.loadPurchaseInformation(customerInfo: customerInfo)
            try await self.loadCustomerCenterConfig()
            self.state = .success
        } catch {
            self.state = .error(error)
        }
    }

    func onDismissRestorePurchasesAlert() {
        currentTask = Task {
            await loadScreen()
        }
    }

    func trackImpression(darkMode: Bool, displayMode: CustomerCenterPresentationMode) {
        guard impressionData == nil else {
            return
        }

        let eventData = CustomerCenterEvent.Data(locale: .current,
                                                 darkMode: darkMode,
                                                 isSandbox: purchasesProvider.isSandbox,
                                                 displayMode: displayMode)
        defer { self.impressionData = eventData }

        let event = CustomerCenterEvent.impression(CustomerCenterEventCreationData(), eventData)
        purchasesProvider.track(customerCenterEvent: event)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension CustomerCenterViewModel {

    func loadPurchaseInformation(customerInfo: CustomerInfo) async throws {
        let hasActiveProducts =  !customerInfo.activeSubscriptions.isEmpty ||
        !customerInfo.nonSubscriptions.isEmpty

        if !hasActiveProducts {
            self.purchaseInformation = nil
            self.state = .success
            return
        }

        guard let activeTransaction = customerInfo.earliestExpiringTransaction() else {
            Logger.warning(Strings.could_not_find_subscription_information)
            self.purchaseInformation = nil
            throw CustomerCenterError.couldNotFindSubscriptionInformation
        }

        let entitlement = customerInfo.entitlements.all.values
            .first(where: { $0.productIdentifier == activeTransaction.productIdentifier })

        self.purchaseInformation = try await createPurchaseInformation(
            for: activeTransaction,
            entitlement: entitlement,
            customerInfo: customerInfo)
    }

    func loadCustomerCenterConfig() async throws {
        self.configuration = try await purchasesProvider.loadCustomerCenter()
        if let productId = configuration?.productId,
            let url = URL(string: "https://itunes.apple.com/app/id\(productId)") {
            self.onUpdateAppClick = {
                // productId is a positive integer, so it should be safe to construct a URL from it.
                URLUtilities.openURLIfNotAppExtension(url)
            }
        }
    }

    func createPurchaseInformation(for transaction: Transaction,
                                   entitlement: EntitlementInfo?,
                                   customerInfo: CustomerInfo) async throws -> PurchaseInformation {
        if transaction.store == .appStore {
            if let product = await purchasesProvider.products([transaction.productIdentifier]).first {
                return await PurchaseInformation.purchaseInformationUsingRenewalInfo(
                    entitlement: entitlement,
                    subscribedProduct: product,
                    transaction: transaction,
                    customerCenterStoreKitUtilities: customerCenterStoreKitUtilities,
                    customerInfoRequestedDate: customerInfo.requestDate
                )
            } else {
                Logger.warning(
                    Strings.could_not_find_product_loading_without_product_information(transaction.productIdentifier)
                )

                return PurchaseInformation(
                    entitlement: entitlement,
                    transaction: transaction,
                    customerInfoRequestedDate: customerInfo.requestDate
                )
            }
        }
        Logger.warning(Strings.active_product_is_not_apple_loading_without_product_information(transaction.store))

        return PurchaseInformation(
            entitlement: entitlement,
            transaction: transaction,
            customerInfoRequestedDate: customerInfo.requestDate
        )
    }
}

fileprivate extension String {
    // swiftlint:disable force_unwrapping

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
