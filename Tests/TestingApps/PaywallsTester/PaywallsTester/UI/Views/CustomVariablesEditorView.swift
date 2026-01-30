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
    @State private var newVariableType: VariableType = .string
    @State private var newVariableStringValue = ""
    @State private var newVariableNumberValue = ""
    @State private var newVariableBoolValue = false

    struct VariableItem: Identifiable {
        let id = UUID()
        var key: String
        var value: CustomVariableValue
    }

    enum VariableType: String, CaseIterable {
        case string = "String"
        case number = "Number"
        case bool = "Boolean"
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

            Picker("Type", selection: $newVariableType) {
                ForEach(VariableType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }

            valueInput

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
                .disabled(newVariableName.isEmpty || !isValidValue)
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
            Text(typeLabel(for: value))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
        }
    }

    private func typeLabel(for value: CustomVariableValue) -> String {
        // Determine type by checking the string representation
        if value.boolValue && (value.stringValue == "true" || value.stringValue == "false") {
            return "Bool"
        } else if Double(value.stringValue) != nil && !value.stringValue.isEmpty {
            return "Number"
        } else {
            return "String"
        }
    }

    @ViewBuilder
    private var valueInput: some View {
        switch newVariableType {
        case .string:
            TextField("Value", text: $newVariableStringValue)
        case .number:
            TextField("Value", text: $newVariableNumberValue)
                #if !os(watchOS)
                .keyboardType(.decimalPad)
                #endif
        case .bool:
            Toggle("Value", isOn: $newVariableBoolValue)
        }
    }

    private var isValidValue: Bool {
        switch newVariableType {
        case .string:
            return true
        case .number:
            return newVariableNumberValue.isEmpty || Double(newVariableNumberValue) != nil
        case .bool:
            return true
        }
    }

    private func addVariable() {
        guard !newVariableName.isEmpty else { return }

        let value: CustomVariableValue
        switch newVariableType {
        case .string:
            value = .string(newVariableStringValue)
        case .number:
            value = .number(Double(newVariableNumberValue) ?? 0)
        case .bool:
            value = .bool(newVariableBoolValue)
        }

        // Add to local list
        let newItem = VariableItem(key: newVariableName, value: value)
        variablesList.append(newItem)
        variablesList.sort { $0.key < $1.key }

        // Also sync to binding immediately
        syncToBinding()

        cancelAddVariable()
    }

    private func cancelAddVariable() {
        withAnimation {
            isAddingVariable = false
        }
        newVariableName = ""
        newVariableType = .string
        newVariableStringValue = ""
        newVariableNumberValue = ""
        newVariableBoolValue = false
    }

    private func deleteVariables(at offsets: IndexSet) {
        variablesList.remove(atOffsets: offsets)
        syncToBinding()
    }

}

#Preview {
    CustomVariablesEditorView(variables: .constant([
        "player_name": .string("John"),
        "level": .number(42),
        "is_premium": .bool(true)
    ]))
}
