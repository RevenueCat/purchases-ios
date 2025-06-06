//
//  PaywallView.swift
//  Magic Weather SwiftUI
//
//  Created by Cody Kerns on 1/19/21.
//

import SwiftUI
import RevenueCat

/*
 An example paywall that uses the current offering.
 */

struct PaywallView: View {
    
    /// - This binding is passed from ContentView: `paywallPresented`
    @Binding var isPresented: Bool
    
    /// - This can change during the lifetime of the PaywallView (e.g. if poor network conditions mean that loading offerings is slow)
    /// So set this as an observed object to trigger view updates as necessary
    @ObservedObject var userViewModel = UserViewModel.shared
    
    /// - The current offering saved from PurchasesDelegateHandler
    ///  if this is nil, then you might want to show a loading indicator or similar
    private var offering: Offering? {
        userViewModel.offerings?.current
    }

    var body: some View {
        PaywallContent(offering: self.offering, isPresented: self.$isPresented)
    }

}

private struct PaywallContent: View {

    var offering: Offering?
    var isPresented: Binding<Bool>

    /// - State for displaying an overlay view
    @State private var isPurchasing: Bool = false
    @State private var error: NSError?
    @State private var displayError: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                /// - The paywall view list displaying each package
                List {
                    Section(header: Text("\nMagic Weather Premium"), footer: Text(Self.footerText)) {
                        ForEach(offering?.availablePackages ?? []) { package in
                            PackageCellView(package: package) { (package) in

                                /// - Set 'isPurchasing' state to `true`
                                isPurchasing = true

                                /// - Purchase a package
                                do {
                                    let result = try await Purchases.shared.purchase(package: package)

                                    /// - Set 'isPurchasing' state to `false`
                                    self.isPurchasing = false

                                    if !result.userCancelled {
                                        self.isPresented.wrappedValue = false
                                    }
                                } catch {
                                    self.isPurchasing = false
                                    self.error = error as NSError
                                    self.displayError = true
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationBarTitle("✨ Magic Weather Premium")
                .navigationBarTitleDisplayMode(.inline)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.bottom)

                /// - Display an overlay during a purchase
                Rectangle()
                    .foregroundColor(Color.black)
                    .opacity(isPurchasing ? 0.5: 0.0)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .colorScheme(.dark)
        .alert(
            isPresented: self.$displayError,
            error: self.error,
            actions: { _ in
                Button(role: .cancel,
                       action: { self.displayError = false },
                       label: { Text("OK") })
            },
            message: { Text($0.recoverySuggestion ?? "Please try again") }
        )
    }

    private static let footerText = "Don't forget to add your subscription terms and conditions. Read more about this here: https://www.revenuecat.com/blog/schedule-2-section-3-8-b"

}

/* The cell view for each package */
private struct PackageCellView: View {

    let package: Package
    let onSelection: (Package) async -> Void
    
    var body: some View {
        Button {
            Task {
                await self.onSelection(self.package)
            }
        } label: {
            self.buttonLabel
        }
        .buttonStyle(.plain)
    }

    private var buttonLabel: some View {
        HStack {
            VStack {
                HStack {
                    Text(package.storeProduct.localizedTitle)
                        .font(.title3)
                        .bold()
                    
                    Spacer()
                }
                HStack {
                    Text(package.terms)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding([.top, .bottom], 8.0)
            
            Spacer()
            
            Text(package.localizedPriceString)
                .font(.title3)
                .bold()
        }
        .contentShape(Rectangle()) // Make the whole cell tappable
    }

}

extension NSError: LocalizedError {

    public var errorDescription: String? {
        return self.localizedDescription
    }

}

struct PaywallView_Previews: PreviewProvider {

    private static let product1 = TestStoreProduct(
        localizedTitle: "PRO monthly",
        price: 3.99,
        localizedPriceString: "$3.99",
        productIdentifier: "com.revenuecat.product",
        productType: .autoRenewableSubscription,
        localizedDescription: "Description",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: .init(value: 1, unit: .month),
        introductoryDiscount: .init(
            identifier: "intro",
            price: 0,
            localizedPriceString: "$0.00",
            paymentMode: .freeTrial,
            subscriptionPeriod: .init(value: 1, unit: .week),
            numberOfPeriods: 1,
            type: .introductory
        ),
        discounts: []
    )
    private static let product2 = TestStoreProduct(
        localizedTitle: "PRO annual",
        price: 34.99,
        localizedPriceString: "$34.99",
        productIdentifier: "com.revenuecat.product",
        productType: .autoRenewableSubscription,
        localizedDescription: "Description",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: .init(value: 1, unit: .year),
        introductoryDiscount: nil,
        discounts: []
    )

    private static let offering = Offering(
        identifier: Self.offeringIdentifier,
        serverDescription: "Main offering",
        metadata: [:],
        availablePackages: [
            .init(
                identifier: "monthly",
                packageType: .monthly,
                storeProduct: product1.toStoreProduct(),
                offeringIdentifier: Self.offeringIdentifier
            ),
            .init(
                identifier: "annual",
                packageType: .annual,
                storeProduct: product2.toStoreProduct(),
                offeringIdentifier: Self.offeringIdentifier
            )
        ]
    )

    private static let offeringIdentifier = "offering"

    static var previews: some View {
        PaywallContent(offering: Self.offering, isPresented: .constant(true))
    }

}
