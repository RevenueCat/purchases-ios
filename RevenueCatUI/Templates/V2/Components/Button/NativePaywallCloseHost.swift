//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import SwiftUI

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
@MainActor
final class NativePaywallCloseCoordinator: ObservableObject {
    struct CloseAction {
        let id: UUID
        let label: String
        let perform: () async throws -> Void
    }

    @Published private(set) var actions: [CloseAction] = []

    func register(id: UUID, label: String, action: @escaping () async throws -> Void) {
        guard !self.actions.contains(where: { $0.id == id }) else { return }
        self.actions.append(CloseAction(id: id, label: label, perform: action))
    }

    func unregister(id: UUID) {
        self.actions.removeAll { $0.id == id }
    }
}

/// A single host renders native Close. Components contribute their existing actions only.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
struct NativePaywallCloseHost: ViewModifier {
    #if os(iOS)
    var uiKitOwner: NativePaywallUIKitOwner?
    #endif
    @StateObject private var coordinator = NativePaywallCloseCoordinator()

    @ViewBuilder func body(content: Content) -> some View {
        #if os(iOS)
        if let owner = self.uiKitOwner {
            self.surface(content)
                .onReceive(self.coordinator.$actions) { owner.install($0.first) }
                .onDisappear { owner.removeClose() }
        } else {
            self.surface(content).toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    NativePaywallToolbarClose(coordinator: self.coordinator)
                }
            }
        }
        #else
        content
        #endif
    }

    private func surface(_ content: Content) -> some View {
        VStack(spacing: 0) { content }
            .environment(\.nativePaywallCloseCoordinator, self.coordinator)
    }

}

#if os(iOS)
@available(iOS 15.0, *)
private struct NativePaywallToolbarClose: View {
    @ObservedObject var coordinator: NativePaywallCloseCoordinator

    @ViewBuilder var body: some View {
        if let action = self.coordinator.actions.first {
            self.closeButton(action)
        }
    }

    @ViewBuilder private func closeButton(_ action: NativePaywallCloseCoordinator.CloseAction) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            Button(role: .close) { Task { try await action.perform() } }
                .accessibilityLabel(action.label)
                .accessibilityIdentifier(NativePaywallUIKitOwner.closeIdentifier)
        } else {
            self.legacyCloseButton(action)
        }
        #else
        self.legacyCloseButton(action)
        #endif
    }

    private func legacyCloseButton(_ action: NativePaywallCloseCoordinator.CloseAction) -> some View {
        Button { Task { try await action.perform() } } label: { Image(systemName: "xmark") }
            .accessibilityLabel(action.label)
            .accessibilityIdentifier(NativePaywallUIKitOwner.closeIdentifier)
    }
}
#endif

#if os(iOS)
/// Passed by PaywallViewController. Never discovers or observes SwiftUI's private controllers.
@available(iOS 15.0, *)
@MainActor
final class NativePaywallUIKitOwner: NSObject, ObservableObject {
    static let closeIdentifier = "RevenueCat.NativePaywallClose"
    weak var controller: UIViewController?
    @Published private var hasNavigation: Bool?
    var context: NativePaywallNavigationContext? {
        self.hasNavigation.map { $0 ? .uiKit(self) : .standalone }
    }
    private var item: UIBarButtonItem?
    private var action: (() async throws -> Void)?

    func prepare(controller: UIViewController) {
        self.controller = controller
        let hasNavigation = controller.navigationController != nil
        guard self.hasNavigation != hasNavigation else { return }
        self.hasNavigation = hasNavigation
    }

    func install(_ action: NativePaywallCloseCoordinator.CloseAction?) {
        self.removeClose()
        guard let controller = self.controller, let action else { return }
        self.action = action.perform
        let item = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(self.closeTapped))
        item.accessibilityIdentifier = Self.closeIdentifier
        item.accessibilityLabel = action.label
        controller.navigationItem.rightBarButtonItems = (controller.navigationItem.rightBarButtonItems ?? []) + [item]
        self.item = item
    }

    @objc private func closeTapped() {
        guard let action = self.action else { return }
        Task { try await action() }
    }

    func removeClose() {
        guard let item = self.item else { return }
        self.controller?.navigationItem.rightBarButtonItems = self.controller?.navigationItem.rightBarButtonItems?
            .filter { $0 !== item }
        self.item = nil
        self.action = nil
    }
}
#endif

#endif
