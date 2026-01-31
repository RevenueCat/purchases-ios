//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallCondensedFooterUIKitView.swift
//
//  Created by Ammad Akhtar on 23/01/2026.

#if canImport(UIKit) && os(iOS)

import SwiftUI
import RevenueCat
import RevenueCatUI

/// Allows us to display `PaywallCondensedFooterViewController`  in a SwiftUI app
struct PaywallCondensedFooterUIKitView: UIViewControllerRepresentable {

    let offering: Offering?

    func makeUIViewController(context: Context) -> UIViewController {
        return PaywallCondensedFooterContainerViewController(offering: self.offering)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }

}

private final class PaywallCondensedFooterContainerViewController: UIViewController, PaywallViewControllerDelegate {

    private enum Constants {
        static let initialPaywallHeight: CGFloat = 150
    }

    private let offering: Offering?

    private let scrollView: UIScrollView = .init()
    private var paywallHeightConstraint: NSLayoutConstraint?
    private var currentPaywallHeight: CGFloat = Constants.initialPaywallHeight

    init(offering: Offering?) {
        self.offering = offering
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor(CustomPaywallContent.backgroundColor)

        self.configureScrollableBackground()
        self.configureCondensedFooter()
    }

    private func configureScrollableBackground() {
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.alwaysBounceVertical = true

        let hostingController = UIHostingController(rootView: CustomPaywallContent())
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(self.scrollView)

        self.addChild(hostingController)
        self.scrollView.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),

            hostingController.view.topAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.trailingAnchor)
        ])

        hostingController.didMove(toParent: self)

        self.updateScrollInsetsForPaywallHeight(self.currentPaywallHeight)
    }

    private func configureCondensedFooter() {
        let paywallVC = PaywallCondensedFooterViewController(offering: self.offering)
        paywallVC.delegate = self

        self.addChild(paywallVC)
        self.view.addSubview(paywallVC.view)
        paywallVC.view.translatesAutoresizingMaskIntoConstraints = false
        paywallVC.view.backgroundColor = .clear

        let heightConstraint = paywallVC.view.heightAnchor.constraint(equalToConstant: self.currentPaywallHeight)
        self.paywallHeightConstraint = heightConstraint

        NSLayoutConstraint.activate([
            paywallVC.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            paywallVC.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            paywallVC.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            heightConstraint
        ])

        paywallVC.didMove(toParent: self)
    }

    private func updateScrollInsetsForPaywallHeight(_ height: CGFloat) {
        let clampedHeight = max(height, 0)

        self.scrollView.contentInset.bottom = clampedHeight

        if #available(iOS 13.0, *) {
            var verticalInsets = self.scrollView.verticalScrollIndicatorInsets
            verticalInsets.bottom = clampedHeight
            self.scrollView.verticalScrollIndicatorInsets = verticalInsets

            var horizontalInsets = self.scrollView.horizontalScrollIndicatorInsets
            horizontalInsets.bottom = clampedHeight
            self.scrollView.horizontalScrollIndicatorInsets = horizontalInsets
        } else {
            var insets = self.scrollView.scrollIndicatorInsets
            insets.bottom = clampedHeight
            self.scrollView.scrollIndicatorInsets = insets
        }
    }

    // MARK: - PaywallViewControllerDelegate

    func paywallViewController(_ controller: PaywallViewController, didChangeSizeTo size: CGSize) {
        guard size.height > 0 else { return }

        self.currentPaywallHeight = size.height
        self.paywallHeightConstraint?.constant = size.height
        self.updateScrollInsetsForPaywallHeight(size.height)
    }
}

#endif
