//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointWorkflowPresenter.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
import UIKit
#endif

/// Presents workflows resolved by the RevenueCat core module.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
@_spi(Internal) public final class CheckpointWorkflowPresenter: NSObject, CheckpointPresenter {

    struct PresentedWorkflow: Identifiable {
        let id: String
        let presentation: ResolvedCheckpointWorkflowPresentation
        let delegate: CheckpointPresenterDelegate
    }

    private var activeWorkflow: PresentedWorkflow?
    private let presentationHandler: ((PresentedWorkflow) throws -> Bool)?

    #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
    private weak var presentedViewController: UIViewController?
    #endif

    /// Creates a checkpoint workflow presenter.
    public override init() {
        self.presentationHandler = nil
        super.init()
    }

    init(presentationHandler: @escaping (PresentedWorkflow) throws -> Bool) {
        self.presentationHandler = presentationHandler
        super.init()
    }

    /// Presents the resolved workflow using RevenueCatUI's workflow paywall renderer.
    public func present(
        callID: String,
        presentation: CheckpointWorkflowPresentation,
        delegate: CheckpointPresenterDelegate
    ) {
        guard let presentation = presentation as? ResolvedCheckpointWorkflowPresentation else {
            delegate.onCheckpointPaywallFinished(
                callID: callID,
                outcome: CheckpointPaywallErrorOutcome(error: WorkflowError.invalidPresentation as NSError)
            )
            return
        }

        do {
            let presentedWorkflow = PresentedWorkflow(
                id: callID,
                presentation: presentation,
                delegate: delegate
            )
            self.activeWorkflow = presentedWorkflow

            let didBeginPresentation = try self.presentationHandler?(presentedWorkflow)
                ?? self.presentAutomatically(presentedWorkflow)
            guard didBeginPresentation else {
                throw WorkflowError.noPresentationContext
            }
        } catch {
            self.finish(with: CheckpointPaywallErrorOutcome(error: error as NSError))
        }
    }

    func finish(with outcome: CheckpointPaywallOutcome) {
        guard let activeWorkflow else {
            return
        }

        self.activeWorkflow = nil

        #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
        let viewController = self.presentedViewController
        self.presentedViewController = nil
        if viewController?.presentingViewController != nil {
            viewController?.dismiss(animated: true)
        }
        #endif

        activeWorkflow.delegate.onCheckpointPaywallFinished(
            callID: activeWorkflow.id,
            outcome: outcome
        )
    }

    func presentationDidDismiss() {
        self.finish(with: CheckpointPaywallDismissedOutcome())
    }

    private func presentAutomatically(_ presentedWorkflow: PresentedWorkflow) throws -> Bool {
        #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
        guard let presentationContext = UIApplication.checkpointPresentationViewController else {
            return false
        }
        guard let offering = presentedWorkflow.presentation.offering else {
            throw WorkflowError.missingOffering
        }

        let workflowContext = try WorkflowPreview.makeContext(
            workflow: presentedWorkflow.presentation.workflow,
            offerings: [offering],
            uiConfig: presentedWorkflow.presentation.uiConfig
        )
        let rootView = PaywallView(
            workflowContext: workflowContext,
            displayCloseButton: true
        )
        .onPurchaseCompleted { [weak self] customerInfo in
            self?.finish(with: CheckpointPaywallPurchasedOutcome(customerInfo: customerInfo))
        }
        .onRestoreCompleted { [weak self] customerInfo in
            self?.finish(with: CheckpointPaywallRestoredOutcome(customerInfo: customerInfo))
        }
        .onPurchaseFailure { [weak self] error in
            self?.finish(with: CheckpointPaywallErrorOutcome(error: error as NSError))
        }
        .onRestoreFailure { [weak self] error in
            self?.finish(with: CheckpointPaywallErrorOutcome(error: error as NSError))
        }
        .onRequestedDismissal { [weak self] in
            self?.finish(with: CheckpointPaywallDismissedOutcome())
        }

        let viewController = UIHostingController(rootView: rootView)
        self.presentedViewController = viewController
        presentationContext.present(viewController, animated: true)
        viewController.presentationController?.delegate = self
        return true
        #else
        return false
        #endif
    }

}

private enum WorkflowError: LocalizedError {

    case invalidPresentation
    case missingOffering
    case noPresentationContext

    var errorDescription: String? {
        switch self {
        case .invalidPresentation:
            return "The checkpoint did not resolve to a renderable workflow."
        case .missingOffering:
            return "The checkpoint workflow's offering is unavailable."
        case .noPresentationContext:
            return "Unable to locate a view controller for checkpoint presentation."
        }
    }

}

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)

@available(iOS 15.0, macOS 12.0, *)
extension CheckpointWorkflowPresenter: UIAdaptivePresentationControllerDelegate {

    /// Reports an interactive dismissal as the workflow's terminal result.
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.presentationDidDismiss()
    }

}

private extension UIApplication {

    static var checkpointPresentationViewController: UIViewController? {
        return self.extensionSafeApplication?
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap(\.windows)
            .sorted { left, right in
                left.isKeyWindow && !right.isKeyWindow
            }
            .compactMap(\.rootViewController)
            .first?
            .checkpointTopMostViewController
    }

}

private extension UIViewController {

    var checkpointTopMostViewController: UIViewController {
        if let presentedViewController {
            return presentedViewController.checkpointTopMostViewController
        }
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.checkpointTopMostViewController
                ?? navigationController
        }
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.checkpointTopMostViewController
                ?? tabBarController
        }
        if let splitViewController = self as? UISplitViewController,
           let lastViewController = splitViewController.viewControllers.last {
            return lastViewController.checkpointTopMostViewController
        }
        return self
    }

}

#endif
