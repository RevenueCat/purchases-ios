//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
extension PaywallComponentsData.PaywallComponentsConfig {
    var requestsNativeClose: Bool {
        let discardRules = self.stack.containsUnsupportedConditions()
            || self.header?.stack.containsUnsupportedConditions() == true
            || self.stickyFooter?.stack.containsUnsupportedConditions() == true
        return self.stack.requestsNativeClose(discardRules: discardRules)
            || self.header?.stack.requestsNativeClose(discardRules: discardRules) == true
            || self.stickyFooter?.stack.requestsNativeClose(discardRules: discardRules) == true
    }
}

/// Preflight considers supported rules that can reveal a candidate later in this presentation.
/// Runtime resolution still decides visibility and opt-in for the current condition context.
private extension PaywallComponent.ComponentOverride {
    func canApply(discardRules: Bool) -> Bool {
        self.extendedConditions.allSatisfy {
            $0 != .unsupported && $0 != .multipleIntroOffers && (!discardRules || !$0.isRule)
        }
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension PaywallComponent.StackComponent {
    func requestsNativeClose(discardRules: Bool) -> Bool {
        let canBeVisible = self.visible != false || self.overrides?.contains {
            $0.canApply(discardRules: discardRules) && $0.properties.visible == true
        } == true
        return canBeVisible && self.components.contains { $0.requestsNativeClose(discardRules: discardRules) }
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension PaywallComponent {
    // Carousel pages and inline sheet destinations keep their own embedded controls.
    func requestsNativeClose(discardRules: Bool) -> Bool {
        if case .button(let button) = self {
            return button.requestsNativeClose(discardRules: discardRules)
        }
        return self.nativeNavigationStacks.contains { $0.requestsNativeClose(discardRules: discardRules) }
    }

    var nativeNavigationStacks: [PaywallComponent.StackComponent] {
        switch self {
        case .stack(let stack): return [stack]
        case .package(let package): return [package.stack]
        case .purchaseButton(let button): return [button.stack]
        case .stickyFooter(let footer): return [footer.stack]
        case .tabs(let tabs): return [tabs.control.stack] + tabs.tabs.map { $0.stack }
        case .tabControlButton(let button): return [button.stack]
        case .countdown(let countdown):
            return [countdown.countdownStack, countdown.endStack, countdown.fallback].compactMap { $0 }
        case .button, .carousel, .text, .image, .icon, .timeline, .tabControl, .tabControlToggle,
             .video, .webView, .fallbackHeader:
            return []
        @unknown default:
            return []
        }
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension PaywallComponent.ButtonComponent {
    func requestsNativeClose(discardRules: Bool) -> Bool {
        let overrides = self.overrides?.filter { $0.canApply(discardRules: discardRules) } ?? []
        guard self.visible != false || overrides.contains(where: { $0.properties.visible == true }) else {
            return false
        }
        let canUseNative = self.useNativeIfPossible
            || overrides.contains { $0.properties.useNativeIfPossible == true }
        if canUseNative {
            if self.isCloseWorkflowAction { return true }
            if case .navigateBack = self.action { return true }
        }
        return self.stack.requestsNativeClose(discardRules: discardRules)
    }
}

#endif
