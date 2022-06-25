//
//  HomeView.swift
//  PurchaseTester
//
//  Created by Josh Holtz on 2/1/22.
//

import Foundation
import SwiftUI
import RevenueCat

struct HomeView: View {
    @EnvironmentObject var revenueCatCustomerData: RevenueCatCustomerData
    
    @State var offerings: [RevenueCat.Offering] = []
    
    @State private var showingAlert = false
    @State private var newAppUserID: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            CustomerInfoHeaderView() { action in
                switch action {
                case .login: self.showLogin()
                case .logout: self.logout()
                }
            }.padding(.horizontal, 20)
            
            List {
                Section("Offerings") {
                    ForEach(self.offerings) { offering in
                        NavigationLink(destination: OfferingDetailView(offering: offering)) {
                            OfferingItemView(offering: offering)
                        }
                    }
                }
                
                Section("Functions") {
                    Button {
                        Task<Void, Never> {
                            do {
                                let customerInfo = try await Purchases.shared.restorePurchases()
                                print("🚀 Info 💁‍♂️ - Customer Info: \(customerInfo)")
                            } catch {
                                print("🚀 Info 💁‍♂️ - Error: \(error)")
                            }
                        }
                    } label: {
                        Text("Restore Purchases")
                    }
                    
                    Button {
                        Task<Void, Never> {
                            do {
                                let customerInfo = try await Purchases.shared.syncPurchases()
                                print("🚀 Info 💁‍♂️ - Customer Info: \(customerInfo)")
                            } catch {
                                print("🚀 Info 💁‍♂️ - Error: \(error)")
                            }
                        }
                    } label: {
                        Text("Sync Purchases")
                    }
                    
                    Button {
                        Purchases.shared.presentCodeRedemptionSheet()
                    } label: {
                        Text("Redemption Sheet")
                    }
                    
                    Button {
                        Task<Void, Never> {
                            do {
                                try await Purchases.shared.showManageSubscriptions()
                            } catch {
                                print("🚀 Info 💁‍♂️ - Error: \(error)")
                            }
                        }
                    } label: {
                        Text("Manage Subscriptions")
                    }
                    
                    Button {
                        Task<Void, Never> {
                            do {
                                try await Purchases.shared.beginRefundRequestForActiveEntitlement()
                            } catch {
                                print("🚀 Info 💁‍♂️ - Error: \(error)")
                            }
                        }
                    } label: {
                        Text("Begin Refund For Active Entitlement")
                    }
                }
            }
                .padding()
                .task {
                    await self.fetchData()
                }

        }
        .navigationTitle("PurchaseTester")
        .textFieldAlert(isShowing: self.$showingAlert, title: "App User ID", fields: [("User ID", "ID of your user", self.$newAppUserID)]) {
            guard !self.newAppUserID.isEmpty else {
                return
            }
            
            Task {
                do {
                    let (customerInfo, created) = try await Purchases.shared.logIn(self.newAppUserID)
                    print("🚀 Info 💁‍♂️ - Customer Info: \(customerInfo)")
                    print("🚀 Info 💁‍♂️ - Created: \(created)")
                } catch {
                    print("🚀 Info 💁‍♂️ - Error: \(error)")
                }
            }
        }
    }
    
    private func fetchData() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            self.offerings = Array(offerings.all.values).sorted(by: { a, b in
                return b.identifier > a.identifier
            })
        } catch {
            print("🚀 Info 💁‍♂️ - Error: \(error)")
        }
    }
    
    private func showLogin() {
        self.newAppUserID = ""
        self.showingAlert = true
    }
    
    private func logout() {
        Purchases.shared.logOut { customerInfo, error in
            print("🚀 Info 💁‍♂️ - Customer Info: \(customerInfo)")
            print("🚀 Info 💁‍♂️ - Error: \(error)")
        }
    }
}

private struct CustomerInfoHeaderView: View {
    @EnvironmentObject var revenueCatCustomerData: RevenueCatCustomerData
    
    typealias Completion = (Action) -> ()
    enum Action {
        case login, logout
    }

    let completion: Completion
    
    init(completion: @escaping Completion) {
        self.completion = completion
    }
    
    var customerInfo: RevenueCat.CustomerInfo? {
        return self.revenueCatCustomerData.customerInfo
    }
    
    var appUserID: String? {
        return self.revenueCatCustomerData.appUserID ?? self.customerInfo?.originalAppUserId
    }
    
    var activeEntitlementInfos: [RevenueCat.EntitlementInfo] {
        guard let customerInfo = customerInfo else {
            return []
        }
        return Array(customerInfo.entitlements.all.values)
            .filter { $0.isActive }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(appUserID ?? "... loading")
            if activeEntitlementInfos.isEmpty {
                Text("No active entitlements")
            } else {
                Text(activeEntitlementInfos.map({$0.identifier}).joined(separator: ", "))
            }
            
            HStack {
                Spacer()
                
                if let customerInfo = self.customerInfo {
                    NavigationLink(destination: CustomerView(customerInfo: customerInfo)) {
                        Text("View Info")
                    }
                } else {
                    Text("View Info")
                }
                
                Spacer()
                if Purchases.shared.isAnonymous {
                    Button {
                        self.completion(.login)
                    } label: {
                        Text("Login")
                    }
                } else {
                    Button {
                        self.completion(.logout)
                    } label: {
                        Text("Logout")
                    }
                }
                Spacer()
            }.padding(.top, 20)
        }
    }
}

private struct OfferingItemView: View {
    let offering: RevenueCat.Offering
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(offering.serverDescription)
            Text(offering.identifier)
            Text("\(offering.availablePackages.count) package(s)")
        }
    }
}
