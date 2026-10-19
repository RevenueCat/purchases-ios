//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Combine
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
    var interactionEnabled = true
    let action: () async throws -> Void
    @ViewBuilder var content: () -> Content
    var availabilityChanged: ((Bool) -> Void)?
    @Environment(\.nativePaywallCloseCoordinator) private var coordinator
    @Environment(\.nativePaywallButtonRegistrationEnabled) private var registrationEnabled
    @Environment(\.nativePaywallPageID) private var pageID
    @Environment(\.nativePaywallControlsPresented) private var controlsPresented
    @State private var identifier = UUID()
    @Environment(\.nativePaywallLayoutButtons) private var layoutButtons
    @Environment(\.nativePaywallRegistrationOnly) private var registrationOnly

    var body: some View {
        if self.enabled, let coordinator {
            if self.registrationOnly || self.componentIdentifier.map({ self.layoutButtons.contains($0) }) != true {
                RegisteredNativePaywallButton(
                    coordinator: coordinator, identifier: self.identifier,
                    accessibilityLabel: self.accessibilityLabel, role: self.role,
                    isWorkflowClose: self.isWorkflowClose, registrationEnabled: self.registrationEnabled,
                    interactionEnabled: self.interactionEnabled,
                    componentIdentifier: self.componentIdentifier, pageID: self.pageID, action: self.action,
                    availabilityChanged: self.availabilityChanged
                )
            }
            if !self.controlsPresented && !self.registrationOnly { self.content() }
        } else if !self.registrationOnly {
            self.content()
        }
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private struct RegisteredNativePaywallButton: View {
    @ObservedObject var coordinator: NativePaywallCloseCoordinator
    let identifier: UUID
    let accessibilityLabel: String
    let role: NativePaywallCloseCoordinator.Role
    let isWorkflowClose: Bool
    let registrationEnabled: Bool
    let interactionEnabled: Bool
    @Environment(\.nativePaywallControlsPresented) private var controlsPresented
    @Environment(\.carouselState) private var carouselState
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.nativePaywallInteractionEnabled) private var workflowInteractionEnabled
    let componentIdentifier: ObjectIdentifier?
    let pageID: UUID?
    let action: () async throws -> Void
    let availabilityChanged: ((Bool) -> Void)?

    private struct Registration: Equatable {
        let enabled: Bool
        let isEnabled: Bool
        let label: String
        let role: NativePaywallCloseCoordinator.Role
        let isWorkflowClose: Bool
        let pageID: UUID?
    }

    private var registration: Registration {
        .init(enabled: self.registrationEnabled && (self.carouselState?.distanceFromActive ?? 0) == 0,
              isEnabled: self.isEnabled && self.interactionEnabled && self.workflowInteractionEnabled,
              label: self.accessibilityLabel,
              role: self.role, isWorkflowClose: self.isWorkflowClose, pageID: self.pageID)
    }

    var body: some View {
        // Every opted-in component delegates its role to the shared toolbar. Only the
        // coordinator selects which callback owns that slot; duplicates stay out of content.
        Color.clear.frame(width: 0, height: 0).accessibilityHidden(true)
        .preference(
            key: NativePaywallHiddenButtonsKey.self,
            value: self.controlsPresented ? Set([self.componentIdentifier].compactMap { $0 }) : []
        )
        .preference(key: NativePaywallHeaderContentKey.self, value: .init(hasNativeButtons: self.controlsPresented))
        .onAppear {
            self.updateRegistration(self.registration)
            self.availabilityChanged?(self.controlsPresented)
        }
        .onChangeOf(self.registration) { self.updateRegistration($0) }
        .onChangeOf(self.controlsPresented) { self.availabilityChanged?($0) }
        // Refresh closures without publishing observable state during a body update.
        .onReceive(Just(self.action)) { self.coordinator.refreshAction(id: self.identifier, action: $0) }
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
            isWorkflowClose: registration.isWorkflowClose, pageID: registration.pageID,
            isEnabled: registration.isEnabled, action: self.action
        )
    }
}

struct NativePaywallHiddenButtonsKey: PreferenceKey {
    static let defaultValue: Set<ObjectIdentifier> = []

    static func reduce(value: inout Set<ObjectIdentifier>, nextValue: () -> Set<ObjectIdentifier>) {
        value.formUnion(nextValue())
    }
}

struct NativePaywallInvisibleButtonsKey: PreferenceKey {
    static let defaultValue: Set<ObjectIdentifier> = []

    static func reduce(value: inout Set<ObjectIdentifier>, nextValue: () -> Set<ObjectIdentifier>) {
        value.formUnion(nextValue())
    }
}

private struct NativePaywallInvisibleLayoutButtonsKey: EnvironmentKey {
    static let defaultValue: Set<ObjectIdentifier> = []
}

private struct NativePaywallControlsPresentedKey: EnvironmentKey {
    static let defaultValue = true
}

private struct NativePaywallHeaderCollapsedKey: EnvironmentKey {
    static let defaultValue = false
}

private struct NativePaywallLayoutButtonsKey: EnvironmentKey {
    static let defaultValue: Set<ObjectIdentifier> = []
}

private struct NativePaywallHiddenLayoutButtonsKey: EnvironmentKey {
    static let defaultValue: Set<ObjectIdentifier> = []
}

private struct NativePaywallRegistrationOnlyKey: EnvironmentKey {
    static let defaultValue = false
}

private struct NativePaywallPageIDKey: EnvironmentKey {
    static let defaultValue: UUID? = nil
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private struct NativePaywallButtonRegistrationKey: EnvironmentKey {
    static let defaultValue = true
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private struct NativePaywallCloseEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

private struct NativePaywallInteractionEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
extension EnvironmentValues {
    var nativePaywallControlsPresented: Bool {
        get { self[NativePaywallControlsPresentedKey.self] }
        set { self[NativePaywallControlsPresentedKey.self] = newValue }
    }

    var nativePaywallHeaderCollapsed: Bool {
        get { self[NativePaywallHeaderCollapsedKey.self] }
        set { self[NativePaywallHeaderCollapsedKey.self] = newValue }
    }

    var nativePaywallLayoutButtons: Set<ObjectIdentifier> {
        get { self[NativePaywallLayoutButtonsKey.self] }
        set { self[NativePaywallLayoutButtonsKey.self] = newValue }
    }
    var nativePaywallHiddenLayoutButtons: Set<ObjectIdentifier> {
        get { self[NativePaywallHiddenLayoutButtonsKey.self] }
        set { self[NativePaywallHiddenLayoutButtonsKey.self] = newValue }
    }

    var nativePaywallInvisibleLayoutButtons: Set<ObjectIdentifier> {
        get { self[NativePaywallInvisibleLayoutButtonsKey.self] }
        set { self[NativePaywallInvisibleLayoutButtonsKey.self] = newValue }
    }
    var nativePaywallRegistrationOnly: Bool {
        get { self[NativePaywallRegistrationOnlyKey.self] }
        set { self[NativePaywallRegistrationOnlyKey.self] = newValue }
    }

    var nativePaywallInteractionEnabled: Bool {
        get { self[NativePaywallInteractionEnabledKey.self] }
        set { self[NativePaywallInteractionEnabledKey.self] = newValue }
    }

    var nativePaywallPageID: UUID? {
        get { self[NativePaywallPageIDKey.self] }
        set { self[NativePaywallPageIDKey.self] = newValue }
    }

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

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private struct NativePaywallCloseCoordinatorKey: EnvironmentKey {
    static let defaultValue: NativePaywallCloseCoordinator? = nil
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
extension EnvironmentValues {
    var nativePaywallCloseCoordinator: NativePaywallCloseCoordinator? {
        get { self[NativePaywallCloseCoordinatorKey.self] }
        set { self[NativePaywallCloseCoordinatorKey.self] = newValue }
    }
}

#if os(iOS)
/// Observes attachment from an actual native control without allocating a separate toolbar item.
@available(iOS 15.0, *)
struct NativePaywallNavigationDetection: UIViewRepresentable {
    let detected: (UUID, Bool) -> Void
    func makeUIView(context: Context) -> NativePaywallToolbarProbe {
        NativePaywallToolbarProbe(detected: self.detected)
    }
    func updateUIView(_ view: NativePaywallToolbarProbe, context: Context) { view.detected = self.detected }
}

@available(iOS 15.0, *)
final class NativePaywallToolbarProbe: UIView {
    private let identifier = UUID()
    var detected: (UUID, Bool) -> Void
    init(detected: @escaping (UUID, Bool) -> Void) {
        self.detected = detected
        super.init(frame: .zero)
        self.isAccessibilityElement = false
    }
    required init?(coder: NSCoder) { nil }
    override func didMoveToWindow() {
        super.didMoveToWindow()
        let available = self.window != nil
        let identifier = self.identifier
        let detected = self.detected
        DispatchQueue.main.async { [weak self] in
            // Detachment must clear the ID even when the removed view was already deallocated.
            guard !available || self?.window != nil else { return }
            detected(identifier, available)
        }
    }
}
#endif

#endif
