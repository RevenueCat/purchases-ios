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

/// Converts eligible components into a single native Close action owned by the paywall root.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
struct NativePaywallCloseButton<Content: View>: View {
    let enabled: Bool
    let accessibilityLabel: String
    let action: () async throws -> Void
    @ViewBuilder var content: () -> Content
    var availabilityChanged: ((Bool) -> Void)?
    @Environment(\.nativePaywallCloseCoordinator) private var coordinator
    @State private var identifier = UUID()

    var body: some View {
        if self.enabled, let coordinator {
            Color.clear
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
                .onAppear {
                    coordinator.register(id: self.identifier, label: self.accessibilityLabel, action: self.action)
                    self.availabilityChanged?(true)
                }
                .onDisappear {
                    coordinator.unregister(id: self.identifier)
                    self.availabilityChanged?(false)
                }
        } else {
            self.content()
        }
    }
}

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
