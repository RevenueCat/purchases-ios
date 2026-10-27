//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EmbeddedCheckpointPresentation.swift
//
//  Created by Cesar de la Vega.
//

import Foundation

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
import UIKit

/// Shows a prepared checkpoint controller as a child of a caller-supplied parent, filling its bounds above
/// the parent's existing content. The SDK owns attachment, layout, and removal; the parent decides whether the
/// result reads as a sheet, a full-screen modal, or an ordinary screen.
///
/// The child never finishes the checkpoint on its own disappearance: a modal covering the parent (for example,
/// a framework-rendered error dialog) leaves the flow active. Only ``remove()`` ends the presentation.
@MainActor
@available(iOS 15.0, macOS 12.0, *)
final class EmbeddedCheckpointPresentation {

    /// The native controller, with its checkpoint delegate and workflow context intact.
    let controller: PaywallViewController
    var onFinished: (() -> Void)?
    /// Called when the parent is dismissed or deallocated while the child is attached, so the owner can
    /// cancel instead of leaving an orphaned flow holding the checkpoint slot.
    var onParentLost: (() -> Void)?
    private weak var parent: UIViewController?
    private(set) var isAttached = false
    private var didFinish = false
    private static var sentinelKey: UInt8 = 0

    init(controller: PaywallViewController, parent: UIViewController) {
        self.controller = controller
        self.parent = parent
        controller.usesEmbeddedCheckpointLifecycle = true
    }

    /// Whether a parent can host a child right now: on screen and not on its way out.
    static func isUsableParent(_ parent: UIViewController?) -> Bool {
        guard let parent, parent.isViewLoaded, parent.view.window != nil,
              !parent.isBeingDismissed, !parent.isMovingFromParent else { return false }
        return true
    }

    /// Attaches the controller as a child of the parent. Returns `false`, leaving nothing behind, when the
    /// parent is no longer usable.
    func attach() -> Bool {
        guard !self.didFinish, !self.isAttached, let parent, Self.isUsableParent(parent) else { return false }

        let childView: UIView = self.controller.view
        parent.addChild(self.controller)
        childView.translatesAutoresizingMaskIntoConstraints = false
        // A child is not a modal to UIKit: keep assistive technologies from reaching the content below.
        childView.accessibilityViewIsModal = true
        parent.view.addSubview(childView)
        NSLayoutConstraint.activate([
            childView.topAnchor.constraint(equalTo: parent.view.topAnchor),
            childView.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor),
            childView.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor)
        ])
        self.controller.didMove(toParent: parent)
        self.isAttached = true
        self.observeParentTeardown(parent)
        return true
    }

    /// Notices the parent going away without an explicit removal: its dismissal (through the child's
    /// appearance callbacks) or its deallocation (through an associated sentinel).
    private func observeParentTeardown(_ parent: UIViewController) {
        self.controller.embeddedParentTeardownHandler = { [weak self] in self?.parentLost() }
        let sentinel = ParentLifetimeSentinel { [weak self] in
            if Thread.isMainThread {
                MainActor.assumeIsolated { self?.parentLost() }
            } else {
                DispatchQueue.main.async { self?.parentLost() }
            }
        }
        objc_setAssociatedObject(parent, &Self.sentinelKey, sentinel, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private func stopObservingParentTeardown() {
        self.controller.embeddedParentTeardownHandler = nil
        if let parent = self.parent {
            objc_setAssociatedObject(parent, &Self.sentinelKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private func parentLost() {
        guard !self.didFinish, self.isAttached else { return }
        self.stopObservingParentTeardown()
        if let onParentLost = self.onParentLost {
            onParentLost()
        } else {
            self.remove()
        }
    }

    /// Reports that the controller could not be attached. The controller is detached from its presenter so a
    /// later presentation cannot be affected by it.
    func fail() {
        guard !self.didFinish else { return }
        self.didFinish = true
        self.controller.delegate = nil
        self.finish()
    }

    /// Removes the child from the parent, then reports the native recorded outcome through the controller's
    /// delegate. Safe to call more than once.
    func remove() {
        guard !self.didFinish else { return }
        self.didFinish = true
        self.stopObservingParentTeardown()
        if self.isAttached {
            self.controller.willMove(toParent: nil)
            self.controller.viewIfLoaded?.removeFromSuperview()
            self.controller.removeFromParent()
            self.isAttached = false
        }
        self.controller.embeddedCheckpointDidRemove()
        self.finish()
    }

    private func finish() {
        let completion = self.onFinished
        self.onFinished = nil
        self.onParentLost = nil
        completion?()
    }

}

/// Fires when the object it is associated with is deallocated.
private final class ParentLifetimeSentinel {

    private let onDeinit: () -> Void

    init(onDeinit: @escaping () -> Void) {
        self.onDeinit = onDeinit
    }

    deinit {
        self.onDeinit()
    }

}

#endif
