//
//  OfferingsListView.swift
//  RCTTester
//

import SwiftUI
import RevenueCat
import RevenueCatUI

struct OfferingsListView: View {

    private enum LoadingState {
        case loading
        case loaded([Offering])
        case error(Error)
    }

    @State private var loadingState: LoadingState = .loading
    @State private var offeringForPaywall: Offering?
    @State private var offeringForMetadata: Offering?

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
                                onPresentPaywall: {
                                    offeringForPaywall = offering
                                },
                                onShowMetadata: {
                                    offeringForMetadata = offering
                                }
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Offerings")
        .refreshable {
            await refreshOfferings()
        }
        .presentPaywall(
            offering: $offeringForPaywall,
            onDismiss: {
                print("Paywall dismissed")
            }
        )
        .sheet(item: $offeringForMetadata) { offering in
            OfferingMetadataView(offering: offering)
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

    private func fetchOfferings() async {
        loadingState = .loading
        await loadOfferings()
    }

    private func refreshOfferings() async {
        await loadOfferings()
    }

    private func loadOfferings() async {
        do {
            let fetchedOfferings = try await Purchases.shared.offerings()
            let sortedOfferings = Array(fetchedOfferings.all.values).sorted { $0.identifier < $1.identifier }
            loadingState = .loaded(sortedOfferings)
        } catch {
            loadingState = .error(error)
            print("Error fetching offerings: \(error)")
        }
    }
}

#Preview {
    NavigationView {
        OfferingsListView()
    }
}
