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
class CustomerCenterViewModel: ObservableObject {

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
            let customerInfo = try await Purchases.shared.customerInfo()
            self.hasSubscriptions = customerInfo.activeSubscriptions.count > 0
            guard let firstActiveEntitlementStore = customerInfo.entitlements.active.first?.value.store else {
                self.subscriptionsAreFromApple = false
                return
            }

            self.subscriptionsAreFromApple =
            firstActiveEntitlementStore == .appStore || firstActiveEntitlementStore == .macAppStore
        } catch {
            self.state = .error(error)
        }
    }

}
