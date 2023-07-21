//
//  AsyncButton.swift
//  
//
//  Created by Nacho Soto on 7/13/23.
//

import RevenueCat
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct AsyncButton<Label>: View where Label: View {

    typealias Action = @Sendable @MainActor () async throws -> Void

    private let action: Action
    private let label: Label

    @State
    private var error: LocalizedAlertError?

    @State
    private var inProgress: Bool = false

    init(action: @escaping Action, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button {
            Task<Void, Never> {
                self.inProgress = true
                defer { self.inProgress = false }

                do {
                    try await self.action()
                } catch let error as NSError {
                    self.error = .init(error: error)
                }
            }
        } label: {
            self.label
        }
        .disabled(self.inProgress)
        .alert(isPresented: self.isShowingError, error: self.error) { _ in
            Button {
                self.error = nil
            } label: {
                Text("OK")
            }
        } message: { error in
            Text(error.failureReason ?? "")
        }
    }

    private var isShowingError: Binding<Bool> {
        return .init {
            self.error != nil
        } set: { newValue in
            if !newValue {
                self.error = nil
            }
        }
    }

}

// MARK: - Errors

private struct LocalizedAlertError: LocalizedError {

    private let underlyingError: NSError

    init(error: NSError) {
        self.underlyingError = error
    }

    var errorDescription: String? {
        return "\(self.underlyingError.domain) \(self.underlyingError.code)"
    }

    var failureReason: String? {
        if let errorCode = self.underlyingError as? ErrorCode {
            return errorCode.description
        } else {
            return self.underlyingError.localizedDescription
        }
    }

    var recoverySuggestion: String? {
        self.underlyingError.localizedRecoverySuggestion
    }

}
