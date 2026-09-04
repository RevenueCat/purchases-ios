//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomCheckpointUseCaseView.swift
//
//  Created by Rick van der Linden.
//

import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI
import SwiftUI

struct CustomCheckpointUseCaseView: View {

    @ObservedObject var model: CheckpointDemoModel
    @ObservedObject var customVariables: CustomVariables

    @State private var identifier = ""
    @State private var isRunning = false

    private var trimmedIdentifier: String {
        return self.identifier.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            Section {
                TextField("Checkpoint identifier", text: self.$identifier)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button("Hit") {
                    Task { @MainActor in
                        await self.hitCheckpoint()
                    }
                }
                .disabled(self.trimmedIdentifier.isEmpty || self.isRunning)
            } footer: {
                Text("The current custom variables are passed to the checkpoint.")
            }
        }
        .navigationTitle("Custom checkpoint")
    }

    @MainActor
    private func hitCheckpoint() async {
        guard !self.trimmedIdentifier.isEmpty, !self.isRunning else { return }

        self.isRunning = true
        defer { self.isRunning = false }

        let result = await Purchases.shared.checkpoint(
            self.trimmedIdentifier,
            customVariables: self.customVariables.checkpointCustomVariables
        )
        self.model.showOutcome(result, checkpointIdentifier: self.trimmedIdentifier)
    }

}
