//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriberAttributeEditor.swift
//
//  Created by Rick van der Linden.
//

import RevenueCat
import SwiftUI

struct SubscriberAttributeEditor: View {

    @Environment(\.dismiss) private var dismiss

    @State private var key = ""
    @State private var value = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Attribute key", text: self.$key)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Attribute value", text: self.$value)
                        .textInputAutocapitalization(.never)
                } footer: {
                    Text(
                        "Subscriber attributes are part of checkpoint rule evaluation. " +
                        "Changing one here can change which rule matches on the next checkpoint."
                    )
                }
            }
            .navigationTitle("Subscriber attribute")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .confirmationAction) {
                    Button("Unset", role: .destructive) {
                        self.updateAttribute(value: "")
                    }
                    .disabled(!self.hasKey)

                    Button("Set") {
                        self.updateAttribute(value: self.value)
                    }
                    .disabled(!self.hasKey)
                }
            }
        }
    }

    private var trimmedKey: String {
        return self.key.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasKey: Bool {
        return !self.trimmedKey.isEmpty
    }

    private func updateAttribute(value: String) {
        Purchases.shared.attribution.setAttributes([self.trimmedKey: value])
        self.dismiss()
    }

}
