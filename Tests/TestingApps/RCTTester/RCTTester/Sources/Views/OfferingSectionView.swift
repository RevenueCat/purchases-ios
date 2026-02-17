//
//  OfferingSectionView.swift
//  RCTTester
//

import SwiftUI
import StoreKit
import RevenueCat

struct OfferingSectionView: View {

    let offering: Offering
    let configuration: SDKConfiguration
    let purchaseManager: AnyPurchaseManager
    let onPresentPaywall: (PaywallPresentationType) -> Void
    let onShowMetadata: () -> Void
    let onPresentStoreView: (StoreViewSheetType) -> Void

    private static let knownEntitlements = ["lite", "premium"]

    @State private var showCustomEntitlementAlert = false
    @State private var customEntitlementText = ""

    private var isStoreKit2: Bool {
        configuration.storeKitVersion == .storeKit2
    }

    var body: some View {
        Section {
            // Header: Offering info and metadata button
            OfferingHeaderView(
                offering: offering,
                onShowMetadata: onShowMetadata
            )

            // Packages with purchase buttons
            ForEach(offering.availablePackages, id: \.identifier) { package in
                PackageRowView(
                    package: package,
                    configuration: configuration,
                    purchaseManager: purchaseManager
                )
            }

            // Present Paywall menu (if offering has a paywall)
            if offering.hasPaywall {
                Menu {
                    Button(".presentPaywall") {
                        onPresentPaywall(.presentPaywall)
                    }
                    Menu(".presentPaywallIfNeeded") {
                        Section("requiredEntitlementIdentifier") {
                            ForEach(Self.knownEntitlements, id: \.self) { entitlementID in
                                Button(entitlementID) {
                                    onPresentPaywall(.presentPaywallIfNeeded(entitlementIdentifier: entitlementID))
                                }
                            }
                            Button("Custom...") {
                                customEntitlementText = ""
                                showCustomEntitlementAlert = true
                            }
                        }
                    }
                    Button("PaywallView") {
                        onPresentPaywall(.paywallView)
                    }
                } label: {
                    Label("Present Paywall", systemImage: "rectangle.on.rectangle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // StoreView and SubscriptionStoreView buttons (iOS 17+ / SK2 only)
            if #available(iOS 17.0, *) {
                Button {
                    onPresentStoreView(.storeView)
                } label: {
                    HStack {
                        Label("Present StoreView", systemImage: "storefront")
                        if !isStoreKit2 {
                            Spacer()
                            Image(systemName: "nosign")
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    onPresentStoreView(.subscriptionStoreView)
                } label: {
                    HStack {
                        Label("Present SubscriptionStoreView", systemImage: "storefront")
                        if !isStoreKit2 {
                            Spacer()
                            Image(systemName: "nosign")
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .alert("Custom Entitlement", isPresented: $showCustomEntitlementAlert) {
            TextField("Entitlement identifier", text: $customEntitlementText)
            Button("Present") {
                onPresentPaywall(.presentPaywallIfNeeded(entitlementIdentifier: customEntitlementText))
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter the entitlement identifier to check.")
        }
    }
}

// MARK: - Paywall Presentation Type

/// Represents which API to use when presenting a paywall.
enum PaywallPresentationType {

    /// Use the `.presentPaywall(offering:)` view modifier.
    case presentPaywall

    /// Use the `.presentPaywallIfNeeded(requiredEntitlementIdentifier:offering:)` view modifier
    /// with the specified entitlement identifier.
    case presentPaywallIfNeeded(entitlementIdentifier: String)

    /// Present a `PaywallView(offering:)` directly in a sheet.
    case paywallView
}

// MARK: - StoreView Sheet Type

/// Represents which StoreKit view sheet to present.
enum StoreViewSheetType: Identifiable {

    /// Present `StoreView.forOffering(_:)`.
    case storeView

    /// Present `SubscriptionStoreView.forOffering(_:)`.
    case subscriptionStoreView

    var id: String {
        switch self {
        case .storeView: return "storeView"
        case .subscriptionStoreView: return "subscriptionStoreView"
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
    let configuration: SDKConfiguration
    let purchaseManager: AnyPurchaseManager

    @State private var isPurchasing = false
    @State private var purchaseError: Error?
    @State private var showError = false

    /// Whether purchases go through RevenueCat APIs (as opposed to StoreKit directly).
    private var purchasesThroughRevenueCat: Bool {
        configuration.purchasesAreCompletedBy == .revenueCat
        || configuration.purchaseLogic == .throughRevenueCat
    }

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

            if isPurchasing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else if purchasesThroughRevenueCat {
                Menu {
                    Button("Purchase Package") {
                        Task { await performPurchase(mode: .package) }
                    }
                    Button("Purchase Product") {
                        Task { await performPurchase(mode: .product) }
                    }
                } label: {
                    Text(package.storeProduct.localizedPriceString)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
            } else {
                Button {
                    Task { await performPurchase(mode: .product) }
                } label: {
                    Text(package.storeProduct.localizedPriceString)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(purchaseError?.localizedDescription ?? "An unknown error occurred")
        }
    }

    private enum PurchaseMode {
        case package
        case product
    }

    @MainActor
    private func performPurchase(mode: PurchaseMode) async {
        isPurchasing = true
        defer { isPurchasing = false }

        let result: PurchaseOperationResult
        switch mode {
        case .package:
            result = await purchaseManager.purchase(package: package)
        case .product:
            result = await purchaseManager.purchase(product: package.storeProduct)
        }

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
            configuration: .default,
            purchaseManager: AnyPurchaseManager(RevenueCatPurchaseManager()),
            onPresentPaywall: { _ in },
            onShowMetadata: {},
            onPresentStoreView: { _ in }
        )
    }
}
