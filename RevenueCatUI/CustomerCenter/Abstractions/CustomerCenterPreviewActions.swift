//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterPreviewActions.swift
//
//  Created by Monika on 2026-10-14.

@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)
@available(iOS 15.0, *)
@MainActor
final class CustomerCenterPreviewActions: ObservableObject {
    @Published private(set) var isRunning = false
    @Published var failure: String?

    private let provider: CustomerCenterPreviewProvider
    private var task: Task<Void, Never>?
    private var actionID: UUID?

    init(provider: CustomerCenterPreviewProvider) {
        self.provider = provider
    }

    func perform(_ action: CustomerCenterPreviewAction) async {
        guard !isRunning, !Task.isCancelled else { return }
        let id = UUID()
        actionID = id
        isRunning = true
        failure = nil
        let task = Task { [provider] in
            do {
                try Task.checkCancellation()
                try await provider.handlePreviewAction(action)
            } catch is CancellationError {
                // Cancellation is an expected preview outcome.
            } catch {
                guard !Task.isCancelled, self.actionID == id else { return }
                if !(error as NSError).isPurchaseCancellation {
                    self.failure = error.localizedDescription
                }
            }
        }
        self.task = task
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
        // A cancelled provider may finish after another action has started.
        guard actionID == id else { return }
        self.task = nil
        actionID = nil
        isRunning = false
    }

    func cancel() {
        task?.cancel()
        task = nil
        actionID = nil
        isRunning = false
        failure = nil
    }
}

@available(iOS 15.0, *)
struct CustomerCenterPreviewActionsModifier: ViewModifier {
    let actions: CustomerCenterPreviewActions?

    @ViewBuilder func body(content: Content) -> some View {
        if let actions {
            content.modifier(ActivePreviewActionsModifier(actions: actions))
        } else {
            content
        }
    }
}

@available(iOS 15.0, *)
private struct ActivePreviewActionsModifier: ViewModifier {
    @ObservedObject var actions: CustomerCenterPreviewActions

    func body(content: Content) -> some View {
        content
            .disabled(actions.isRunning)
            .overlay {
                if actions.isRunning {
                    ProgressView().padding().background(.regularMaterial).cornerRadius(12)
                }
            }
            .onDisappear { actions.cancel() }
            .alert("Preview action failed", isPresented: Binding(
                get: { actions.failure != nil }, set: { if !$0 { actions.failure = nil } }
            )) {
                Button("OK", role: .cancel) { actions.failure = nil }
            } message: {
                Text(actions.failure ?? "")
            }
    }
}
#endif
