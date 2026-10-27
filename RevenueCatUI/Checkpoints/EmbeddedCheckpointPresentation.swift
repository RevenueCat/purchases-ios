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
    private weak var parent: UIViewController?
    private(set) var isAttached = false
    private var didFinish = false

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
        parent.view.addSubview(childView)
        NSLayoutConstraint.activate([
            childView.topAnchor.constraint(equalTo: parent.view.topAnchor),
            childView.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor),
            childView.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor)
        ])
        self.controller.didMove(toParent: parent)
        self.isAttached = true
        return true
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
        completion?()
    }

}

#endif
