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

    /// Whether or not the Customer Center should warn the customer that they're on an outdated version of the app.
    var shouldShowAppUpdateWarnings: Bool {
        return !appIsLatestVersion && (configuration?.support.shouldWarnCustomerToUpdate ?? true)
    }

    /// Whether or not the user has any purchases (subscriptions, non-subscriptions, virtual currencies)
    var hasAnyPurchases: Bool {
        !subscriptionsSection.isEmpty
            || !nonSubscriptionsSection.isEmpty
            || !(virtualCurrencies?.balanceIsZero ?? true)
    }

    var shouldShowList: Bool {
        let virtualCurrenciesCount = virtualCurrencies.map { $0.all.count } ?? 0
        let nonVirtualCurrencyCount = subscriptionsSection.count + nonSubscriptionsSection.count

        return nonVirtualCurrencyCount + virtualCurrenciesCount > 1
    }

    var originalAppUserId: String {
        customerInfo?.originalAppUserId ?? ""
    }

    var originalPurchaseDate: Date? {
        customerInfo?.originalPurchaseDate
    }

    var shouldShowSeeAllPurchases: Bool {
        configuration?.support.displayPurchaseHistoryLink == true
        && customerInfo?.shouldShowSeeAllPurchasesButton(
            maxNonSubscriptions: RelevantPurchasesListViewModel.maxNonSubscriptionsToShow
        ) ?? false
    }

    var shouldShowVirtualCurrencies: Bool {
        configuration?.support.displayVirtualCurrencies == true
    }

    var shouldShowUserDetailsSection: Bool {
        configuration?.support.displayUserDetailsSection ?? true
    }

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

    func publisher(for purchase: PurchaseInformation?) -> AnyPublisher<PurchaseInformation?, Never> {
        $customerInfo.map { [weak self] _ -> PurchaseInformation? in
            guard let self else { return nil }
            let purchases = self.subscriptionsSection + self.nonSubscriptionsSection
            guard let purchase else { return purchases.first }
            return self.purchase(matching: purchase)
        }
        .eraseToAnyPublisher()
    }

    func purchase(matching purchase: PurchaseInformation) -> PurchaseInformation? {
        let purchases = subscriptionsSection + nonSubscriptionsSection
        return purchases.first { $0.productIdentifier == purchase.productIdentifier }
            ?? purchases.first {
                purchase.subscriptionGroupID != nil
                    && $0.subscriptionGroupID == purchase.subscriptionGroupID
                    && $0.store == purchase.store
            }
    }

    func loadScreen(shouldSync: Bool = false) async {
        if purchasesProvider is CustomerCenterPreviewProvider {
            await loadPreviewScreen(shouldSync: shouldSync)
            return
        }

        do {
            let customerInfo = shouldSync ?
            try await self.purchasesProvider.syncPurchases() :
            try await purchasesProvider.customerInfo(fetchPolicy: .fetchCurrent)

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
    func loadPreviewScreen(shouldSync: Bool = false, customerInfo: CustomerInfo? = nil) async {
        guard let provider = purchasesProvider as? CustomerCenterPreviewProvider, !Task.isCancelled else { return }
        previewLoadGeneration += 1
        let generation = previewLoadGeneration

        do {
            let resolvedCustomerInfo: CustomerInfo
            if let customerInfo {
                resolvedCustomerInfo = customerInfo
            } else {
                resolvedCustomerInfo = shouldSync ?
                try await purchasesProvider.syncPurchases() :
                try await purchasesProvider.customerInfo(fetchPolicy: .fetchCurrent)
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

private extension VirtualCurrencies {

    var balanceIsZero: Bool {
        all.map(\.value.balance).reduce(0, +) <= 0
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension CustomerCenterViewModel {

    func loadCustomerCenterConfig() async throws -> CustomerCenterConfigData {
        let configuration = try await purchasesProvider.loadCustomerCenter()

        defer {
            self.configuration = configuration
        }

        if let productId = configuration.productId,
            let url = URL(string: "https://itunes.apple.com/app/id\(productId)") {
            self.onUpdateAppClick = {
                // productId is a positive integer, so it should be safe to construct a URL from it.
                URLUtilities.openURLIfNotAppExtension(url)
            }
        }

        return configuration
    }

    func updatePreviewConfiguration(
        _ configuration: CustomerCenterConfigData, provider: CustomerCenterPreviewProvider
    ) {
        self.configuration = configuration
        self.onUpdateAppClick = nil
        if let productId = configuration.productId,
            let url = URL(string: "https://itunes.apple.com/app/id\(productId)") {
            self.onUpdateAppClick = provider.previewURLHandler(for: url)
        }
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
