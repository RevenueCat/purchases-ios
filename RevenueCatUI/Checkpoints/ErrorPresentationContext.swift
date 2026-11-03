//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ErrorPresentationContext.swift
//
#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
import UIKit

/// Presentation capability for hybrid error UI, valid only while its native error request is active.
@_spi(Internal)
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class ErrorPresentationContext {
    /// The owning paywall controller. Cleared when this context is invalidated.
    public private(set) weak var viewController: UIViewController?
    /// Whether the original error request is still active.
    public private(set) var isValid = true
    private var invalidationHandler: (() -> Void)?

    /// Called once on invalidation, or immediately when registered after invalidation.
    public var onInvalidated: (() -> Void)? {
        get { self.invalidationHandler }
        set {
            if self.isValid {
                self.invalidationHandler = newValue
            } else {
                newValue?()
            }
        }
    }

    init(viewController: UIViewController?) {
        self.viewController = viewController
    }

    func invalidate() {
        guard self.isValid else { return }
        self.isValid = false
        self.viewController = nil
        let handler = self.invalidationHandler
        self.invalidationHandler = nil
        handler?()
    }
}
#endif
