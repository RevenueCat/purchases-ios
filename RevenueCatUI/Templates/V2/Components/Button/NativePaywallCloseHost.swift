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

#if os(iOS)
@MainActor
private func performNativePaywallAction(_ action: () async throws -> Void) async {
    do {
        try await action()
    } catch {
        Logger.error(Strings.paywall_native_navigation_action_failed(error))
    }
}

#endif

/// A single host renders native Back and Close. Components contribute their existing actions only.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
struct NativePaywallCloseHost: ViewModifier {
    static let closeIdentifier = "RevenueCat.NativePaywallClose"
    static let backIdentifier = "RevenueCat.NativePaywallBack"
    var enabled = true
    var ownsNavigation = false
    var detectNavigation = false
    @State private var mountedControls: Set<UUID> = []
    #if os(iOS)
    var uiKitOwner: NativePaywallUIKitOwner?
    #endif
    @StateObject private var coordinator = NativePaywallCloseCoordinator()

    @ViewBuilder func body(content: Content) -> some View {
        #if os(iOS)
        if let owner = self.uiKitOwner {
            self.surface(content)
                .onAppear { owner.activate(self.coordinator) }
                .onReceive(self.coordinator.$actions) { owner.install($0, from: self.coordinator) }
                .onDisappear { owner.removeClose(from: self.coordinator) }
        } else {
            self.nativeNavigation(content)
        }
        #else
        content
        #endif
    }

    #if os(iOS)
    @ViewBuilder private func nativeNavigation(_ content: Content) -> some View {
        // Both native Back and native Close replace the caller's automatic Back button.
        let view = self.surface(content)
            .navigationBarBackButtonHidden(self.enabled && !self.coordinator.actions.isEmpty)
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            view.toolbar {
                self.backToolbarItem
                if self.detectNavigation, self.enabled, self.coordinator.action(for: .close) != nil {
                    ToolbarSpacer(.fixed, placement: .navigationBarTrailing)
                }
                self.closeToolbarItem
            }
        } else {
            view.toolbar { self.backToolbarItem; self.closeToolbarItem }
        }
        #else
        view.toolbar { self.backToolbarItem; self.closeToolbarItem }
        #endif
    }

    private var backToolbarItem: some ToolbarContent {
        ToolbarItemGroup(placement: .cancellationAction) {
            if self.enabled, self.coordinator.action(for: .back) != nil {
                NativePaywallToolbarClose(
                    coordinator: self.coordinator, primary: true, detectNavigation: self.detectNavigation,
                    probe: self.navigationProbe
                )
            }
        }
    }

    private var closeToolbarItem: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if self.enabled, self.coordinator.action(for: .close) != nil {
                NativePaywallToolbarClose(
                    coordinator: self.coordinator, primary: false, detectNavigation: self.detectNavigation,
                    probe: self.navigationProbe
                )
            }
        }
    }

    @ViewBuilder private var navigationProbe: some View {
        if self.detectNavigation {
            NativePaywallNavigationDetection { identifier, available in
                if available {
                    self.mountedControls.insert(identifier)
                } else {
                    self.mountedControls.remove(identifier)
                }
            }.frame(width: 0, height: 0)
        }
    }

    @ViewBuilder private func surface(_ content: Content) -> some View {
        let view = VStack(spacing: 0) { content }
            .environment(\.nativePaywallCloseCoordinator, self.enabled ? self.coordinator : nil)
            .environment(\.nativePaywallControlsPresented, !self.detectNavigation || !self.mountedControls.isEmpty)
        if self.ownsNavigation {
            if #available(iOS 16.0, *) {
                view.toolbar(self.coordinator.actions.isEmpty ? .hidden : .visible, for: .navigationBar)
            } else {
                view.navigationBarHidden(self.coordinator.actions.isEmpty)
            }
        } else {
            view
        }
    }
    #endif

}

#if os(iOS)
@available(iOS 15.0, *)
private struct NativePaywallToolbarClose<Probe: View>: View {
    @ObservedObject var coordinator: NativePaywallCloseCoordinator
    let primary: Bool
    let detectNavigation: Bool
    let probe: Probe

    @ViewBuilder var body: some View {
        if self.primary {
            if let back = self.coordinator.action(for: .back) {
                Button {
                    self.performAction(back.id)
                } label: {
                    Image(systemName: "chevron.backward").background { self.probe }
                }
                .accessibilityLabel(back.label)
                .accessibilityIdentifier(NativePaywallCloseHost.backIdentifier)
                .disabled(!back.isEnabled)
            }
        } else if let close = self.coordinator.action(for: .close) {
            self.closeButton(close).disabled(!close.isEnabled)
        }
    }

    @ViewBuilder private func closeButton(_ action: NativePaywallCloseCoordinator.CloseAction) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            Group {
                if self.detectNavigation {
                    Button(role: .close) {
                        self.performAction(action.id)
                    } label: {
                        Image(systemName: "xmark").background { self.probe }
                    }
                } else {
                    Button(role: .close) {
                        self.performAction(action.id)
                    }
                }
            }
            .accessibilityLabel(action.label)
            .accessibilityIdentifier(NativePaywallCloseHost.closeIdentifier)
        } else {
            self.legacyCloseButton(action)
        }
        #else
        self.legacyCloseButton(action)
        #endif
    }

    private func performAction(_ id: UUID) {
        Task { await performNativePaywallAction { try await self.coordinator.performAction(id: id) } }
    }

    private func legacyCloseButton(_ action: NativePaywallCloseCoordinator.CloseAction) -> some View {
        Button {
            self.performAction(action.id)
        } label: { Image(systemName: "xmark").background { self.probe } }
            .accessibilityLabel(action.label)
            .accessibilityIdentifier(NativePaywallCloseHost.closeIdentifier)
    }
}
#endif

#if os(iOS)
/// Passed by PaywallViewController. Never discovers or observes SwiftUI's private controllers.
@available(iOS 15.0, *)
@MainActor
final class NativePaywallUIKitOwner: NSObject, ObservableObject {
    static let closeIdentifier = NativePaywallCloseHost.closeIdentifier
    static let backIdentifier = NativePaywallCloseHost.backIdentifier
    weak var controller: UIViewController?
    @Published private var isStandalone: Bool?
    var context: NativePaywallNavigationContext? {
        self.isStandalone.map { $0 ? .standalone : .uiKit(self) }
    }
    private var items: [UIBarButtonItem] = []
    private var originalSupplementBackButton: Bool?
    private var originalHidesBackButton: Bool?
    private weak var activeSource: NativePaywallCloseCoordinator?
    private var backAction: NativePaywallCloseCoordinator.CloseAction?
    private var closeAction: NativePaywallCloseCoordinator.CloseAction?

    func prepare(controller: UIViewController) {
        self.controller = controller
        let isStandalone = controller.parent == nil && controller.navigationController == nil
        guard self.isStandalone != isStandalone else { return }
        self.isStandalone = isStandalone
    }

    func activate(_ source: NativePaywallCloseCoordinator) {
        self.activeSource = source
        self.install(source.actions)
    }

    func install(_ actions: [NativePaywallCloseCoordinator.CloseAction], from source: NativePaywallCloseCoordinator) {
        guard self.activeSource === source else { return }
        self.install(actions)
    }

    func removeClose(from source: NativePaywallCloseCoordinator) {
        guard self.activeSource === source else { return }
        self.activeSource = nil
        self.removeClose()
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
        if back != nil || close != nil {
            self.originalHidesBackButton = controller.navigationItem.hidesBackButton
            controller.navigationItem.hidesBackButton = true
        }
        if let back {
            self.originalSupplementBackButton = controller.navigationItem.leftItemsSupplementBackButton
            controller.navigationItem.leftItemsSupplementBackButton = false
            self.backAction = back
            let item = UIBarButtonItem(
                image: UIImage(systemName: "chevron.backward"), style: .plain,
                target: self, action: #selector(self.backTapped)
            )
            item.accessibilityIdentifier = Self.backIdentifier
            item.accessibilityLabel = back.label
            item.isEnabled = back.isEnabled
            controller.navigationItem.leftBarButtonItems =
                (controller.navigationItem.leftBarButtonItems ?? []) + [item]
            self.items.append(item)
        }
        if let close {
            self.closeAction = close
            let item = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(self.closeTapped))
            item.accessibilityIdentifier = Self.closeIdentifier
            item.accessibilityLabel = close.label
            item.isEnabled = close.isEnabled
            controller.navigationItem.rightBarButtonItems =
                (controller.navigationItem.rightBarButtonItems ?? []) + [item]
            self.items.append(item)
        }
    }

    @objc private func backTapped() {
        guard let action = self.backAction else { return }
        Task {
            guard self.backAction?.id == action.id, self.backAction?.isEnabled == true else { return }
            await performNativePaywallAction(action.perform)
        }
    }

    @objc private func closeTapped() {
        guard let action = self.closeAction else { return }
        Task {
            guard self.closeAction?.id == action.id, self.closeAction?.isEnabled == true else { return }
            await performNativePaywallAction(action.perform)
        }
    }

    func removeClose() {
        if let navigationItem = self.controller?.navigationItem {
            if let originalHidesBackButton {
                navigationItem.hidesBackButton = originalHidesBackButton
            }
            if let originalSupplementBackButton {
                navigationItem.leftItemsSupplementBackButton = originalSupplementBackButton
            }
            for path in [\UINavigationItem.leftBarButtonItems, \UINavigationItem.rightBarButtonItems] {
                guard let existing = navigationItem[keyPath: path],
                      existing.contains(where: { item in self.items.contains { $0 === item } }) else { continue }
                let remaining = existing.filter { item in !self.items.contains { $0 === item } }
                navigationItem[keyPath: path] = remaining.isEmpty ? nil : remaining
            }
        }
        self.items = []
        self.originalSupplementBackButton = nil
        self.originalHidesBackButton = nil
        self.backAction = nil
        self.closeAction = nil
    }

}
#endif

#endif
