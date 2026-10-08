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
    var componentIdentifier: ObjectIdentifier?
    let action: () async throws -> Void
    @ViewBuilder var content: () -> Content
    var availabilityChanged: ((Bool) -> Void)?
    @Environment(\.nativePaywallCloseCoordinator) private var coordinator
    @Environment(\.nativePaywallButtonRegistrationEnabled) private var registrationEnabled
    @State private var identifier = UUID()

    var body: some View {
        if self.enabled, let coordinator {
            RegisteredNativePaywallButton(
                coordinator: coordinator, identifier: self.identifier,
                accessibilityLabel: self.accessibilityLabel, role: self.role,
                isWorkflowClose: self.isWorkflowClose, registrationEnabled: self.registrationEnabled,
                componentIdentifier: self.componentIdentifier, action: self.action,
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
    let registrationEnabled: Bool
    let componentIdentifier: ObjectIdentifier?
    let action: () async throws -> Void
    @ViewBuilder var content: () -> Content
    let availabilityChanged: ((Bool) -> Void)?

    private struct Registration: Equatable {
        let enabled: Bool
        let label: String
        let role: NativePaywallCloseCoordinator.Role
        let isWorkflowClose: Bool
    }

    private var registration: Registration {
        .init(enabled: self.registrationEnabled, label: self.accessibilityLabel,
              role: self.role, isWorkflowClose: self.isWorkflowClose)
    }

    private var showsConfiguredButton: Bool {
        self.registrationEnabled
            && self.coordinator.actions.contains(where: { $0.id == self.identifier && $0.role == self.role })
            && self.coordinator.action(for: self.role)?.id != self.identifier
            && !(self.role == .close && !self.isWorkflowClose
                 && self.coordinator.action(for: .close)?.isWorkflowClose == true)
    }

    var body: some View {
        VStack(spacing: 0) {
            if self.showsConfiguredButton {
                self.content()
            } else {
                Color.clear.frame(width: 0, height: 0).accessibilityHidden(true)
            }
        }
        .preference(
            key: NativePaywallHiddenButtonsKey.self,
            value: self.showsConfiguredButton ? [] : Set([self.componentIdentifier].compactMap { $0 })
        )
        .onAppear {
            self.updateRegistration(self.registration)
            self.availabilityChanged?(true)
        }
        .onChange(of: self.registration) { self.updateRegistration($0) }
        .onDisappear {
            self.coordinator.unregister(id: self.identifier)
            self.availabilityChanged?(false)
        }
    }

    private func updateRegistration(_ registration: Registration) {
        guard registration.enabled else {
            self.coordinator.unregister(id: self.identifier)
            return
        }
        self.coordinator.register(
            id: self.identifier, label: registration.label, role: registration.role,
            isWorkflowClose: registration.isWorkflowClose, action: self.action
        )
    }
}

struct NativePaywallHiddenButtonsKey: PreferenceKey {
    static let defaultValue: Set<ObjectIdentifier> = []

    static func reduce(value: inout Set<ObjectIdentifier>, nextValue: () -> Set<ObjectIdentifier>) {
        value.formUnion(nextValue())
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private struct NativePaywallButtonRegistrationKey: EnvironmentKey {
    static let defaultValue = true
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private struct NativePaywallCloseEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
extension EnvironmentValues {
    /// Transition header copies render native placeholders without owning toolbar actions.
    var nativePaywallButtonRegistrationEnabled: Bool {
        get { self[NativePaywallButtonRegistrationKey.self] }
        set { self[NativePaywallButtonRegistrationKey.self] = newValue }
    }

    var nativePaywallCloseEnabled: Bool {
        get { self[NativePaywallCloseEnabledKey.self] }
        set { self[NativePaywallCloseEnabledKey.self] = newValue }
    }
}

#endif
