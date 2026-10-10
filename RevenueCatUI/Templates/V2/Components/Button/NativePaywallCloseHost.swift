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
    enum Role: Equatable { case back, close }

    struct CloseAction {
        let id: UUID
        let label: String
        let perform: () async throws -> Void
        var role: Role = .close
        var isWorkflowClose = false
        var pageID: UUID?
    }

    @Published private(set) var actions: [CloseAction] = []
    private var registrations: [CloseAction] = []
    private var activePageID: UUID?

    func activatePage(_ pageID: UUID?) {
        guard self.activePageID != pageID else { return }
        self.activePageID = pageID
        self.updateActions()
    }

    private func updateActions() {
        self.actions = self.registrations.filter { $0.pageID == self.activePageID }
    }

    func register(
        id: UUID,
        label: String,
        role: Role = .close,
        isWorkflowClose: Bool = false,
        pageID: UUID? = nil,
        action: @escaping () async throws -> Void
    ) {
        let value = CloseAction(
            id: id, label: label, perform: action, role: role, isWorkflowClose: isWorkflowClose, pageID: pageID
        )
        if let index = self.registrations.firstIndex(where: { $0.id == id }) {
            guard self.registrations[index].role != role || self.registrations[index].label != label
                || self.registrations[index].isWorkflowClose != isWorkflowClose
                || self.registrations[index].pageID != pageID else { return }
            self.registrations[index] = value
        } else {
            self.registrations.append(value)
        }
        self.updateActions()
    }

    func action(for role: Role) -> CloseAction? {
        if role == .close, let close = self.actions.first(where: { $0.role == .close && $0.isWorkflowClose }) {
            return close
        }
        return self.actions.first { $0.role == role }
    }

    func unregister(id: UUID) {
        self.registrations.removeAll { $0.id == id }
        self.updateActions()
    }
}

/// A single host renders native Back and Close. Components contribute their existing actions only.
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
                .onReceive(self.coordinator.$actions) { owner.install($0) }
                .onDisappear { owner.removeClose() }
        } else {
            self.surface(content)
                .navigationBarBackButtonHidden(self.coordinator.action(for: .back) != nil)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        NativePaywallToolbarClose(coordinator: self.coordinator, primary: true)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NativePaywallToolbarClose(coordinator: self.coordinator, primary: false)
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
    let primary: Bool

    @ViewBuilder var body: some View {
        if self.primary {
            if let back = self.coordinator.action(for: .back) {
                Button { Task { try await back.perform() } } label: {
                    Image(systemName: "chevron.backward")
                }
                .accessibilityLabel(back.label)
                .accessibilityIdentifier(NativePaywallUIKitOwner.backIdentifier)
            }
        } else if let close = self.coordinator.action(for: .close) {
            self.closeButton(close)
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
    static let backIdentifier = "RevenueCat.NativePaywallBack"
    weak var controller: UIViewController?
    @Published private var hasNavigation: Bool?
    var context: NativePaywallNavigationContext? {
        self.hasNavigation.map { $0 ? .uiKit(self) : .standalone }
    }
    private var items: [UIBarButtonItem] = []
    private var backAction: (() async throws -> Void)?
    private var closeAction: (() async throws -> Void)?

    func prepare(controller: UIViewController) {
        self.controller = controller
        let hasNavigation = controller.navigationController != nil
        guard self.hasNavigation != hasNavigation else { return }
        self.hasNavigation = hasNavigation
    }

    func install(_ action: NativePaywallCloseCoordinator.CloseAction?) {
        self.install(action.map { [$0] } ?? [])
    }

    func install(_ actions: [NativePaywallCloseCoordinator.CloseAction]) {
        self.removeClose()
        guard let controller = self.controller else { return }
        let back = actions.first { $0.role == .back }
        let close = actions.first { $0.role == .close && $0.isWorkflowClose }
            ?? actions.first { $0.role == .close }
        if let back {
            self.backAction = back.perform
            let item = UIBarButtonItem(
                image: UIImage(systemName: "chevron.backward"), style: .plain,
                target: self, action: #selector(self.backTapped)
            )
            item.accessibilityIdentifier = Self.backIdentifier
            item.accessibilityLabel = back.label
            controller.navigationItem.leftBarButtonItems =
                (controller.navigationItem.leftBarButtonItems ?? []) + [item]
            self.items.append(item)
        }
        if let close {
            self.closeAction = close.perform
            let item = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(self.closeTapped))
            item.accessibilityIdentifier = Self.closeIdentifier
            item.accessibilityLabel = close.label
            controller.navigationItem.rightBarButtonItems =
                (controller.navigationItem.rightBarButtonItems ?? []) + [item]
            self.items.append(item)
        }
    }

    @objc private func backTapped() {
        guard let action = self.backAction else { return }
        Task { try await action() }
    }

    @objc private func closeTapped() {
        guard let action = self.closeAction else { return }
        Task { try await action() }
    }

    func removeClose() {
        self.controller?.navigationItem.leftBarButtonItems = self.controller?.navigationItem.leftBarButtonItems?
            .filter { item in !self.items.contains { $0 === item } }
        self.controller?.navigationItem.rightBarButtonItems = self.controller?.navigationItem.rightBarButtonItems?
            .filter { item in !self.items.contains { $0 === item } }
        self.items = []
        self.backAction = nil
        self.closeAction = nil
    }

}
#endif

#endif
