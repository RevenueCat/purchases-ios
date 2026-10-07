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

/// Replaces only opted-in close buttons. Other platforms and missing/hidden navigation bars
/// retain the configured component until native placement is available.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
struct NativePaywallCloseButton<Content: View>: View {
    let enabled: Bool
    let accessibilityLabel: String
    let action: () async throws -> Void
    @ViewBuilder var content: () -> Content
    var availabilityChanged: ((Bool) -> Void)?
    @State private var hasNativeClose = false

    var body: some View {
        #if os(iOS)
        if self.enabled {
            VStack(spacing: 0) {
                if self.hasNativeClose {
                    Color.clear.frame(width: 0, height: 0).accessibilityHidden(true)
                } else {
                    self.content()
                }
            }
            .background {
                NativePaywallCloseBridge(
                    accessibilityLabel: self.accessibilityLabel,
                    action: { Task { try await self.action() } },
                    availabilityChanged: { self.hasNativeClose = $0 }
                )
                .frame(width: 0, height: 0)
            }
            .onChange(of: self.hasNativeClose) { self.availabilityChanged?($0) }
        } else {
            self.content()
        }
        #else
        self.content()
        #endif
    }
}

/// Resolves navigation while only the paywall background is mounted. The paywall's stateful
/// content is then inserted once, in its final container, without moving it between hierarchies.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
struct NativePaywallNavigationModifier: ViewModifier {
    let requested: Bool
    var background: BackgroundStyle?
    #if os(iOS)
    @State private var hasNavigation: Bool?

    @ViewBuilder func body(content: Content) -> some View {
        if !self.requested {
            content
        } else if let hasNavigation = self.hasNavigation {
            if hasNavigation {
                content
            } else {
                self.wrapped(content: content)
            }
        } else {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .backgroundStyle(self.background, alignment: .top)
                .ignoresSafeArea()
                .background {
                    NativePaywallNavigationObserver { hasNavigation in
                        guard self.hasNavigation == nil else { return }
                        var transaction = SwiftUI.Transaction(animation: nil)
                        transaction.disablesAnimations = true
                        withTransaction(transaction) { self.hasNavigation = hasNavigation }
                    }
                    .frame(width: 0, height: 0)
                }
        }
    }

    @ViewBuilder private func wrapped(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                content
                    .toolbar(.visible, for: .navigationBar)
            }
        } else {
            NavigationView {
                content
                    .navigationBarHidden(false)
            }
            .navigationViewStyle(.stack)
        }
    }
    #else
    func body(content: Content) -> some View { content }
    #endif
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
extension NativePaywallNavigationModifier {
    init(
        paywallComponents: Offering.PaywallComponents,
        workflowContext: WorkflowContext?,
        preferredLocale: Locale
    ) {
        let data = paywallComponents.data
        let workflow = workflowContext?.workflow
        let initialStep = workflow.flatMap { $0.steps[$0.initialStepId] }
        let initialScreen = initialStep?.screenId.flatMap { workflow?.screens[$0] }
        let config = initialScreen?.componentsConfig.base ?? data.componentsConfig.base
        let configs = workflow.map { $0.screens.values.map { $0.componentsConfig.base } } ?? [config]
        let requested = configs.contains { $0.requestsNativeClose }
        guard requested else {
            self.init(requested: false)
            return
        }
        let localization = PaywallsV2View.chooseLocalization(
            componentsLocalizations: initialScreen?.componentsLocalizations ?? data.componentsLocalizations,
            preferredLocales: [preferredLocale],
            defaultLocale: initialScreen?.defaultLocale ?? data.defaultLocale
        )
        let uiConfigProvider = UIConfigProvider(uiConfig: workflowContext?.uiConfig ?? paywallComponents.uiConfig)
        self.init(
            requested: true,
            background: config.background.asDisplayable(
                uiConfigProvider: uiConfigProvider, localizationProvider: localization
            )
        )
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
extension PaywallComponentsData.PaywallComponentsConfig {
    var requestsNativeClose: Bool {
        self.stack.requestsNativeClose
            || self.header?.stack.requestsNativeClose == true
            || self.stickyFooter?.stack.requestsNativeClose == true
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension PaywallComponent.StackComponent {
    var requestsNativeClose: Bool {
        self.visible != false && self.components.contains { $0.requestsNativeClose }
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension PaywallComponent {
    // Only inspect components that belong to the paywall, never a button's inline sheet destination.
    var requestsNativeClose: Bool {
        switch self {
        case .button(let button):
            guard button.visible != false else { return false }
            if button.useNativeIfPossible {
                if button.isCloseWorkflowAction { return true }
                if case .navigateBack = button.action { return true }
            }
            return button.stack.requestsNativeClose
        case .stack(let stack): return stack.requestsNativeClose
        case .package(let package): return package.stack.requestsNativeClose
        case .purchaseButton(let button): return button.stack.requestsNativeClose
        case .stickyFooter(let footer): return footer.stack.requestsNativeClose
        case .tabs(let tabs):
            return tabs.control.stack.requestsNativeClose || tabs.tabs.contains { $0.stack.requestsNativeClose }
        case .tabControlButton(let button): return button.stack.requestsNativeClose
        case .carousel(let carousel): return carousel.pages.contains { $0.requestsNativeClose }
        case .countdown(let countdown):
            return countdown.countdownStack.requestsNativeClose
                || countdown.endStack?.requestsNativeClose == true
                || countdown.fallback?.requestsNativeClose == true
        case .text, .image, .icon, .timeline, .tabControl, .tabControlToggle, .video, .webView, .fallbackHeader:
            return false
        }
    }
}

#if os(iOS)
@available(iOS 15.0, *)
private struct NativePaywallNavigationObserver: UIViewControllerRepresentable {
    let changed: (Bool) -> Void

    func makeUIViewController(context: Context) -> NativePaywallCloseBridge.NavigationObserver {
        NativePaywallCloseBridge.NavigationObserver()
    }

    func updateUIViewController(_ controller: NativePaywallCloseBridge.NavigationObserver, context: Context) {
        controller.changed = { [weak controller] in
            guard let controller, controller.viewIfLoaded?.window != nil else { return }
            self.changed(controller.navigationController != nil)
        }
        controller.scheduleUpdate()
    }

    static func dismantleUIViewController(
        _ controller: NativePaywallCloseBridge.NavigationObserver, coordinator: ()
    ) {
        controller.changed = nil
    }
}
#endif

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private struct NativePaywallCloseEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
extension EnvironmentValues {
    var nativePaywallCloseEnabled: Bool {
        get { self[NativePaywallCloseEnabledKey.self] }
        set { self[NativePaywallCloseEnabledKey.self] = newValue }
    }
}

#endif
