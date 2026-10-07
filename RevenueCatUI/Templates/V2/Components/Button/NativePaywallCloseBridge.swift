//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

#if os(iOS)
import ObjectiveC
import SwiftUI
import UIKit

/// Inspects the mounted controller hierarchy, rather than inferring navigation from whether
/// SwiftUI happened to render a toolbar. Works with both SwiftUI and UIKit navigation owners.
@available(iOS 15.0, *)
struct NativePaywallCloseBridge: UIViewControllerRepresentable {
    let accessibilityLabel: String
    let action: () -> Void
    let availabilityChanged: (Bool) -> Void

    func makeUIViewController(context: Context) -> NavigationObserver {
        let controller = NavigationObserver()
        controller.changed = { [weak coordinator = context.coordinator, weak controller] in
            guard let controller else { return }
            coordinator?.update(from: controller)
        }
        return controller
    }

    func updateUIViewController(_ controller: NavigationObserver, context: Context) {
        context.coordinator.action = self.action
        context.coordinator.closeLabel = self.accessibilityLabel
        context.coordinator.availabilityChanged = self.availabilityChanged
        controller.scheduleUpdate()
    }

    static func dismantleUIViewController(_ controller: NavigationObserver, coordinator: Coordinator) {
        controller.changed = nil
        coordinator.releaseOwnership()
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    @MainActor
    final class Coordinator: NSObject {
        private static var ownershipKey: UInt8 = 0
        private weak var navigationOwner: UIViewController?
        static let identifier = "RevenueCat.NativePaywallClose"
        var action: () -> Void = {}
        var closeLabel = ""
        var availabilityChanged: (Bool) -> Void = { _ in }
        private weak var owner: UIViewController?
        private var item: UIBarButtonItem?
        private var available: Bool?

        func update(from controller: UIViewController) {
            guard let navigation = controller.navigationController,
                  navigation.viewIfLoaded?.window != nil,
                  let top = navigation.topViewController,
                  Self.isAncestor(top, of: controller) else {
                self.releaseOwnership()
                self.report(false)
                return
            }
            if self.navigationOwner !== top { self.releaseOwnership() }
            let ownership: NativePaywallCloseOwnership
            if let existing = objc_getAssociatedObject(
                top.navigationItem, &Self.ownershipKey
            ) as? NativePaywallCloseOwnership {
                ownership = existing
            } else {
                ownership = NativePaywallCloseOwnership()
                objc_setAssociatedObject(
                    top.navigationItem, &Self.ownershipKey, ownership, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
            }
            guard ownership.coordinator == nil || ownership.coordinator === self else {
                self.report(false)
                return
            }
            ownership.coordinator = self
            self.navigationOwner = top
            guard !navigation.isNavigationBarHidden else {
                self.removeItem()
                self.report(false)
                return
            }
            if self.owner !== top { self.removeItem() }
            let items = top.navigationItem.rightBarButtonItems ?? []
            if self.item == nil {
                self.item = UIBarButtonItem(
                    barButtonSystemItem: .close, target: self, action: #selector(self.closeTapped)
                )
                self.item?.accessibilityIdentifier = Self.identifier
            }
            guard let item = self.item else { return }
            item.accessibilityLabel = self.closeLabel
            self.owner = top
            if !items.contains(where: { $0 === item }) {
                top.navigationItem.rightBarButtonItems = items + [item]
            }
            self.report(true)
        }

        func releaseOwnership() {
            self.removeItem()
            if let owner = self.navigationOwner,
               let ownership = objc_getAssociatedObject(
                   owner.navigationItem, &Self.ownershipKey
               ) as? NativePaywallCloseOwnership,
               ownership.coordinator === self {
                ownership.coordinator = nil
            }
            self.navigationOwner = nil
        }

        @objc private func closeTapped() { self.action() }

        func removeItem() {
            if let owner = self.owner, let item = self.item {
                owner.navigationItem.rightBarButtonItems = owner.navigationItem.rightBarButtonItems?
                    .filter { $0 !== item }
            }
            self.item = nil
            self.owner = nil
        }

        private func report(_ available: Bool) {
            guard self.available != available else { return }
            self.available = available
            self.availabilityChanged(available)
        }

        private static func isAncestor(_ ancestor: UIViewController, of controller: UIViewController) -> Bool {
            var current: UIViewController? = controller
            while let candidate = current {
                if candidate === ancestor { return true }
                current = candidate.parent
            }
            return false
        }
    }

    private final class ObservationView: UIView {
        var changed: (() -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            self.changed?()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            self.changed?()
        }
    }

    final class NavigationObserver: UIViewController {
        var changed: (() -> Void)?
        private var updateScheduled = false

        override func loadView() {
            let view = ObservationView()
            view.changed = { [weak self] in self?.scheduleUpdate() }
            self.view = view
            self.view.isUserInteractionEnabled = false
        }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            self.scheduleUpdate()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            self.scheduleUpdate()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            self.scheduleUpdate()
        }

        func scheduleUpdate() {
            guard !self.updateScheduled else { return }
            self.updateScheduled = true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.updateScheduled = false
                self.changed?()
            }
        }
    }
}
@available(iOS 15.0, *)
@MainActor
private final class NativePaywallCloseOwnership: NSObject {
    weak var coordinator: NativePaywallCloseBridge.Coordinator?
}

#endif
