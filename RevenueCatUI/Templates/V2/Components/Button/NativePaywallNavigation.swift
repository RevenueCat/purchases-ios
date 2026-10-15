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
}

/// Chooses the final container before mounting stateful paywall content.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
struct NativePaywallNavigationModifier: ViewModifier {
    let requested: Bool
    @Environment(\.nativePaywallNavigationContext) private var context
    @State private var detectedNavigation = false

    @ViewBuilder func body(content: Content) -> some View {
        #if os(iOS)
        if !self.requested {
            content
        } else {
            switch self.context {
            case .standalone:
                self.wrapped(content: content)
            case .automatic:
                content.modifier(NativePaywallCloseHost(enabled: self.detectedNavigation))
                    .toolbar {
                        NativePaywallNavigationDetection { self.detectedNavigation = $0 }
                            .frame(width: 0, height: 0)
                    }
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

#if os(iOS)
/// Confirm that SwiftUI mounted the toolbar in a window. Unknown hosts retain the designed button.
@available(iOS 15.0, *)
private struct NativePaywallNavigationDetection: UIViewRepresentable {
    let detected: (Bool) -> Void

    func makeUIView(context: Context) -> NativePaywallToolbarProbe {
        NativePaywallToolbarProbe(detected: self.detected)
    }

    func updateUIView(_ view: NativePaywallToolbarProbe, context: Context) {
        view.detected = self.detected
    }
}

@available(iOS 15.0, *)
private final class NativePaywallToolbarProbe: UIView {
    var detected: (Bool) -> Void

    init(detected: @escaping (Bool) -> Void) {
        self.detected = detected
        super.init(frame: .zero)
        self.isAccessibilityElement = false
    }

    required init?(coder: NSCoder) { nil }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        let available = self.window != nil
        // Publish after UIKit finishes mounting, and discard superseded attachment events.
        DispatchQueue.main.async { [weak self] in
            guard let self, (self.window != nil) == available else { return }
            self.detected(available)
        }
    }
}
#endif

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
