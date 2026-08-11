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
import RevenueCatUI
import SwiftUI

struct CustomCheckpointUseCaseView: View {

    @ObservedObject var model: CheckpointDemoModel
    @ObservedObject var checkpointVariables: CheckpointVariables

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
                Text("The current variables are passed as checkpoint parameters.")
            }
        }
        .navigationTitle("Custom checkpoint")
    }

    @MainActor
    private func hitCheckpoint() async {
        guard !self.trimmedIdentifier.isEmpty, !self.isRunning else { return }

        self.isRunning = true
        defer { self.isRunning = false }

        do {
            let result = try await Purchases.shared.checkpoint(
                self.trimmedIdentifier,
                params: self.checkpointVariables.checkpointParams
            )
            self.model.showOutcome(result)
        } catch {
            self.model.showError(error)
        }
    }

}
