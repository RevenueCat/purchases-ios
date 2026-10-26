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
        guard canBeVisible else { return false }
        let badges = [self.badge].compactMap { $0 } + (self.overrides?.compactMap {
            $0.canApply(discardRules: discardRules) ? $0.properties.badge : nil
        } ?? [])
        return self.components.contains { $0.requestsNativeClose(discardRules: discardRules) }
            || badges.contains { $0.stack.requestsNativeClose(discardRules: discardRules) }
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension PaywallComponent {
    // Only inspect components that belong to the paywall, never a button's inline sheet destination.
    func requestsNativeClose(discardRules: Bool) -> Bool {
        if case .button(let button) = self {
            let overrides = button.overrides?.filter { $0.canApply(discardRules: discardRules) } ?? []
            guard button.visible != false || overrides.contains(where: { $0.properties.visible == true }) else {
                return false
            }
            let canUseNative = button.useNativeIfPossible
                || overrides.contains { $0.properties.useNativeIfPossible == true }
            if canUseNative {
                if button.isCloseWorkflowAction { return true }
                if case .navigateBack = button.action { return true }
            }
        }
        return self.childStacks(includeSheetDestinations: false).contains {
            $0.requestsNativeClose(discardRules: discardRules)
        }
    }
}

#endif
