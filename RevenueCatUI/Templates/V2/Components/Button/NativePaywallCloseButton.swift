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

/// Registers eligible Back and Close actions with the paywall root.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
struct NativePaywallCloseButton<Content: View>: View {
    let enabled: Bool
    let accessibilityLabel: String
    var role: NativePaywallCloseCoordinator.Role = .close
    var isWorkflowClose = false
    let action: () async throws -> Void
    @ViewBuilder var content: () -> Content
    var availabilityChanged: ((Bool) -> Void)?
    @Environment(\.nativePaywallCloseCoordinator) private var coordinator
    @State private var identifier = UUID()

    var body: some View {
        if self.enabled, let coordinator {
            RegisteredNativePaywallButton(
                coordinator: coordinator, identifier: self.identifier,
                accessibilityLabel: self.accessibilityLabel, role: self.role,
                isWorkflowClose: self.isWorkflowClose, action: self.action,
                content: self.content, availabilityChanged: self.availabilityChanged
            )
        } else {
            self.content()
        }
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private struct RegisteredNativePaywallButton<Content: View>: View {
    @ObservedObject var coordinator: NativePaywallCloseCoordinator
    let identifier: UUID
    let accessibilityLabel: String
    let role: NativePaywallCloseCoordinator.Role
    let isWorkflowClose: Bool
    let action: () async throws -> Void
    @ViewBuilder var content: () -> Content
    let availabilityChanged: ((Bool) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            if self.coordinator.actions.contains(where: { $0.id == self.identifier }),
               self.coordinator.action(for: self.role)?.id != self.identifier {
                self.content()
            } else {
                Color.clear.frame(width: 0, height: 0).accessibilityHidden(true)
            }
        }
        .onAppear {
            self.register()
            self.availabilityChanged?(true)
        }
        .onChange(of: self.role) { _ in self.register() }
        .onChange(of: self.accessibilityLabel) { _ in self.register() }
        .onChange(of: self.isWorkflowClose) { _ in self.register() }
        .onDisappear {
            self.coordinator.unregister(id: self.identifier)
            self.availabilityChanged?(false)
        }
    }

    private func register() {
        self.coordinator.register(
            id: self.identifier, label: self.accessibilityLabel, role: self.role,
            isWorkflowClose: self.isWorkflowClose, action: self.action
        )
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
