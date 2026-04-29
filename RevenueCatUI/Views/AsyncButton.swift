//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

//  AsyncButton.swift
//
//  Created by Nacho Soto on 7/13/23.

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct AsyncButton<Label>: View where Label: View {

    typealias Action = @Sendable @MainActor () async throws -> Void

    private let action: Action
    private let label: Label
    private let accessibilityLabelString: String?

    @State
    private var error: NSError?

    init(
        accessibilityLabel: String? = nil,
        action: @escaping Action,
        @ViewBuilder label: () -> Label
    ) {
        self.action = action
        self.label = label()
        self.accessibilityLabelString = accessibilityLabel
    }

    var body: some View {
        Button {
            Task<Void, Never> {
                do {
                    try await self.action()
                } catch let error as NSError {
                    self.error = error
                }
            }
        } label: {
            self.label
        }
        .applyIf(accessibilityLabelString != nil) { button in
            // swiftlint:disable:next force_unwrapping
            button.accessibilityLabel(accessibilityLabelString!)
        }
        .displayError(self.$error)
    }

}
