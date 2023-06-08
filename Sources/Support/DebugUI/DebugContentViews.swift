//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DebugViewContent.swift
//
//  Created by Nacho Soto on 5/30/23.

#if DEBUG && os(iOS) && swift(>=5.8)

import SwiftUI

@available(iOS 16.0, *)
struct DebugSwiftUIRootView: View {

    @StateObject
    private var model = DebugViewModel()

    var body: some View {
        NavigationStack(path: self.$model.navigationPath) {
            DebugSummaryView(model: self.model)
                .navigationDestination(for: DebugViewPath.self) { path in
                    switch path {
                    case let .offering(offering):
                        DebugOfferingView(offering: offering)

                    case let .package(package):
                        DebugPackageView(package: package)
                    }
                }
                .background(
                    Rectangle()
                        .foregroundStyle(Material.thinMaterial)
                        .edgesIgnoringSafeArea(.all)
                )
        }
        .task {
            await self.model.load()
        }
    }

}

private enum DebugViewPath: Hashable {

    case offering(Offering)
    case package(Package)

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private struct DebugSummaryView: View {

    @ObservedObject
    var model: DebugViewModel

    var body: some View {
        List {
            self.diagnosticsSection

            self.configurationSection

            #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
            self.customerInfoSection
            #endif

            self.offeringsSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .navigationTitle("RevenueCat Debug View")
    }

    private var diagnosticsSection: some View {
        Section("Diagnostics") {
            LabeledContent("Status") {
                HStack {
                    Text(self.model.diagnosticsStatus)
                    self.model.diagnosticsIcon
                }
            }
        }
    }

    private var configurationSection: some View {
        Section("Configuration") {
            switch self.model.configuration {
            case .loading:
                Text("Loading...")

            case let .loaded(config):
                LabeledContent("SDK version", value: config.sdkVersion)
                LabeledContent("Observer mode", value: config.observerMode.description)
                LabeledContent("Sandbox", value: config.sandbox.description)
                LabeledContent("StoreKit 2", value: config.storeKit2Enabled ? "on" : "off")
                LabeledContent("Offline Customer Info",
                               value: config.offlineCustomerInfoSupport ? "enabled" : "disabled")
                LabeledContent("Entitlement Verification Mode", value: config.verificationMode)

                ShareLink(item: config, preview: .init("Configuration")) {
                    Label("Share", systemImage: "square.and.arrow.up")

                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
    private var customerInfoSection: some View {
        Section("Customer Info") {
            switch self.model.customerInfo {
            case .loading:
                Text("Loading...")

            case let .loaded(info):
                LabeledContent("User ID", value: Purchases.shared.appUserID)
                LabeledContent("Original User ID", value: info.originalAppUserId)
                LabeledContent("Active Entitlements", value: info.entitlements.active.count.description)

                if let latestExpiration = info.latestExpirationDate {
                    LabeledContent("Latest Expiration Date",
                                   value: latestExpiration.formatted(date: .abbreviated,
                                                                     time: .omitted))
                }

            case let .failed(error):
                Text("Error loading customer info: \(error.localizedDescription)")
            }
        }
    }
    #endif

    @ViewBuilder
    private var offeringsSection: some View {
        Section("Offerings") {
            switch self.model.offerings {
            case .loading:
                Text("Loading...")

            case let .loaded(offerings):
                ForEach(Array(offerings.all.values)) { offering in
                    NavigationLink(value: DebugViewPath.offering(offering)) {
                        VStack {
                            LabeledContent(
                                offering.identifier,
                                value: "\(offering.availablePackages.count) package(s)"
                            )
                        }
                    }
                }

            case let .failed(error):
                Text("Error loading offerings: \(error.localizedDescription)")
            }
        }
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private struct DebugOfferingView: View {

    var offering: Offering

    var body: some View {
        List {
            Section("Data") {
                LabeledContent("Identifier", value: self.offering.id)
                LabeledContent("Description", value: self.offering.serverDescription)
            }

            Section("Packages") {
                ForEach(self.offering.availablePackages) { package in
                    NavigationLink(value: DebugViewPath.package(package)) {
                        Text(package.identifier)
                    }
                }
            }
        }
            .navigationTitle("Offering")
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private struct DebugPackageView: View {

    var package: Package

    @State private var error: NSError? {
        didSet {
            if self.error != nil {
                self.displayError = true
            }
        }
    }

    @State private var displayError: Bool = false
    @State private var purchasing: Bool = false

    var body: some View {
        List {
            Section("Data") {
                LabeledContent("Identifier", value: self.package.identifier)
                LabeledContent("Price", value: self.package.localizedPriceString)
                LabeledContent("Product", value: self.package.storeProduct.productIdentifier)
                LabeledContent("Type", value: self.package.packageType.description ?? "")
            }

            Section("Purchasing") {
                Button {
                    _ = Task<Void, Never> {
                        do {
                            self.purchasing = true
                            try await self.purchase()
                        } catch {
                            self.error = error as NSError
                        }

                        self.purchasing = false
                    }
                } label: {
                    Text("Purchase")
                }
                .disabled(self.purchasing)
            }
        }
            .navigationTitle("Package")
            .alert(
                "Error",
                isPresented: self.$displayError,
                presenting: self.error
            ) { error in
                Text(error.localizedDescription)
            }
    }

    private func purchase() async throws {
        _ = try await Purchases.shared.purchase(package: self.package)
    }

}

@available(iOS 16.0, *)
extension DebugViewModel.Configuration: Transferable {

    static var transferRepresentation: some TransferRepresentation {
        return CodableRepresentation(
            for: DebugViewModel.Configuration.self,
            contentType: .plainText,
            encoder: JSONEncoder.prettyPrinted,
            decoder: JSONDecoder.default
        )
    }

}

#endif
