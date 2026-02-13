//
//  OfferingsListView.swift
//  RCTTester
//

import SwiftUI
import StoreKit
import RevenueCat
import RevenueCatUI

struct OfferingsListView: View {

    private enum LoadingState {
        case loading
        case loaded([Offering])
        case error(Error)
    }

    let configuration: SDKConfiguration
    let purchaseManager: AnyPurchaseManager

    @State private var loadingState: LoadingState = .loading
    @State private var offeringForPaywall: Offering?
    @State private var paywallIfNeededPresentation: PaywallIfNeededPresentation?
    @State private var offeringForPaywallView: Offering?
    @State private var offeringForMetadata: Offering?
    @State private var storeViewPresentation: StoreViewPresentation?
    @State private var showingStoreViewUnavailableAlert = false

    var body: some View {
        Group {
            switch loadingState {
            case .loading:
                ProgressView("Loading offerings...")

            case .error(let error):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Failed to load offerings")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task {
                            await fetchOfferings()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()

            case .loaded(let offerings):
                if offerings.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(offerings) { offering in
                            OfferingSectionView(
                                offering: offering,
                                configuration: configuration,
                                purchaseManager: purchaseManager,
                                onPresentPaywall: { type in
                                    switch type {
                                    case .presentPaywall:
                                        offeringForPaywall = offering
                                    case .presentPaywallIfNeeded(let entitlementIdentifier):
                                        paywallIfNeededPresentation = PaywallIfNeededPresentation(
                                            offering: offering,
                                            entitlementIdentifier: entitlementIdentifier
                                        )
                                    case .paywallView:
                                        offeringForPaywallView = offering
                                    }
                                },
                                onShowMetadata: {
                                    offeringForMetadata = offering
                                },
                                onPresentStoreView: { sheetType in
                                    if configuration.storeKitVersion == .storeKit2 {
                                        storeViewPresentation = StoreViewPresentation(
                                            offering: offering,
                                            sheetType: sheetType
                                        )
                                    } else {
                                        showingStoreViewUnavailableAlert = true
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Offerings")
        .refreshable {
            await fetchOfferings(showLoading: false)
        }
        .presentPaywall(
            offering: $offeringForPaywall,
            myAppPurchaseLogic: purchaseManager.myAppPurchaseLogic,
            onDismiss: {
                print(".presentPaywall dismissed")
            }
        )
        .sheet(item: $paywallIfNeededPresentation) { presentation in
            NavigationView {
                PresentPaywallIfNeededView(
                    offering: presentation.offering,
                    entitlementIdentifier: presentation.entitlementIdentifier,
                    myAppPurchaseLogic: purchaseManager.myAppPurchaseLogic
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            paywallIfNeededPresentation = nil
                        }
                    }
                }
            }
        }
        .sheet(item: $offeringForPaywallView) { offering in
            PaywallView(
                offering: offering,
                displayCloseButton: true,
                performPurchase: purchaseManager.myAppPurchaseLogic?.performPurchase,
                performRestore: purchaseManager.myAppPurchaseLogic?.performRestore
            )
        }
        .sheet(item: $offeringForMetadata) { offering in
            OfferingMetadataView(offering: offering)
        }
        .modifier(StoreViewSheetModifier(storeViewPresentation: $storeViewPresentation))
        .alert("Unavailable", isPresented: $showingStoreViewUnavailableAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("StoreView and SubscriptionStoreView require StoreKit 2. "
                 + "Reconfigure the SDK with StoreKit 2 to use these views.")
        }
        .task {
            await fetchOfferings()
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        if #available(iOS 17.0, *) {
            ContentUnavailableView(
                "No Offerings",
                systemImage: "tag.slash",
                description: Text("No offerings are configured for this app.")
            )
        } else {
            VStack(spacing: 16) {
                Image(systemName: "tag.slash")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No Offerings")
                    .font(.headline)
                Text("No offerings are configured for this app.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }

    private func fetchOfferings(showLoading: Bool = true) async {
        if showLoading {
            loadingState = .loading
        }
        do {
            let fetchedOfferings = try await Purchases.shared.offerings()
            let currentOffering = fetchedOfferings.current

            // Sort by identifier, keeping the current offering first
            let sortedOfferings = fetchedOfferings.all.values.sorted { lhs, rhs in
                let lhsIsCurrent = lhs.identifier == currentOffering?.identifier
                let rhsIsCurrent = rhs.identifier == currentOffering?.identifier
                if lhsIsCurrent != rhsIsCurrent {
                    return lhsIsCurrent
                }
                return lhs.identifier < rhs.identifier
            }
            loadingState = .loaded(sortedOfferings)
        } catch {
            loadingState = .error(error)
            print("Error fetching offerings: \(error)")
        }
    }
}

// MARK: - presentPaywallIfNeeded Presentation

/// Pairs an offering with the entitlement identifier for `.presentPaywallIfNeeded`.
private struct PaywallIfNeededPresentation: Identifiable {
    let offering: Offering
    let entitlementIdentifier: String

    var id: String { "\(offering.identifier)-\(entitlementIdentifier)" }
}

// MARK: - StoreView Presentation

/// Pairs an offering with the type of StoreKit view to present.
private struct StoreViewPresentation: Identifiable {
    let offering: Offering
    let sheetType: StoreViewSheetType

    var id: String { "\(offering.identifier)-\(sheetType.id)" }
}

/// Encapsulates the `@available(iOS 17.0, *)` sheet presentation for `StoreView` and
/// `SubscriptionStoreView`, avoiding the need for `@available` on the entire parent view.
private struct StoreViewSheetModifier: ViewModifier {

    @Binding var storeViewPresentation: StoreViewPresentation?

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .sheet(item: $storeViewPresentation) { presentation in
                    switch presentation.sheetType {
                    case .storeView:
                        VStack(spacing: 0) {
                            Text("StoreView")
                                .font(.headline)
                                .padding()
                            StoreView.forOffering(presentation.offering)
                        }
                    case .subscriptionStoreView:
                        SubscriptionStoreView.forOffering(presentation.offering)
                    }
                }
        } else {
            content
        }
    }
}

#Preview {
    NavigationView {
        OfferingsListView(
            configuration: .default,
            purchaseManager: AnyPurchaseManager(RevenueCatPurchaseManager())
        )
    }
}
