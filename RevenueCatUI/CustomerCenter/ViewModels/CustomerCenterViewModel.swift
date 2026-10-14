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

import Combine
import Foundation
@_spi(Internal) import RevenueCat

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor class CustomerCenterViewModel: ObservableObject {

    typealias CurrentVersionFetcher = () -> String?

    private static let defaultAppIsLatestVersion = true

    private lazy var currentAppVersion: String? = currentVersionFetcher()

    @Published
    private(set) var appIsLatestVersion: Bool = defaultAppIsLatestVersion

    @Published
    private(set) var virtualCurrencies: VirtualCurrencies?

    @Published
    private(set) var onUpdateAppClick: (() -> Void)?

    @Published
    var manageSubscriptionsSheet = false

    @Published
    var changePlansSheet = false

    @Published var state: CustomerCenterViewState

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

    @Published
    var subscriptionsSection: [PurchaseInformation] = []

    @Published
    var nonSubscriptionsSection: [PurchaseInformation] = []

    private(set) var purchasesProvider: CustomerCenterPurchasesType
    private(set) var customerCenterStoreKitUtilities: CustomerCenterStoreKitUtilitiesType

    private let currentVersionFetcher: CurrentVersionFetcher

    @Published internal var customerInfo: CustomerInfo?

    /// The action wrapper that handles both the deprecated handler and the new preference system
    internal let actionWrapper: CustomerCenterActionWrapper

    /// Used to make testing easier
    internal var currentTask: Task<Void, Never>?

    private var impressionData: CustomerCenterEvent.Data?
    private var previewLoadGeneration = 0

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
        self.customerInfo = nil
    }

    convenience init(
        uiPreviewPurchaseProvider: CustomerCenterPurchasesType
    ) {
        self.init(
            actionWrapper: CustomerCenterActionWrapper(legacyActionHandler: nil),
            purchasesProvider: uiPreviewPurchaseProvider
        )
    }

    #if DEBUG

    convenience init(
        configuration: CustomerCenterConfigData
    ) {
        self.init(actionWrapper: CustomerCenterActionWrapper(legacyActionHandler: nil))
        self.configuration = configuration
        self.state = .success
    }

    convenience init(
        activeSubscriptionPurchases: [PurchaseInformation],
        activeNonSubscriptionPurchases: [PurchaseInformation],
        virtualCurrencies: VirtualCurrencies? = nil,
        configuration: CustomerCenterConfigData
    ) {
        self.init(actionWrapper: CustomerCenterActionWrapper(legacyActionHandler: nil))
        self.subscriptionsSection = activeSubscriptionPurchases
        self.nonSubscriptionsSection = activeNonSubscriptionPurchases
        self.virtualCurrencies = virtualCurrencies
        self.configuration = configuration
        self.state = .success
    }

    #endif

    func loadScreen(shouldSync: Bool = false) async {
        if let provider = purchasesProvider as? CustomerCenterPreviewProvider {
            await loadPreviewScreen(provider: provider, shouldSync: shouldSync)
            return
        }

        do {
            let customerInfo = try await fetchCustomerInfo(shouldSync: shouldSync)

            let configuration = try await self.loadCustomerCenterConfig()
            self.subscriptionsSection = await loadSubscriptions(
                customerInfo: customerInfo, configuration: configuration
            )
            self.nonSubscriptionsSection = await loadNonSubscriptions(
                customerInfo: customerInfo, configuration: configuration
            )
            self.customerInfo = customerInfo

            if shouldShowVirtualCurrencies {
                purchasesProvider.invalidateVirtualCurrenciesCache()
                self.virtualCurrencies = try? await purchasesProvider.virtualCurrencies()
            } else {
                self.virtualCurrencies = nil
            }
            self.state = .success
        } catch {
            self.state = .error(error)
        }
    }

    /// Publishes a complete preview update only if this is the latest load and its task is still active.
    func loadPreviewScreen(
        provider: CustomerCenterPreviewProvider, shouldSync: Bool = false, customerInfo: CustomerInfo? = nil
    ) async {
        guard !Task.isCancelled else { return }
        previewLoadGeneration += 1
        let generation = previewLoadGeneration

        do {
            let resolvedCustomerInfo: CustomerInfo
            if let customerInfo {
                resolvedCustomerInfo = customerInfo
            } else {
                resolvedCustomerInfo = try await fetchCustomerInfo(shouldSync: shouldSync)
            }

            let configuration = try await purchasesProvider.loadCustomerCenter()
            let subscriptions = await loadSubscriptions(
                customerInfo: resolvedCustomerInfo, configuration: configuration
            )
            let nonSubscriptions = await loadNonSubscriptions(
                customerInfo: resolvedCustomerInfo, configuration: configuration
            )
            var virtualCurrencies: VirtualCurrencies?
            if configuration.support.displayVirtualCurrencies == true {
                purchasesProvider.invalidateVirtualCurrenciesCache()
                virtualCurrencies = try? await purchasesProvider.virtualCurrencies()
            }
            try Task.checkCancellation()
            guard generation == previewLoadGeneration else { return }
            self.updatePreviewConfiguration(configuration, provider: provider)
            self.subscriptionsSection = subscriptions
            self.nonSubscriptionsSection = nonSubscriptions
            self.virtualCurrencies = virtualCurrencies
            self.customerInfo = resolvedCustomerInfo
            self.state = .success
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled, generation == previewLoadGeneration else { return }
            self.state = .error(error)
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

    func loadNonSubscriptions(
        customerInfo: CustomerInfo, configuration: CustomerCenterConfigData
    ) async -> [PurchaseInformation] {
        var activeNonSubscriptionPurchases: [PurchaseInformation] = []
        // customerInfo returns these oldest first, and the management screen only shows the first few
        for subscription in customerInfo.nonSubscriptions.sorted(by: { $0.purchaseDate > $1.purchaseDate }) {

            let purchaseInfo: PurchaseInformation = await .from(
                transaction: subscription,
                customerInfo: customerInfo,
                purchasesProvider: purchasesProvider,
                changePlans: [],
                customerCenterStoreKitUtilities: customerCenterStoreKitUtilities,
                localization: configuration.localization
            )
            activeNonSubscriptionPurchases.append(purchaseInfo)
        }
        return activeNonSubscriptionPurchases
    }

    func loadMostRecentExpiredTransaction(
        customerInfo: CustomerInfo, configuration: CustomerCenterConfigData
    ) async -> [PurchaseInformation] {
        let inactive = customerInfo.subscriptionsByProductIdentifier
            .filter { !$0.value.isActive }
            .sorted { sub1, sub2 in
                // most recent expired
                let date1 = sub1.value.expiresDate
                let date2 = sub2.value.expiresDate

                switch (date1, date2) {
                case let (date1?, date2?):
                    return date1 > date2
                case (nil, _?):
                    return false
                case (_?, nil):
                    return true
                case (nil, nil):
                    return false
                }
            }
            .first

        guard let inactiveSub = inactive?.value else {
            return []
        }

        let purchaseInfo: PurchaseInformation = await .from(
            transaction: inactiveSub,
            customerInfo: customerInfo,
            purchasesProvider: purchasesProvider,
            changePlans: [],
            customerCenterStoreKitUtilities: customerCenterStoreKitUtilities,
            localization: configuration.localization
        )

        return [purchaseInfo]
    }

    func loadSubscriptions(
        customerInfo: CustomerInfo,
        configuration: CustomerCenterConfigData
    ) async -> [PurchaseInformation] {
        var activeSubscriptionPurchases: [PurchaseInformation] = []
        let subscriptions = customerInfo.activeSubscriptions
            .compactMap({ id in
                // Do the opposite as CustomerInfo.extractProductIDAndBasePlan for non-apple products
                let idWithoutBasePlan = id.split(separator: ":").first.map { id in String(id) } ?? id
                return customerInfo.subscriptionsByProductIdentifier[idWithoutBasePlan]
                    ?? customerInfo.subscriptionsByProductIdentifier[id] // fallback in case it fails
            })
            .sorted(by: {
                guard let date1 = $0.expiresDate, let date2 = $1.expiresDate else {
                    return $0.expiresDate != nil
                }

                return date1 < date2
            })

        for subscription in subscriptions {
            let purchaseInfo: PurchaseInformation = await .from(
                transaction: subscription,
                customerInfo: customerInfo,
                purchasesProvider: purchasesProvider,
                changePlans: configuration.changePlans,
                customerCenterStoreKitUtilities: customerCenterStoreKitUtilities,
                localization: configuration.localization
            )

            activeSubscriptionPurchases.append(purchaseInfo)
        }

        if activeSubscriptionPurchases.isEmpty {
            return await loadMostRecentExpiredTransaction(customerInfo: customerInfo, configuration: configuration)
        }
        return activeSubscriptionPurchases
    }

    func fetchCustomerInfo(shouldSync: Bool) async throws -> CustomerInfo {
        if shouldSync {
            return try await purchasesProvider.syncPurchases()
        }
        return try await purchasesProvider.customerInfo(fetchPolicy: .fetchCurrent)
    }

    func loadCustomerCenterConfig() async throws -> CustomerCenterConfigData {
        let configuration = try await purchasesProvider.loadCustomerCenter()

        defer {
            self.configuration = configuration
        }

        if let url = configuration.updateAppURL {
            self.onUpdateAppClick = {
                URLUtilities.openURLIfNotAppExtension(url)
            }
        }

        return configuration
    }

    func updatePreviewConfiguration(
        _ configuration: CustomerCenterConfigData, provider: CustomerCenterPreviewProvider
    ) {
        self.configuration = configuration
        self.onUpdateAppClick = configuration.updateAppURL.map(provider.previewURLHandler(for:))
    }
}

private extension CustomerCenterConfigData {
    var updateAppURL: URL? {
        productId.flatMap { URL(string: "https://itunes.apple.com/app/id\($0)") }
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
