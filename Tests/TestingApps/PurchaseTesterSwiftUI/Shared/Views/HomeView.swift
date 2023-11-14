//
//  HomeView.swift
//  PurchaseTester
//
//  Created by Josh Holtz on 2/1/22.
//

import Foundation
import SwiftUI

import Core
import RevenueCat

struct HomeView: View {

    @EnvironmentObject private var revenueCatCustomerData: RevenueCatCustomerData
    @EnvironmentObject private var observerModeManager: ObserverModeManager
    
    @State var offerings: [RevenueCat.Offering] = []
    
    @State private var debugOverlayVisible = false
    @State private var showingAlert = false
    @State private var newAppUserID: String = ""
    @State private var cacheFetchPolicy: CacheFetchPolicy = .default

    @State private var error: Error?
    
    private var content: some View {
        VStack(alignment: .leading) {
            CustomerInfoHeaderView(debugOverlayVisible: self.$debugOverlayVisible) { action in
                switch action {
                case .login: self.showLogin()
                case .logout: await self.logOut()
                }
            }.padding(.horizontal, 20)
            
            List {
                Section("Offerings") {
                    ForEach(self.offerings) { offering in
                        NavigationLink(
                            destination: OfferingDetailView(offering: offering)
                                .environmentObject(self.observerModeManager)
                        ) {
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
                    
                    HStack {
                        Picker("CustomerInfo", selection: self.$cacheFetchPolicy) {
                            ForEach(CacheFetchPolicy.all) { policy in
                                Text(policy.label).tag(policy)
                            }
                        }
                        #if os(iOS)
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 80)
                        #endif
                        
                        Spacer()

                        Button {
                            Task<Void, Never> {
                                do {
                                    _ = try await Purchases.shared.customerInfo(fetchPolicy: self.cacheFetchPolicy)
                                } catch {
                                    self.error = error
                                }
                            }
                        } label: {
                            Text("Go")
                        }
                    }

                    #if os(iOS) && !targetEnvironment(macCatalyst)
                    Button {
                        Purchases.shared.presentCodeRedemptionSheet()
                    } label: {
                        Text("Redemption Sheet")
                    }
                    #endif
                    
                    #if !os(watchOS)
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
                    #endif

                    #if os(iOS)
                    Button {
                        Task<Void, Never> {
                            do {
                                _ = try await Purchases.shared.beginRefundRequestForActiveEntitlement()
                            } catch {
                                print("🚀 Info 💁‍♂️ - Error: \(error)")
                            }
                        }
                    } label: {
                        Text("Begin Refund For Active Entitlement")
                    }
                    #endif
                }
            }
            .task {
                await self.fetchData()
            }
        }
        .alert(
            isPresented: .init(get: { self.error != nil },
                               set: { if $0 == false { self.error = nil } }),
            error: self.error.map(LocalizedAlertError.init),
            actions: { _ in
                Button("OK") {
                    self.error = nil
                }
            },
            message: { Text($0.subtitle) }
        )
        .navigationTitle("PurchaseTester")
        .textFieldAlert(isShowing: self.$showingAlert, title: "App User ID", fields: [("User ID", "ID of your user", self.$newAppUserID)]) {
            guard !self.newAppUserID.isEmpty else {
                return
            }
            
            Task<Void, Never> {
                do {
                    let (customerInfo, created) = try await Purchases.shared.logIn(self.newAppUserID)
                    print("🚀 Info 💁‍♂️ - Customer Info: \(customerInfo)")
                    print("🚀 Info 💁‍♂️ - Created: \(created)")
                } catch {
                    print("🚀 Info 💁‍♂️ - Error: \(error)")
                    self.error = error
                }
            }
        }
    }

    var body: some View {
        #if DEBUG && !os(visionOS) && !os(watchOS)
        if #available(iOS 16.0, macOS 13.0, *) {
            self.content
                .debugRevenueCatOverlay(isPresented: self.$debugOverlayVisible)
        } else {
            self.content
        }
        #else
        self.content
        #endif
    }
    
    private func fetchData() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            self.offerings = Array(offerings.all.values).sorted(by: { a, b in
                return b.identifier > a.identifier
            })
        } catch {
            print("🚀 Info 💁‍♂️ - Error: \(error)")
            self.error = error
        }
    }
    
    private func showLogin() {
        self.newAppUserID = ""
        self.showingAlert = true
    }
    
    private func logOut() async {
        do {
            let customerInfo = try await Purchases.shared.logOut()
            print("🚀 Info 💁‍♂️ - Customer Info: \(customerInfo)")
        } catch {
            print("🚀 Failed logging out 💁‍♂️ - Error: \(error)")
            self.error = error
        }
    }

}

private struct CustomerInfoHeaderView: View {
    
    enum Action {
        case login, logout
    }

    @EnvironmentObject var revenueCatCustomerData: RevenueCatCustomerData
    
    typealias Completion = (Action) async -> ()

    private let debugOverlayVisible: Binding<Bool>
    private let completion: Completion
    
    init(debugOverlayVisible: Binding<Bool>, completion: @escaping Completion) {
        self.debugOverlayVisible = debugOverlayVisible
        self.completion = completion
    }
    
    var appUserID: String? {
        return self.revenueCatCustomerData.appUserID
        ?? self.revenueCatCustomerData.customerInfo?.originalAppUserId
    }
    
    var activeEntitlementInfos: [RevenueCat.EntitlementInfo] {
        guard let customerInfo = self.revenueCatCustomerData.customerInfo else {
            return []
        }
        return Array(customerInfo.entitlements.all.values)
            .filter { $0.isActive }
    }
    
    var body: some View {
        VStack(alignment: self.horizontalAlignment) {
            Text(appUserID ?? "... loading")
            if activeEntitlementInfos.isEmpty {
                Text("No active entitlements")
            } else {
                Text(activeEntitlementInfos.map(\.identifier).joined(separator: ", "))
            }
            
            AdaptiveStack {
                Spacer()

                if let customerInfo = self.revenueCatCustomerData.customerInfo {
                    NavigationLink(destination: CustomerView(customerInfo: customerInfo)) {
                        Text("View Info")
                    }
                }
                
                Spacer()

                NavigationLink {
                    LocalReceiptView()
                } label: {
                    Text("Receipt")
                }

                Spacer()

                if Purchases.shared.isAnonymous {
                    Button {
                        Task<Void, Never> {
                            await self.completion(.login)
                        }
                    } label: {
                        Text("Login")
                    }
                } else {
                    Button {
                        Task<Void, Never> {
                            await self.completion(.logout)
                        }
                    } label: {
                        Text("Logout")
                    }
                }

                Spacer()

                #if targetEnvironment(macCatalyst) || os(macOS)
                if #available(macCatalyst 16.0, *) {
                    OpenWindowButton()

                    OpenProxyWindowButton()
                }
                #else
                NavigationLink(destination: LoggerView(logger: ConfiguredPurchases.logger)) {
                    Text("View logs")
                }
                #endif

                #if DEBUG
                if #available(iOS 16.0, macOS 13.0, *) {
                    Button {
                        self.debugOverlayVisible.wrappedValue = true
                    } label: {
                        Text("Debug")
                    }
                }
                #endif

                Spacer()

            }.padding(.top, 20)
        }
    }
    
    private var horizontalAlignment: HorizontalAlignment {
        #if os(visionOS)
        return .center
        #else
        return .leading
        #endif
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

#if targetEnvironment(macCatalyst) || os(macOS)
@available(macCatalyst 16.0, *)
private struct OpenWindowButton: View {

    @Environment(\.openWindow)
    private var openWindow

    var body: some View {
        Button("View logs") {
            self.openWindow(id: Windows.logs.rawValue)
        }
    }
    
}

@available(macCatalyst 16.0, *)
private struct OpenProxyWindowButton: View {

    @Environment(\.openWindow)
    private var openWindow

    var body: some View {
        Button("Proxy") {
            self.openWindow(id: Windows.proxy.rawValue)
        }
    }

}
#endif
