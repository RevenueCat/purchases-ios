//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallFooterViewController.swift
//
//  Created by Antonio Rico Diez on 4/12/23.
//

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)

import RevenueCat
import SwiftUI
import UIKit

/// A view controller for displaying `PaywallData` for an `Offering` in a footer format.
/// This is used by the RevenueCat hybrid SDKs in order to get a View of the footer.
///
/// Consumers should normally use ``PaywallViewController`` instead.
///
/// - Seealso: ``PaywallView`` for `SwiftUI`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@objc(RCPaywallFooterViewController)
public final class PaywallFooterViewController: PaywallViewController {

    override var mode: PaywallViewMode {
        return .footer
    }

    /// Initialize a `PaywallFooterViewController` with an optional `Offering`.
    /// - Parameter offering: The `Offering` containing the desired `PaywallData` to display.
    /// `Offerings.current` will be used by default.
    @objc
    public init(offering: Offering? = nil) {
        super.init(offering: offering, displayCloseButton: false)
    }

    @available(*, unavailable)
    override init(
        offering: Offering? = nil,
        displayCloseButton: Bool = false
    ) {
        super.init(offering: offering, displayCloseButton: false)
    }

    // swiftlint:disable:next missing_docs
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -

    public override var additionalSafeAreaInsets: UIEdgeInsets {
        didSet {
            // Ideally setting self.hostingController.additionalSafeAreaInsets
            // would propagate it to SwiftUI, but it doesn't.
            // Instead we modify the internal state to manually pass the value to SwiftUI.
            self.viewModel.bottomSafeArea = self.additionalSafeAreaInsets
        }
    }

    private let viewModel: PaywallWrapperViewModel = .init()

    override func createViewController() -> UIViewController {
        let view = PaywallWrapper(viewModel: self.viewModel) {
            super.createPaywallView()
        }
        return UIHostingController(rootView: view)
    }

}

// MARK: - Inset

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
final class PaywallWrapperViewModel: ObservableObject {

    @Published
    var bottomSafeArea: UIEdgeInsets = .zero

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct PaywallWrapper<Paywall: View>: View {

    private let paywallView: Paywall

    @ObservedObject
    private var viewModel: PaywallWrapperViewModel

    init(viewModel: PaywallWrapperViewModel, paywallView: () -> Paywall) {
        self.viewModel = viewModel
        self.paywallView = paywallView()
    }

    var body: some View {
        if #available(iOS 17.0, *) {
            self.paywallView
                .safeAreaPadding(self.viewModel.bottomSafeArea.asInsets)
        } else {
            self.paywallView
                .safeAreaInset(edge: .bottom) {
                    Rectangle()
                        .hidden()
                        .frame(height: self.viewModel.bottomSafeArea.bottom)
                }
        }
    }

}

private extension UIEdgeInsets {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
    var asInsets: EdgeInsets {
        return .init(top: self.top, leading: self.left, bottom: self.bottom, trailing: self.right)
    }

}

#endif
