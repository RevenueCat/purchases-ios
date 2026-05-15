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
private struct PaywallStateStoreKey: EnvironmentKey {
    static let defaultValue: PaywallStateStore? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallStateScopeKey: EnvironmentKey {
    static let defaultValue: PaywallStateScope? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallStateRenderContextKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallStateMutationHandlerKey: EnvironmentKey {
    static let defaultValue: PaywallStateMutationHandler? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallStateChangeObserverKey: EnvironmentKey {
    static let defaultValue: (@Sendable (PaywallStateChange.Event<PaywallStateChange.Committed>) -> Void)? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    var paywallStateStore: PaywallStateStore? {
        get { self[PaywallStateStoreKey.self] }
        set { self[PaywallStateStoreKey.self] = newValue }
    }

    var paywallStateScope: PaywallStateScope? {
        get { self[PaywallStateScopeKey.self] }
        set { self[PaywallStateScopeKey.self] = newValue }
    }

    var paywallStateRenderContext: String? {
        get { self[PaywallStateRenderContextKey.self] }
        set { self[PaywallStateRenderContextKey.self] = newValue }
    }

    var paywallStateMutationHandler: PaywallStateMutationHandler? {
        get { self[PaywallStateMutationHandlerKey.self] }
        set { self[PaywallStateMutationHandlerKey.self] = newValue }
    }

    var paywallStateChangeObserver: (@Sendable (PaywallStateChange.Event<PaywallStateChange.Committed>) -> Void)? {
        get { self[PaywallStateChangeObserverKey.self] }
        set { self[PaywallStateChangeObserverKey.self] = newValue }
    }

}

#endif
