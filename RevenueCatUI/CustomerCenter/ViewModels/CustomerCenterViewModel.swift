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

    internal var customerInfo: CustomerInfo?

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

    func publisher(for purchase: PurchaseInformation?) -> AnyPublisher<PurchaseInformation, Never>? {
        guard let productIdentifier = purchase?.productIdentifier else {
            return nil
        }

        return $subscriptionsSection.combineLatest($nonSubscriptionsSection)
            .throttle(for: .seconds(0.3), scheduler: DispatchQueue.main, latest: true)
            .compactMap {
                $0.first(where: { $0.productIdentifier == productIdentifier })
                ?? $1.first(where: { $0.productIdentifier == productIdentifier })
            }
            .eraseToAnyPublisher()
    }

    func loadScreen(shouldSync: Bool = false) async {
        do {
            let customerInfo = shouldSync ?
            try await self.purchasesProvider.syncPurchases() :
            try await purchasesProvider.customerInfo(fetchPolicy: .fetchCurrent)

            let configuration = try await self.loadCustomerCenterConfig()
            try await self.loadPurchases(customerInfo: customerInfo, configuration: configuration)

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

    func loadPurchases(customerInfo: CustomerInfo, configuration: CustomerCenterConfigData) async throws {
        self.customerInfo = customerInfo

        await loadSubscriptionsSection(customerInfo: customerInfo, configuration: configuration)
        await loadNonSubscriptionsSection(customerInfo: customerInfo, configuration: configuration)
    }

    func loadNonSubscriptionsSection(customerInfo: CustomerInfo, configuration: CustomerCenterConfigData) async {
        var activeNonSubscriptionPurchases: [PurchaseInformation] = []
        for subscription in customerInfo.nonSubscriptions {

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
        self.nonSubscriptionsSection = activeNonSubscriptionPurchases
    }

    func loadMostRecentExpiredTransaction(customerInfo: CustomerInfo, configuration: CustomerCenterConfigData) async {
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
            return
        }

        let purchaseInfo: PurchaseInformation = await .from(
            transaction: inactiveSub,
            customerInfo: customerInfo,
            purchasesProvider: purchasesProvider,
            changePlans: [],
            customerCenterStoreKitUtilities: customerCenterStoreKitUtilities,
            localization: configuration.localization
        )

        self.subscriptionsSection = [purchaseInfo]
    }

    func loadSubscriptionsSection(
        customerInfo: CustomerInfo,
        configuration: CustomerCenterConfigData
    ) async {
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
            await loadMostRecentExpiredTransaction(customerInfo: customerInfo, configuration: configuration)
        } else {
            self.subscriptionsSection = activeSubscriptionPurchases
        }
    }

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
