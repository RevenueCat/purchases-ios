//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EmbeddedCheckpointExecution.swift
//
//  Created by Cesar de la Vega.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Owns one checkpoint embedded in a caller-supplied parent view controller, from resolution until the
/// flow is removed, cancelled, or fails.
///
/// The SDK performs the UIKit containment itself: the caller only supplies the parent and receives callbacks.
@_spi(Internal)
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class EmbeddedCheckpointExecution {

    private(set) var isCancelled = false
    private var onFinished: (() -> Void)?
    private var ownsPresentationSlot = false
    private var pendingErrors: [UUID: ErrorPresentationCompletion] = [:]
    var task: Task<Void, Never>?

    #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
    private var presentation: EmbeddedCheckpointPresentation?

    /// The parent is only held weakly: if it goes away before the flow is attached, the checkpoint fails cleanly
    /// instead of falling back to a modal.
    private(set) weak var parentViewController: UIViewController?

    init(parentViewController: UIViewController?, onFinished: @escaping () -> Void) {
        self.parentViewController = parentViewController
        self.onFinished = onFinished
    }
    #else
    private var presentation: AnyObject?

    init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }
    #endif

    /// Cancels resolution, or removes the embedded flow if it is on screen. `onPassed` is suppressed unless
    /// the flow had already granted access (a purchase or restore the app must still learn about), and
    /// `onFinished` is still delivered exactly once.
    public func cancel() {
        guard !self.isCancelled, self.onFinished != nil else { return }
        self.isCancelled = true
        self.task?.cancel()
        self.retirePendingErrors()
        #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
        if let presentation = self.presentation {
            presentation.remove()
            return
        }
        #endif
        if !self.ownsPresentationSlot {
            self.finish()
        }
    }

    func presentationStarted() {
        self.ownsPresentationSlot = true
    }

    func presentationEnded() {
        self.ownsPresentationSlot = false
        if self.isCancelled, self.presentation == nil { self.finish() }
    }

    #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
    func attach(_ presentation: EmbeddedCheckpointPresentation) {
        self.presentation = presentation
        presentation.onParentLost = { [weak self] in self?.cancel() }
        presentation.onFinished = { [weak self] in
            guard let self else { return }
            self.presentation = nil
            if self.isCancelled, !self.ownsPresentationSlot { self.finish() }
        }
    }
    #endif

    func finish() {
        guard let completion = self.onFinished else { return }
        self.onFinished = nil
        self.task = nil
        self.presentation = nil
        self.retirePendingErrors()
        completion()
    }

    /// Tracks the error presentations of this execution so cancellation can release them, and so replies that
    /// arrive after cancellation are ignored.
    func wrap(_ handler: @escaping ErrorPresentationHandler) -> ErrorPresentationHandler {
        return { [weak self] params, completion in
            guard let self, !self.isCancelled, self.onFinished != nil else {
                completion.complete()
                return
            }
            let id = UUID()
            self.pendingErrors[id] = completion
            handler(params, .init { [weak self] in
                self?.pendingErrors.removeValue(forKey: id)?.complete()
            })
        }
    }

    private func retirePendingErrors() {
        let errors = self.pendingErrors.values
        self.pendingErrors.removeAll()
        for error in errors { error.complete() }
    }

}
