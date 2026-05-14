//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import SwiftUI

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public extension View {

    func onPaywallStateChange(
        _ action: @escaping @Sendable (PaywallStateChange.Event<PaywallStateChange.Committed>) -> Void
    ) -> some View {
        self.modifier(PaywallStateChangeObserverModifier(action: action))
    }

    func onPaywallStateMutation(
        _ action: @escaping @Sendable (PaywallStateMutationProposal) -> Void
    ) -> some View {
        self.modifier(PaywallStateMutationHandlerModifier(action: action))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallStateChangeObserverModifier: ViewModifier {

    @Environment(\.paywallStateChangeObserver)
    private var existing

    let action: @Sendable (PaywallStateChange.Event<PaywallStateChange.Committed>) -> Void

    func body(content: Content) -> some View {
        content.environment(\.paywallStateChangeObserver) { change in
            self.existing?(change)
            self.action(change)
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallStateMutationHandlerModifier: ViewModifier {

    @Environment(\.paywallStateMutationHandler)
    private var existing

    let action: @Sendable (PaywallStateMutationProposal) -> Void

    func body(content: Content) -> some View {
        content.environment(\.paywallStateMutationHandler, PaywallStateMutationHandler { proposal in
            if let existing = self.existing {
                existing(proposal)
            } else {
                self.action(proposal)
            }
        })
    }

}

#endif
