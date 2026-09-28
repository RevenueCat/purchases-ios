//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallSideToolbarCancelButton.swift
//
//  Created by Michael S. Muegel on 9/24/26.

import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// Moves a Paywalls V2 close button into a system toolbar when the presentation supports a
    /// vertical toolbar, such as full-screen content on iPhone Duo.
    ///
    /// The close button designed in the paywall editor is replaced by a toolbar
    /// `cancellationAction`, which the system can place in the vertical bar along the side of the
    /// display. Everywhere else the paywall keeps its designed close button.
    ///
    /// This is on by default for paywalls presented with `presentPaywallIfNeeded` and
    /// `presentPaywall`, and for a `PaywallViewController` presented on its own rather than pushed
    /// or wrapped in a navigation controller. A `PaywallView` you present yourself can't know
    /// whether it's the root of a modal presentation or pushed onto your own navigation stack, so
    /// it only opts in when you apply this modifier with `true`. Apply it to the root of a modal
    /// presentation only.
    ///
    /// - Parameter enabled: Pass `false` to always keep the designed close button.
    public func movePaywallCancelButtonToSideToolbarWhenAppropriate(_ enabled: Bool = true) -> some View {
        self.environment(\.paywallSideToolbarCancelButtonSetting, enabled)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// Marks a paywall presented modally by RevenueCatUI, where hosting a navigation stack is safe.
    func paywallIsModalPresentationRoot() -> some View {
        self.environment(\.paywallIsModalPresentationRoot, true)
    }

    /// Hosts a Paywalls V2 paywall or workflow in a navigation stack whose toolbar takes over the
    /// designed close button when the presentation supports a vertical toolbar.
    func paywallSideToolbarCancelButtonHost(
        purchaseHandler: PurchaseHandler,
        onCancel: @escaping () -> Void
    ) -> some View {
        self.modifier(PaywallSideToolbarCancelButtonHost(purchaseHandler: purchaseHandler, onCancel: onCancel))
    }

    /// Reports that a close button was left out of the layout because the toolbar provides it.
    func paywallCancelButtonMovedToToolbar() -> some View {
        self.preference(key: PaywallCancelButtonMovedToToolbarKey.self, value: true)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallSideToolbarCancelButtonHost: ViewModifier {

    @ObservedObject
    var purchaseHandler: PurchaseHandler
    let onCancel: () -> Void

    @Environment(\.paywallSideToolbarCancelButtonSetting)
    private var setting

    @Environment(\.paywallIsModalPresentationRoot)
    private var isModalPresentationRoot

    func body(content: Content) -> some View {
        // Vertical toolbars need the iOS 27.1 SDK, which ships the same Swift compiler as 27.0.
        #if os(iOS) && !targetEnvironment(macCatalyst) && canImport(SwiftUI, _version: 8.0.85)
        if #available(iOS 27.1, *), SideToolbarCancelButtonStack.isSupported {
            if self.setting ?? self.isModalPresentationRoot {
                content.modifier(SideToolbarCancelButtonStack(
                    isDisabled: self.purchaseHandler.actionInProgress,
                    closeTitle: Localization.localizedBundle(
                        self.purchaseHandler.preferredLocaleOverride ?? .current
                    ).localizedString(forKey: "Close", value: nil, table: nil),
                    onCancel: self.onCancel
                ))
            } else {
                content
            }
        } else {
            content
        }
        #else
        content
        #endif
    }

}

#if os(iOS) && !targetEnvironment(macCatalyst) && canImport(SwiftUI, _version: 8.0.85)
@available(iOS 27.1, *)
private struct SideToolbarCancelButtonStack: ViewModifier {

    let isDisabled: Bool
    let closeTitle: String
    let onCancel: () -> Void

    /// The preferred vertical toolbar edge, or `nil` where vertical toolbars aren't supported.
    @Environment(\.toolbarVerticalEdge)
    private var toolbarVerticalEdge

    @State
    private var paywallHasCancelButton = false

    /// SDK releases made in parallel with iOS 27.1 can lack the vertical toolbar declarations, so
    /// check the symbol and not only the OS version.
    static var isSupported: Bool {
        if #_hasSymbol(EnvironmentValues().toolbarVerticalEdge) {
            return true
        }
        return false
    }

    func body(content: Content) -> some View {
        let movesCancelButton = self.toolbarVerticalEdge != nil
        let showsToolbar = movesCancelButton && self.paywallHasCancelButton

        // Always hosted in the stack, even while the button stays inline, so folding and rotating
        // don't replace the container and reset the paywall's state.
        NavigationStack {
            content
                .environment(\.paywallCancelButtonInToolbar, movesCancelButton)
                .onPreferenceChange(PaywallCancelButtonMovedToToolbarKey.self) { hasCancelButton in
                    self.paywallHasCancelButton = hasCancelButton
                }
                .toolbar {
                    if showsToolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(self.closeTitle, systemImage: "xmark", action: self.onCancel)
                                .disabled(self.isDisabled)
                                // Looks like the system control it is, not like the paywall
                                // content whose tint an app may set.
                                .tint(nil)
                        }
                    }
                }
                .toolbarVisibility(showsToolbar ? .automatic : .hidden, for: .navigationBar)
        }
    }

}
#endif

private struct PaywallCancelButtonMovedToToolbarKey: PreferenceKey {

    static var defaultValue: Bool { false }

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }

}

private struct PaywallSideToolbarCancelButtonSettingKey: EnvironmentKey {
    static let defaultValue: Bool? = nil
}

private struct PaywallIsModalPresentationRootKey: EnvironmentKey {
    static let defaultValue = false
}

private struct PaywallCancelButtonInToolbarKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {

    /// `nil` defers to whether RevenueCatUI presented the paywall modally.
    var paywallSideToolbarCancelButtonSetting: Bool? {
        get { self[PaywallSideToolbarCancelButtonSettingKey.self] }
        set { self[PaywallSideToolbarCancelButtonSettingKey.self] = newValue }
    }

    var paywallIsModalPresentationRoot: Bool {
        get { self[PaywallIsModalPresentationRootKey.self] }
        set { self[PaywallIsModalPresentationRootKey.self] = newValue }
    }

    /// Whether a paywall close button is shown in the toolbar instead of in the layout.
    var paywallCancelButtonInToolbar: Bool {
        get { self[PaywallCancelButtonInToolbarKey.self] }
        set { self[PaywallCancelButtonInToolbarKey.self] = newValue }
    }

}

#endif
