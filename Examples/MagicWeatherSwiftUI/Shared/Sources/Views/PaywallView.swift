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
    
    /// - State for displaying an overlay view
    @State
    private(set) var isPurchasing: Bool = false
    
    /// - The current offering saved from PurchasesDelegateHandler
    private(set) var offering: Offering? = UserViewModel.shared.offerings?.current
    
    private let footerText = "Don't forget to add your subscription terms and conditions. Read more about this here: https://www.revenuecat.com/blog/schedule-2-section-3-8-b"
    
    @State private var error: NSError?
    @State private var displayError: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                /// - The paywall view list displaying each package
                List {
                    Section(header: Text("\nMagic Weather Premium"), footer: Text(footerText)) {
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
                                        self.isPresented = false
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
}

/* The cell view for each package */
struct PackageCellView: View {

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
                    Text(package.terms(for: package))
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
