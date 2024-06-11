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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor class CustomerCenterViewModel: ObservableObject {

    @Published
    var hasSubscriptions: Bool = false
    @Published
    var subscriptionsAreFromApple: Bool = false
    @Published
    var state: State {
        didSet {
            if case let .error(stateError) = state {
                self.error = stateError
            }
        }
    }

    var isLoaded: Bool {
        if case .notLoaded = state {
            return false
        }
        return true
    }

    enum State {

        case notLoaded
        case success
        case error(Error)

    }

    private var error: Error?

    init() {
        self.state = .notLoaded
    }

    init(hasSubscriptions: Bool = false, areSubscriptionsFromApple: Bool = false) {
        self.hasSubscriptions = hasSubscriptions
        self.subscriptionsAreFromApple = areSubscriptionsFromApple
        self.state = .success
    }

    func loadHasSubscriptions() async {
        do {
            // swiftlint:disable:next todo
            // TODO: support non-consumables
            let customerInfo = try await Purchases.shared.customerInfo()
            let hasSubscriptions = customerInfo.activeSubscriptions.count > 0

            let subscriptionsAreFromApple = customerInfo.entitlements.active.first(where: {
                $0.value.store == .appStore || $0.value.store == .macAppStore
            }).map { entitlement in
                customerInfo.activeSubscriptions.contains(entitlement.value.productIdentifier)
            } ?? false

            self.hasSubscriptions = hasSubscriptions
            self.subscriptionsAreFromApple = subscriptionsAreFromApple
            self.state = .success
        } catch {
            self.state = .error(error)
        }
    }

}
