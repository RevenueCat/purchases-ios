//
//  OfferingRowView.swift
//  RCTTester
//

import SwiftUI
import RevenueCat

struct OfferingRowView: View {

    let offering: Offering
    let onShowPaywall: () -> Void

    @State private var showingMetadata = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Offering info and metadata button
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(offering.identifier)
                        .font(.headline)
                    Text(offering.serverDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(offering.availablePackages.count) package(s)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    showingMetadata = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    print("🚧 WIP: Purchase action for offering '\(offering.identifier)'")
                } label: {
                    Label("Purchase", systemImage: "cart")
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)

                if offering.hasPaywall {
                    Button {
                        onShowPaywall()
                    } label: {
                        Label("Show Paywall", systemImage: "rectangle.on.rectangle")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingMetadata) {
            OfferingMetadataView(offering: offering)
        }
    }
}

// MARK: - Offering Metadata View

private struct OfferingMetadataView: View {

    let offering: Offering

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("Basic Info") {
                    MetadataRow(label: "Identifier", value: offering.identifier)
                    MetadataRow(label: "Description", value: offering.serverDescription)
                    MetadataRow(label: "Has Paywall", value: offering.hasPaywall ? "Yes" : "No")
                }

                Section("Packages (\(offering.availablePackages.count))") {
                    ForEach(offering.availablePackages, id: \.identifier) { package in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(package.identifier)
                                .font(.headline)
                            Text(package.storeProduct.localizedTitle)
                                .font(.subheadline)
                            Text(package.storeProduct.localizedPriceString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                if !offering.metadata.isEmpty {
                    Section("Metadata") {
                        ForEach(Array(offering.metadata.keys.sorted()), id: \.self) { key in
                            MetadataRow(label: key, value: String(describing: offering.metadata[key] ?? "nil"))
                        }
                    }
                }

                Section("Standard Packages") {
                    MetadataRow(label: "Lifetime", value: offering.lifetime?.identifier ?? "—")
                    MetadataRow(label: "Annual", value: offering.annual?.identifier ?? "—")
                    MetadataRow(label: "Six Month", value: offering.sixMonth?.identifier ?? "—")
                    MetadataRow(label: "Three Month", value: offering.threeMonth?.identifier ?? "—")
                    MetadataRow(label: "Two Month", value: offering.twoMonth?.identifier ?? "—")
                    MetadataRow(label: "Monthly", value: offering.monthly?.identifier ?? "—")
                    MetadataRow(label: "Weekly", value: offering.weekly?.identifier ?? "—")
                }
            }
            .navigationTitle("Offering Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Metadata Row

private struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    OfferingRowView(
        offering: Offering(
            identifier: "default",
            serverDescription: "The default offering",
            availablePackages: [],
            webCheckoutUrl: nil
        ),
        onShowPaywall: {}
    )
}
