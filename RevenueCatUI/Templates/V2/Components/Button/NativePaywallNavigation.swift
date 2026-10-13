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
    var background: BackgroundStyle?
    @Environment(\.nativePaywallNavigationContext) private var context
    @State private var detectedNavigation: Bool?

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
                    self.loadingBackground
                } else if let controller = owner.controller,
                          controller.navigationController?.isNavigationBarHidden == false {
                    content.modifier(NativePaywallCloseHost(uiKitOwner: owner))
                } else {
                    content
                }
            case .automatic:
                if let detectedNavigation = self.detectedNavigation {
                    if detectedNavigation {
                        content.modifier(NativePaywallCloseHost())
                    } else {
                        self.wrapped(content: content)
                    }
                } else {
                    self.loadingBackground.toolbar {
                        NativePaywallNavigationDetection { detected in
                            guard self.detectedNavigation == nil else { return }
                            var transaction = SwiftUI.Transaction(animation: nil)
                            transaction.disablesAnimations = true
                            withTransaction(transaction) { self.detectedNavigation = detected }
                        }
                    }
                }
            }
        }
        #else
        content
        #endif
    }

    private var loadingBackground: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .backgroundStyle(self.background, alignment: .top)
            .ignoresSafeArea()
    }

    #if os(iOS)
    @ViewBuilder private func wrapped(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                content.modifier(NativePaywallCloseHost()).toolbar(.visible, for: .navigationBar)
            }
        } else {
            NavigationView {
                content.modifier(NativePaywallCloseHost()).navigationBarHidden(false)
            }
            .navigationViewStyle(.stack)
        }
    }
    #endif
}

/// The sample/blog detector: toolbar isPresented change, with a one-shot 50 ms fallback.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private struct NativePaywallNavigationDetection: View {
    @Environment(\.isPresented) private var isPresented
    @State private var reported = false
    let detected: (Bool) -> Void

    var body: some View {
        Rectangle().frame(width: 0, height: 0)
            .onChange(of: self.isPresented) { if $0 { self.report(true) } }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { self.report(false) }
            }
    }

    private func report(_ value: Bool) {
        guard !self.reported else { return }
        self.reported = true
        self.detected(value)
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private struct NativePaywallNavigationContextKey: EnvironmentKey {
    static let defaultValue = NativePaywallNavigationContext.automatic
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private struct NativePaywallCloseCoordinatorKey: EnvironmentKey {
    static let defaultValue: NativePaywallCloseCoordinator? = nil
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
extension EnvironmentValues {
    var nativePaywallNavigationContext: NativePaywallNavigationContext {
        get { self[NativePaywallNavigationContextKey.self] }
        set { self[NativePaywallNavigationContextKey.self] = newValue }
    }

    var nativePaywallCloseCoordinator: NativePaywallCloseCoordinator? {
        get { self[NativePaywallCloseCoordinatorKey.self] }
        set { self[NativePaywallCloseCoordinatorKey.self] = newValue }
    }
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
    // Only inspect components that belong to the paywall, never a button's inline sheet destination.
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
        case .carousel(let carousel): return carousel.pages
        case .countdown(let countdown):
            return [countdown.countdownStack, countdown.endStack, countdown.fallback].compactMap { $0 }
        case .button, .text, .image, .icon, .timeline, .tabControl, .tabControlToggle,
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
