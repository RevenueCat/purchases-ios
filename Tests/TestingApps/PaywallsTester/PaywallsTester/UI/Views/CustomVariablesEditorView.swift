//
//  CustomVariablesEditorView.swift
//  PaywallsTester
//
//  Created by RevenueCat on 2026.
//

import RevenueCat
#if DEBUG
@testable import RevenueCatUI
#else
import RevenueCatUI
#endif
import SwiftUI

struct CustomVariablesEditorView: View {

    @Binding var variables: [String: CustomVariableValue]
    @Environment(\.dismiss) private var dismiss

    // Use local state for the list to ensure proper SwiftUI updates
    @State private var variablesList: [VariableItem] = []

    @State private var isAddingVariable = false
    @State private var newVariableName = ""
    @State private var newVariableValue = ""

    struct VariableItem: Identifiable {
        let id = UUID()
        var key: String
        var value: CustomVariableValue
    }

    var body: some View {
        NavigationView {
            List {
                variablesSection

                if isAddingVariable {
                    addVariableSection
                }
            }
            .navigationTitle("Custom Variables")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        syncToBinding()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation {
                            isAddingVariable = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(isAddingVariable)
                }
            }
            .onAppear {
                loadFromBinding()
            }
        }
    }

    private func loadFromBinding() {
        variablesList = variables.map { VariableItem(key: $0.key, value: $0.value) }
            .sorted { $0.key < $1.key }
    }

    private func syncToBinding() {
        var newDict: [String: CustomVariableValue] = [:]
        for item in variablesList {
            newDict[item.key] = item.value
        }
        variables = newDict
    }

    @ViewBuilder
    private var variablesSection: some View {
        Section {
            if variablesList.isEmpty {
                Text("No custom variables defined. Tap '+' to add one.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(variablesList) { item in
                    variableRow(key: item.key, value: item.value)
                }
                .onDelete(perform: deleteVariables)
            }
        } header: {
            if !variablesList.isEmpty {
                Text("Current Variables (\(variablesList.count))")
            }
        }
    }

    @ViewBuilder
    private var addVariableSection: some View {
        Section {
            TextField("Variable name", text: $newVariableName)
                #if !os(watchOS)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()

            TextField("Value", text: $newVariableValue)

            HStack {
                Button("Cancel", role: .destructive) {
                    cancelAddVariable()
                }
                .buttonStyle(.borderless)

                Spacer()

                Button("Add") {
                    addVariable()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newVariableName.isEmpty)
            }
            .padding(.vertical, 4)
        } header: {
            Text("New Variable")
        }
    }

    @ViewBuilder
    private func variableRow(key: String, value: CustomVariableValue) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(key)
                    .font(.headline)
                Text(value.stringValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    private func addVariable() {
        guard !newVariableName.isEmpty else { return }

        let newItem = VariableItem(key: newVariableName, value: .string(newVariableValue))
        variablesList.append(newItem)
        variablesList.sort { $0.key < $1.key }

        syncToBinding()
        cancelAddVariable()
    }

    private func cancelAddVariable() {
        withAnimation {
            isAddingVariable = false
        }
        newVariableName = ""
        newVariableValue = ""
    }

    private func deleteVariables(at offsets: IndexSet) {
        variablesList.remove(atOffsets: offsets)
        syncToBinding()
    }

}

#Preview {
    CustomVariablesEditorView(variables: .constant([
        "player_name": .string("John"),
        "level": .string("42"),
        "is_premium": .string("true")
    ]))
}
