//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS)

/// Presentation owners supply known navigation. Only arbitrary embedding needs detection.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
enum NativePaywallNavigationContext {
    case automatic
    case standalone
    #if os(iOS)
    case uiKit(NativePaywallUIKitOwner)
    #endif
}

/// Chooses the final container before mounting stateful paywall content.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
struct NativePaywallNavigationModifier: ViewModifier {
    let requested: Bool
    @Environment(\.nativePaywallNavigationContext) private var context

    @ViewBuilder func body(content: Content) -> some View {
        #if os(iOS)
        if !self.requested {
            content
        } else {
            switch self.context {
            case .standalone:
                self.wrapped(content: content)
            case .uiKit(let owner):
                if owner.context == nil {
                    Color.clear
                } else if let controller = owner.controller,
                          controller.navigationController?.isNavigationBarHidden == false {
                    content.modifier(NativePaywallCloseHost(uiKitOwner: owner))
                } else {
                    content
                }
            case .automatic:
                content.modifier(NativePaywallCloseHost(detectNavigation: true))
            }
        }
        #else
        content
        #endif
    }

    #if os(iOS)
    @ViewBuilder private func wrapped(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                content.modifier(NativePaywallCloseHost(ownsNavigation: true))
            }
        } else {
            NavigationView {
                content.modifier(NativePaywallCloseHost(ownsNavigation: true))
            }
            .navigationViewStyle(.stack)
        }
    }
    #endif
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private struct NativePaywallNavigationContextKey: EnvironmentKey {
    static let defaultValue = NativePaywallNavigationContext.automatic
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
extension EnvironmentValues {
    var nativePaywallNavigationContext: NativePaywallNavigationContext {
        get { self[NativePaywallNavigationContextKey.self] }
        set { self[NativePaywallNavigationContextKey.self] = newValue }
    }

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
extension NativePaywallNavigationModifier {
    init(
        paywallComponents: Offering.PaywallComponents,
        workflowContext: WorkflowContext?
    ) {
        // Workflow integration is added in the final layer; retain its existing presentation.
        guard workflowContext == nil else {
            self.init(requested: false)
            return
        }
        self.init(requested: paywallComponents.data.componentsConfig.base.requestsNativeClose)
    }
}

#endif
