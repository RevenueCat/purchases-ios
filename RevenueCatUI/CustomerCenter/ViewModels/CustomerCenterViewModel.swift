//
//  CustomerCenterViewModel.swift
//
//
//  Created by Cesar de la Vega on 27/5/24.
//

import Foundation
import RevenueCat

@available(iOS 15.0, *)
class CustomerCenterViewModel: ObservableObject {

    @Published
    var hasSubscriptions: Bool = false
    @Published
    var areSubscriptionsFromApple: Bool = false

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

    var error: Error?

    private(set) var state: State {
        didSet {
            if case let .error(stateError) = state {
                self.error = stateError
            }
        }
    }

    init() {
        self.state = .notLoaded
    }

    init(hasSubscriptions: Bool = false, areSubscriptionsFromApple: Bool = false) {
        self.hasSubscriptions = hasSubscriptions
        self.areSubscriptionsFromApple = areSubscriptionsFromApple
        self.state = .success
    }

    func loadHasSubscriptions() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            self.hasSubscriptions = customerInfo.activeSubscriptions.count > 0
            guard let firstActiveEntitlementStore = customerInfo.entitlements.active.first?.value.store else {
                self.areSubscriptionsFromApple = false
                return
            }

            self.areSubscriptionsFromApple =
            firstActiveEntitlementStore == .appStore || firstActiveEntitlementStore == .macAppStore
        } catch {
            self.state = .error(error)
        }
    }

}
