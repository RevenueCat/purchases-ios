import SwiftUI
import RevenueCat

struct OfferingsView: View {
    @Environment(UserViewModel.self) private var userViewModel
    @State private var selectedOffering: Offering?
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(spacing: 16) {
                    if userViewModel.isFetchingOfferings {
                        Text("Fetching offerings")
                    } else if let offerings = userViewModel.offerings {
                        ScrollView(.vertical) {
                            VStack(spacing: 12) {
                                ScrollView(.horizontal) {
                                    HStack(spacing: 12) {
                                        ForEach(Array(offerings.all.values)) { offering in
                                            Button(action: { selectedOffering = offering }) {
                                                Text(offering.identifier)
                                                    .textCase(.uppercase)
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .padding(.vertical, 12)
                                                    .padding(.horizontal, 16)
                                                    .background(selectedOffering == offering ? Color.accentColor : .secondary.opacity(0.2))
                                                    .foregroundStyle(selectedOffering == offering ? Color.white : .primary)
                                                    .clipShape(Capsule())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                
                                if let selectedOffering {
                                    ForEach(selectedOffering.availablePackages) { package in
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(package.identifier)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .textCase(.uppercase)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .fontWeight(.heavy)
                                                .padding(.top, 12)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(package.storeProduct.productIdentifier)
                                                    .font(.headline)
                                                Text(package.storeProduct.localizedTitle)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                                Text(package.storeProduct.localizedPriceString)
                                                    .fontWeight(.semibold)
                                            }
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding()
                                            .background(.secondary.opacity(0.3))
                                            .clipShape(.rect(cornerRadius: 12))
                                            
                                            Label("Correctly configured in App Store Connect", systemImage: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                                .font(.caption)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .foregroundStyle(.secondary)
                                                .fontWeight(.semibold)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .clipShape(.rect(cornerRadius: 8))
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .task { await userViewModel.fetchOfferings() }
            .refreshable { Task { await userViewModel.fetchOfferings() } }
            .onChange(of: userViewModel.offerings) {
                selectedOffering = userViewModel.offerings?.current
            }
            .navigationTitle("Offerings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
