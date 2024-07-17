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

    typealias CustomerInfoFetcher = @Sendable () async throws -> CustomerInfo

    @Published
    private(set) var hasSubscriptions: Bool = false
    @Published
    private(set) var subscriptionsAreFromApple: Bool = false

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
    var configuration: CustomerCenterConfigData?

    var isLoaded: Bool {
        return state != .notLoaded && configuration != nil
    }

    private var customerInfoFetcher: CustomerInfoFetcher
    internal let customerCenterActionHandler: CustomerCenterActionHandler?

    private var error: Error?

    convenience init(customerCenterActionHandler: CustomerCenterActionHandler?) {
        self.init(customerCenterActionHandler: customerCenterActionHandler,
                  customerInfoFetcher: {
            guard Purchases.isConfigured else {
                throw PaywallError.purchasesNotConfigured
            }

            return try await Purchases.shared.customerInfo()
        })
    }

    init(customerCenterActionHandler: CustomerCenterActionHandler?,
         customerInfoFetcher: @escaping CustomerInfoFetcher) {
        self.state = .notLoaded
        self.customerInfoFetcher = customerInfoFetcher
        self.customerCenterActionHandler = customerCenterActionHandler
    }

    #if DEBUG

    init(hasSubscriptions: Bool = false,
         areSubscriptionsFromApple: Bool = false) {
        self.hasSubscriptions = hasSubscriptions
        self.subscriptionsAreFromApple = areSubscriptionsFromApple
        self.customerInfoFetcher = {
            guard Purchases.isConfigured else {
                throw PaywallError.purchasesNotConfigured
            }

            return try await Purchases.shared.customerInfo()
        }
        self.state = .success
        self.customerCenterActionHandler = nil
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
        self.customerCenterActionHandler?.onRestoreStarted()
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            self.customerCenterActionHandler?.onRestoreCompleted(customerInfo)
            let hasEntitlements = customerInfo.entitlements.active.count > 0
            return hasEntitlements ? .purchasesRecovered : .purchasesNotFound
        } catch {
            self.customerCenterActionHandler?.onRestoreFailed(error)
            return .purchasesNotFound
        }
    }

}

#endif
