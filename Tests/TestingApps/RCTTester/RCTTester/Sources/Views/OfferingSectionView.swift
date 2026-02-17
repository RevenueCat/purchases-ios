//
//  OfferingSectionView.swift
//  RCTTester
//

import SwiftUI
import RevenueCat

struct OfferingSectionView: View {

    let offering: Offering
    let purchaseManager: AnyPurchaseManager
    let onPresentPaywall: () -> Void
    let onShowMetadata: () -> Void

    var body: some View {
        Section {
            // Header: Offering info and metadata button
            OfferingHeaderView(
                offering: offering,
                onShowMetadata: onShowMetadata
            )

            // Packages with purchase buttons
            ForEach(offering.availablePackages, id: \.identifier) { package in
                PackageRowView(package: package, purchaseManager: purchaseManager)
            }

            // Present Paywall button (if offering has a paywall)
            if offering.hasPaywall {
                Button {
                    onPresentPaywall()
                } label: {
                    Label("Present Paywall", systemImage: "rectangle.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Offering Header View

private struct OfferingHeaderView: View {

    let offering: Offering
    let onShowMetadata: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(offering.identifier)
                    .font(.headline)
                Text(offering.serverDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                onShowMetadata()
            } label: {
                Image(systemName: "info.circle")
                    .font(.title2)
            }
            .buttonStyle(.borderless)
        }
    }
}

// MARK: - Package Row View

private struct PackageRowView: View {

    let package: Package
    let purchaseManager: AnyPurchaseManager

    @State private var isPurchasing = false
    @State private var purchaseError: Error?
    @State private var showError = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(package.storeProduct.localizedTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(package.identifier)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                Task {
                    await performPurchase()
                }
            } label: {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text(package.storeProduct.localizedPriceString)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .disabled(isPurchasing)
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(purchaseError?.localizedDescription ?? "An unknown error occurred")
        }
    }

    @MainActor
    private func performPurchase() async {
        isPurchasing = true
        defer { isPurchasing = false }

        let result = await purchaseManager.purchase(package: package)

        switch result {
        case .success(let customerInfo):
            print("✅ Purchase successful! Active entitlements: \(customerInfo.entitlements.active.keys)")

        case .userCancelled:
            print("⚠️ Purchase cancelled by user")

        case .pending:
            print("⏳ Purchase pending approval (e.g., Ask to Buy)")

        case .failure(let error):
            print("❌ Purchase failed: \(error)")
            purchaseError = error
            showError = true
        }
    }
}

// MARK: - Offering Metadata View

struct OfferingMetadataView: View {

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
                            Text(package.storeProduct.localizedTitle)
                                .font(.headline)
                            Text(package.identifier)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
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
    List {
        OfferingSectionView(
            offering: Offering(
                identifier: "default",
                serverDescription: "The default offering",
                availablePackages: [],
                webCheckoutUrl: nil
            ),
            purchaseManager: AnyPurchaseManager(RevenueCatPurchaseManager()),
            onPresentPaywall: {},
            onShowMetadata: {}
        )
    }
}
