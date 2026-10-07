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

#endif
