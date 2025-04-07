import SwiftUI
import RevenueCat

struct OfferingsView: View {
    @Environment(UserViewModel.self) private var userViewModel
    @State private var selectedOffering: OfferingViewModel?
    @State private var offerings = [OfferingViewModel]()
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(offerings) { offering in
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
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                List {
                    if let selectedOffering {
                        ForEach(selectedOffering.packages) { package in
                            Section {
                                VStack(alignment: .leading, spacing: 20) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(package.title)
                                            .font(.headline)
                                        Text(package.productIdentifier)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        if let price = package.price {
                                            Text(price)
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    
                                    HStack(alignment: .center, spacing: 8) {
                                        Image(systemName: package.status.icon)
                                        Text(package.statusHelperText)
                                    }
                                    .foregroundStyle(package.status.color)
                                    .font(.caption)
                                }
                            } header: {
                                Text(package.identifier)
                                    .fontWeight(.semibold)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .blur(radius: isLoading ? 5 : 0)
                .overlay {
                    if isLoading {
                        VStack {
                            Spinner()
                            Text("Loading...")
                                .font(.headline)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear(perform: loadData)
            .refreshable(action: loadData)
            .navigationTitle("Offerings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func loadData() {
        Task {
            isLoading = true
            await userViewModel.fetchOfferings()
            do {
                try await checkAppHealth()
            } catch let error {
                print(error)
            }
            isLoading = false
        }
    }
    
    private func checkAppHealth() async throws {
        let healthCheck = try await Purchases.shared.checkAppHealth()
        self.offerings = healthCheck.offerings.map { backendOffering in
            let sdkOffering = userViewModel.offerings?[backendOffering.identifier]
            return OfferingViewModel(
                identifier: backendOffering.identifier,
                packages: backendOffering.products.map { backendProduct in
                    let sdkPackage = sdkOffering?.package(identifier: backendProduct.packageIdentifier)
                    return PackageViewModel(
                        identifier: sdkPackage?.identifier ?? backendProduct.packageIdentifier,
                        productIdentifier: backendProduct.status.productIdentifier,
                        title: sdkPackage?.storeProduct.localizedTitle ?? backendProduct.status.productTitle ?? "",
                        price: sdkPackage?.storeProduct.localizedPriceString,
                        status: backendProduct.status.status,
                        statusHelperText: backendProduct.status.helperText
                    )
                }
            )
        }
        self.selectedOffering = offerings.first
    }
}
