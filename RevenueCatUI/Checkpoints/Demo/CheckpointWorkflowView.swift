//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointWorkflowView.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CheckpointWorkflowView: View {

    let presentedWorkflow: DemoCheckpointWorkflowPresenter.PresentedWorkflow
    let presenter: DemoCheckpointWorkflowPresenter

    @State private var pageIndex = 0

    var body: some View {
        let workflow = self.presentedWorkflow.workflow
        let page = workflow.pages[self.pageIndex]

        ScrollView {
            VStack(spacing: 18) {
                Spacer(minLength: 24)

                ForEach(Array(page.components.enumerated()), id: \.offset) { _, component in
                    self.componentView(component)
                }

                if workflow.pages.count > 1 {
                    SwiftUI.ProgressView(
                        value: Double(self.pageIndex + 1),
                        total: Double(workflow.pages.count)
                    )
                    .padding(.vertical, 8)
                }

                ForEach(Array(page.actions.enumerated()), id: \.offset) { _, action in
                    self.actionButton(action, workflow: workflow)
                }

                Spacer(minLength: 24)
            }
            .frame(maxWidth: 560)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func componentView(_ component: CheckpointWorkflowComponent) -> some View {
        switch component.type {
        case .image:
            if let systemName = component.systemName {
                Image(systemName: systemName)
                    .font(.system(size: 58))
                    .foregroundStyle(.tint)
            }
        case .title:
            if let text = component.text {
                Text(text)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
            }
        case .body:
            if let text = component.text {
                Text(text)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        case .feature:
            if let text = component.text {
                Label(text, systemImage: component.systemName ?? "checkmark.circle.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private func actionButton(
        _ action: CheckpointWorkflowAction,
        workflow: CheckpointWorkflow
    ) -> some View {
        switch action.style {
        case .primary:
            self.button(action, workflow: workflow)
                .buttonStyle(.borderedProminent)
        case .secondary:
            self.button(action, workflow: workflow)
                .buttonStyle(.bordered)
        case .destructive:
            self.button(action, workflow: workflow)
                .buttonStyle(.bordered)
                .foregroundStyle(.red)
        }
    }

    private func button(
        _ action: CheckpointWorkflowAction,
        workflow: CheckpointWorkflow
    ) -> some View {
        Button(action.title) {
            self.perform(action, workflow: workflow)
        }
        .controlSize(.large)
        .frame(maxWidth: .infinity)
    }

    private func perform(
        _ action: CheckpointWorkflowAction,
        workflow: CheckpointWorkflow
    ) {
        switch action.type {
        case .next:
            self.pageIndex = min(self.pageIndex + 1, workflow.pages.count - 1)
        case .previous:
            self.pageIndex = max(self.pageIndex - 1, 0)
        case .purchase:
            self.presenter.finishWithCustomerInfo(restored: false)
        case .restore:
            self.presenter.finishWithCustomerInfo(restored: true)
        case .dismiss, .complete:
            self.presenter.finish(with: CheckpointPaywallDismissedOutcome.shared)
        case .error:
            self.presenter.finish(
                with: CheckpointPaywallErrorOutcome(
                    error: NSError(
                        domain: "RevenueCatUI.CheckpointWorkflow",
                        code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Server-driven workflow simulated an error."
                        ]
                    )
                )
            )
        }
    }

}
