//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ScrollViewGestureCoordinator.swift
//

import SwiftUI

#if canImport(UIKit) && !os(watchOS) && !os(tvOS)
import UIKit

/// Coordinates gestures between a horizontal carousel and a parent vertical scroll view.
/// This installs a horizontal-only pan recognizer into the carousel host view and
/// requires the parent vertical scroll recognizer to wait for it to fail.
@available(iOS 15.0, *)
struct ScrollViewGestureCoordinator: UIViewRepresentable {
    @Binding var translation: CGFloat
    let onDragEnded: (CGFloat) -> Void
    let onDragStarted: () -> Void

    func makeUIView(context: Context) -> GestureCoordinatorHostView {
        let view = GestureCoordinatorHostView()
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: GestureCoordinatorHostView, context: Context) {
        uiView.onTranslationChanged = { translation in
            self.translation = translation
        }
        uiView.onDragEnded = { translation in
            self.onDragEnded(translation)
        }
        uiView.onDragStarted = self.onDragStarted
        uiView.attachIfNeeded()
    }
}

@available(iOS 15.0, *)
final class GestureCoordinatorHostView: UIView, UIGestureRecognizerDelegate {
    var onTranslationChanged: ((CGFloat) -> Void)?
    var onDragEnded: ((CGFloat) -> Void)?
    var onDragStarted: (() -> Void)?

    private weak var gestureContainerView: UIView?
    private weak var attachedWindow: UIWindow?

    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        gesture.cancelsTouchesInView = false
        gesture.delegate = self
        return gesture
    }()
    private var isHorizontalPan: Bool?
    private let directionLockThreshold: CGFloat = 10

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    deinit {
        self.gestureContainerView?.removeGestureRecognizer(self.panGesture)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        self.attachIfNeeded()
    }

    func attachIfNeeded() {
        guard self.gestureContainerView == nil else { return }
        guard self.superview != nil else { return }
        guard let window = self.window else { return }

        let containerView = window

        containerView.addGestureRecognizer(self.panGesture)
        self.gestureContainerView = containerView
        self.attachedWindow = window

        let carouselFrameInWindow = self.convert(self.bounds, to: window)
        let candidateScrollViews = self.findAllScrollViews(in: window).filter { scrollView in
            let frameInWindow = scrollView.convert(scrollView.bounds, to: window)
            return frameInWindow.intersects(carouselFrameInWindow)
        }

        for scrollView in candidateScrollViews {
            scrollView.panGestureRecognizer.require(toFail: self.panGesture)
        }
    }

    private func findAllScrollViews(in rootView: UIView) -> [UIScrollView] {
        var result: [UIScrollView] = []
        if let scrollView = rootView as? UIScrollView {
            result.append(scrollView)
        }

        for subview in rootView.subviews {
            result.append(contentsOf: findAllScrollViews(in: subview))
        }

        return result
    }

    private func findInteractiveAncestor(startingAt view: UIView) -> UIView? {
        var currentView: UIView? = view
        while let view = currentView {
            if view.isUserInteractionEnabled {
                return view
            }
            currentView = view.superview
        }

        return nil
    }

    private func findAncestorScrollView(startingAt view: UIView) -> UIScrollView? {
        var currentView = view.superview
        while let view = currentView {
            if let scrollView = view as? UIScrollView {
                return scrollView
            }
            currentView = view.superview
        }

        return nil
    }

    // swiftlint:disable:next cyclomatic_complexity
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let gestureView = gesture.view else { return }

        let translation = gesture.translation(in: gestureView)
        let velocity = gesture.velocity(in: gestureView)

        switch gesture.state {
        case .began:
            if velocity != .zero {
                isHorizontalPan = abs(velocity.x) >= abs(velocity.y)
            } else {
                isHorizontalPan = nil
            }
            self.onDragStarted?()

        case .changed:
            if isHorizontalPan == nil {
                let absX = abs(translation.x)
                let absY = abs(translation.y)
                if max(absX, absY) >= directionLockThreshold {
                    isHorizontalPan = absX > absY
                }
            }

            if isHorizontalPan == true {
                self.onTranslationChanged?(translation.x)
            }

        case .ended, .cancelled:
            let resolvedIsHorizontal: Bool = {
                if let isHorizontalPan {
                    return isHorizontalPan
                }

                return abs(translation.x) >= abs(translation.y)
            }()

            if resolvedIsHorizontal {
                self.onDragEnded?(translation.x)
            } else {
                self.onDragEnded?(0)
            }
            isHorizontalPan = nil

        default:
            break
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == panGesture else { return true }
        guard let gestureView = gestureRecognizer.view else { return true }
        guard let window = self.attachedWindow else { return true }

        let locationInWindow = gestureRecognizer.location(in: window)
        let carouselFrameInWindow = self.convert(self.bounds, to: window)
        guard carouselFrameInWindow.contains(locationInWindow) else {
            return false
        }

        let velocity = panGesture.velocity(in: gestureView)
        return abs(velocity.x) >= abs(velocity.y)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return false
    }
}
#endif
