//
//  LocalPaywallOverrideEditorView.swift
//  PaywallsTester
//
//  Created by RevenueCat on 5/21/26.
//

import SwiftUI

#if os(iOS)

struct LocalPaywallOverrideEditorView: View {

    @Environment(\.dismiss) private var dismiss

    @State
    private var settings = LocalPaywallOfferingsOverrideStore.settings

    @State
    private var packageMappings: [PackageMappingItem] = []

    @State
    private var isAddingPackageMapping = false

    @State
    private var newPackageIdentifier = ""

    @State
    private var newProductIdentifier = ""

    var onSave: () -> Void

    var body: some View {
        NavigationView {
            List {
                statusSection
                paywallComponentsSection
                packageMappingsSection
                uiConfigSection
            }
            .navigationTitle("Local Paywall JSON")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(settings.isActive && validationMessage != nil)
                }
            }
            .onAppear {
                loadPackageMappings()
            }
        }
    }

}

private extension LocalPaywallOverrideEditorView {

    var statusSection: some View {
        Section {
            if settings.isActive {
                Label("Local offerings override enabled", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Label("Paste paywall JSON to enable the override", systemImage: "pause.circle")
                    .foregroundColor(.secondary)
            }

            if let validationMessage {
                Text(validationMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
            } else if settings.isActive {
                Text("Save and refresh Live Paywalls to load this JSON through the SDK offerings endpoint.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }

    var paywallComponentsSection: some View {
        Section {
            TextEditor(text: $settings.paywallComponentsJSON)
                .font(.system(.caption, design: .monospaced))
                .frame(minHeight: 220)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            Button("Clear Paywall JSON", role: .destructive) {
                settings.paywallComponentsJSON = ""
            }
            .disabled(settings.paywallComponentsJSON.isEmpty)
        } header: {
            Text("Paywall components JSON")
        } footer: {
            Text("Paste the dashboard paywall components object. Clearing this field disables the override.")
        }
    }

    var packageMappingsSection: some View {
        Section {
            if packageMappings.isEmpty {
                Text("No package mappings defined.")
                    .foregroundColor(.secondary)
            } else {
                ForEach($packageMappings) { $mapping in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Package identifier", text: $mapping.packageIdentifier)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        TextField("Product identifier", text: $mapping.productIdentifier)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
                .onDelete(perform: deletePackageMappings)
            }

            if isAddingPackageMapping {
                addPackageMappingView
            }

            HStack {
                Button {
                    resetPackageMappings()
                } label: {
                    Label("Reset defaults", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.borderless)

                Spacer()

                Button {
                    withAnimation {
                        isAddingPackageMapping = true
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .disabled(isAddingPackageMapping)
            }
        } header: {
            Text("Package to product mapping")
        } footer: {
            Text("Package IDs found in the JSON are mapped to StoreKit product IDs from the tester configuration.")
        }
    }

    var uiConfigSection: some View {
        Section {
            TextEditor(text: $settings.uiConfigJSON)
                .font(.system(.caption, design: .monospaced))
                .frame(minHeight: 180)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            HStack {
                Button("Use default UI config") {
                    settings.uiConfigJSON = LocalPaywallOfferingsOverrideSettings.defaultUIConfigJSON
                }
                .buttonStyle(.borderless)

                Spacer()

                Button("Clear") {
                    settings.uiConfigJSON = ""
                }
                .buttonStyle(.borderless)
            }
        } header: {
            Text("Mock UI config JSON")
        } footer: {
            Text("Leave empty to use the tester default mock UI config.")
        }
    }

    var addPackageMappingView: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Package identifier", text: $newPackageIdentifier)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            TextField("Product identifier", text: $newProductIdentifier)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            HStack {
                Button("Cancel", role: .destructive) {
                    cancelAddPackageMapping()
                }
                .buttonStyle(.borderless)

                Spacer()

                Button("Add") {
                    addPackageMapping()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canAddPackageMapping)
            }
        }
    }

    var validationMessage: String? {
        guard settings.isActive else {
            return nil
        }

        do {
            var candidate = settings
            candidate.productIdentifiersByPackageIdentifier = packageMappingsDictionary
            _ = try LocalPaywallOfferingsResponseFactory.makeOfferingsResponseData(settings: candidate)
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    var packageMappingsDictionary: [String: String] {
        return packageMappings.reduce(into: [:]) { result, item in
            let packageIdentifier = item.packageIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
            let productIdentifier = item.productIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)

            if !packageIdentifier.isEmpty, !productIdentifier.isEmpty {
                result[packageIdentifier] = productIdentifier
            }
        }
    }

    var canAddPackageMapping: Bool {
        return !newPackageIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !newProductIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func loadPackageMappings() {
        packageMappings = settings.productIdentifiersByPackageIdentifier
            .map { PackageMappingItem(packageIdentifier: $0.key, productIdentifier: $0.value) }
            .sorted { $0.packageIdentifier < $1.packageIdentifier }
    }

    func save() {
        settings.productIdentifiersByPackageIdentifier = packageMappingsDictionary
        LocalPaywallOfferingsOverrideStore.settings = settings
        onSave()
        dismiss()
    }

    func addPackageMapping() {
        packageMappings.append(
            .init(
                packageIdentifier: newPackageIdentifier.trimmingCharacters(in: .whitespacesAndNewlines),
                productIdentifier: newProductIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
        packageMappings.sort { $0.packageIdentifier < $1.packageIdentifier }
        cancelAddPackageMapping()
    }

    func cancelAddPackageMapping() {
        withAnimation {
            isAddingPackageMapping = false
        }
        newPackageIdentifier = ""
        newProductIdentifier = ""
    }

    func deletePackageMappings(at offsets: IndexSet) {
        packageMappings.remove(atOffsets: offsets)
    }

    func resetPackageMappings() {
        settings.productIdentifiersByPackageIdentifier =
            LocalPaywallOfferingsOverrideSettings.defaultProductIdentifiersByPackageIdentifier
        loadPackageMappings()
    }

}

private struct PackageMappingItem: Identifiable {

    let id = UUID()
    var packageIdentifier: String
    var productIdentifier: String

}

#Preview {
    LocalPaywallOverrideEditorView(onSave: {})
}

#endif
