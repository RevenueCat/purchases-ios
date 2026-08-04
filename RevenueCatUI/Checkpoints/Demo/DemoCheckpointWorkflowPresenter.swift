//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DemoCheckpointWorkflowPresenter.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
import UIKit
#endif

/// PoC-only renderer for the JSON workflows bundled with CheckpointTester.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class DemoCheckpointWorkflowPresenter: NSObject, CheckpointEnginePresenter {

    struct PresentedWorkflow: Identifiable {
        let id: String
        let checkpoint: CheckpointEngineInfo
        let workflow: CheckpointWorkflow
        let delegate: CheckpointEnginePresenterDelegate
    }

    private var activeWorkflow: PresentedWorkflow?
    private var isFinishing = false
    private let presentationHandler: ((PresentedWorkflow) -> Bool)?

    #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
    private weak var presentedViewController: UIViewController?
    #endif

    override init() {
        self.presentationHandler = nil
        super.init()
    }

    init(presentationHandler: @escaping (PresentedWorkflow) -> Bool) {
        self.presentationHandler = presentationHandler
        super.init()
    }

    func present(
        callID: String,
        presentation: CheckpointEnginePresentation,
        delegate: CheckpointEnginePresenterDelegate
    ) {
        guard let presentation = presentation as? DemoCheckpointWorkflowPresentation else {
            delegate.onCheckpointPaywallFinished(
                callID: callID,
                outcome: .error(WorkflowError.invalidPresentation as NSError)
            )
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let workflow = try decoder.decode(CheckpointWorkflow.self, from: presentation.workflowData)
            guard !workflow.pages.isEmpty else {
                throw WorkflowError.emptyWorkflow
            }

            let presentedWorkflow = PresentedWorkflow(
                id: callID,
                checkpoint: presentation.checkpoint,
                workflow: workflow,
                delegate: delegate
            )
            self.activeWorkflow = presentedWorkflow

            let didBeginPresentation = self.presentationHandler?(presentedWorkflow)
                ?? self.presentAutomatically(presentedWorkflow)
            guard didBeginPresentation else {
                throw WorkflowError.noPresentationContext
            }
        } catch {
            self.finish(with: .error(error as NSError), fallback: (callID, delegate))
        }
    }

    func finish(with outcome: CheckpointEnginePaywallOutcome) {
        self.finish(with: outcome, fallback: nil)
    }

    func finishWithCustomerInfo(restored: Bool) {
        guard self.activeWorkflow != nil, !self.isFinishing else {
            return
        }
        self.isFinishing = true

        Task { @MainActor in
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                if restored {
                    self.finish(with: .restored(customerInfo))
                } else {
                    self.finish(with: .purchased(customerInfo))
                }
            } catch {
                self.finish(with: .error(error as NSError))
            }
        }
    }

    func presentationDidDismiss() {
        self.finish(with: .dismissed)
    }

    private func finish(
        with outcome: CheckpointEnginePaywallOutcome,
        fallback: (String, CheckpointEnginePresenterDelegate)?
    ) {
        let activeWorkflow = self.activeWorkflow
        self.activeWorkflow = nil
        self.isFinishing = false

        #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
        let viewController = self.presentedViewController
        self.presentedViewController = nil
        if viewController?.presentingViewController != nil {
            viewController?.dismiss(animated: true)
        }
        #endif

        if let activeWorkflow {
            activeWorkflow.delegate.onCheckpointPaywallFinished(
                callID: activeWorkflow.id,
                outcome: outcome
            )
        } else if let fallback {
            fallback.1.onCheckpointPaywallFinished(callID: fallback.0, outcome: outcome)
        }
    }

    private func presentAutomatically(_ presentedWorkflow: PresentedWorkflow) -> Bool {
        #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
        guard let presentationContext = UIApplication.demoCheckpointPresentationViewController else {
            return false
        }

        let rootView = CheckpointWorkflowView(
            presentedWorkflow: presentedWorkflow,
            presenter: self
        )
        .interactiveDismissDisabled(!presentedWorkflow.workflow.presentation.dismissible)
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

    case emptyWorkflow
    case invalidPresentation
    case noPresentationContext

    var errorDescription: String? {
        switch self {
        case .emptyWorkflow:
            return "The checkpoint workflow contains no pages."
        case .invalidPresentation:
            return "The checkpoint did not resolve to a demo JSON workflow."
        case .noPresentationContext:
            return "Unable to locate a view controller for checkpoint presentation."
        }
    }

}

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)

@available(iOS 15.0, macOS 12.0, *)
extension DemoCheckpointWorkflowPresenter: UIAdaptivePresentationControllerDelegate {

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return self.activeWorkflow?.workflow.presentation.dismissible == true
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.presentationDidDismiss()
    }

}

private extension UIApplication {

    static var demoCheckpointPresentationViewController: UIViewController? {
        return self.extensionSafeApplication?
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap(\.windows)
            .sorted { left, right in left.isKeyWindow && !right.isKeyWindow }
            .compactMap(\.rootViewController)
            .first?
            .demoCheckpointTopMostViewController
    }

}

private extension UIViewController {

    var demoCheckpointTopMostViewController: UIViewController {
        if let presentedViewController {
            return presentedViewController.demoCheckpointTopMostViewController
        }
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.demoCheckpointTopMostViewController
                ?? navigationController
        }
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.demoCheckpointTopMostViewController
                ?? tabBarController
        }
        if let splitViewController = self as? UISplitViewController,
           let lastViewController = splitViewController.viewControllers.last {
            return lastViewController.demoCheckpointTopMostViewController
        }
        return self
    }

}

#endif
