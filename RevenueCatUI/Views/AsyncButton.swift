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
    private var error: NSError?

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
                    self.error = error
                }
            }
        } label: {
            self.label
        }
        .disabled(self.inProgress)
        .displayError(self.$error)
    }

}
