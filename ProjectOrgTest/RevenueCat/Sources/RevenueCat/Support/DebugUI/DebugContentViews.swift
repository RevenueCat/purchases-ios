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

#if DEBUG && swift(>=5.8) && (os(iOS) || os(macOS) || VISION_OS)

import StoreKit
import SwiftUI

#if os(macOS)
import AppKit
#endif

// swiftlint:disable file_length

@available(iOS 16.0, macOS 13.0, *)
struct DebugSwiftUIRootView: View {

    @StateObject
    private var model = DebugViewModel()

    @Environment(\.presentationMode)
    private var presentationMode

    var body: some View {
        NavigationStack(path: self.$model.navigationPath) {
            DebugSummaryView(model: self.model)
                .navigationDestination(for: DebugViewPath.self) { path in
                    switch path {
                    case let .offering(offering):
                        DebugOfferingView(offering: offering)

                    case let .offeringMetadata(offering):
                        DebugOfferingMetadataView(offering: offering)

                    case let .package(package):
                        DebugPackageView(package: package)

                    case let .paywall(paywall):
                        DebugPaywallJSONView(paywall: paywall)
                    }
                }
                .background(
                    Rectangle()
                        .foregroundStyle(Material.thinMaterial)
                        .edgesIgnoringSafeArea(.all)
                )
                #if os(macOS) || targetEnvironment(macCatalyst)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            self.presentationMode.wrappedValue.dismiss()
                        } label: {
                            Label("Close", systemImage: "xmark")
                        }
                    }
                }
                #endif
        }
        .task {
            await self.model.load()
        }
    }

    static let cornerRadius: CGFloat = 24

}

private enum DebugViewPath: Hashable {

    case offering(Offering)
    case offeringMetadata(Offering)
    case package(Package)
    case paywall(PaywallData)

}

@available(iOS 16.0, macOS 13.0, *)
internal struct DebugSummaryView: View {

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
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
        .scrollContentBackground(.hidden)
        .navigationTitle("RevenueCat Debug")
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
                Group {
                    LabeledContent("SDK version", value: config.sdkVersion)
                    LabeledContent("Observer mode", value: config.observerMode.description)
                    LabeledContent("Sandbox", value: config.sandbox.description)
                    LabeledContent("StoreKit 2", value: config.storeKit2Enabled ? "on" : "off")
                    LabeledContent("Locale", value: config.locale.display)
                    LabeledContent("Offline Customer Info",
                                   value: config.offlineCustomerInfoSupport ? "enabled" : "disabled")
                    LabeledContent("Entitlement Verification Mode", value: config.verificationMode)
                    LabeledContent("Receipt URL", value: config.receiptURL?.relativeString ?? "")
                        #if os(macOS)
                        .contextMenu {
                            Button {
                                if let url = config.receiptURL {
                                    NSWorkspace.shared.selectFile(
                                        nil,
                                        inFileViewerRootedAtPath: url.deletingLastPathComponent().path
                                    )
                                }
                            } label: {
                                Text("Show in Finder")
                            }
                        }
                        #endif
                    LabeledContent("Receipt status", value: config.receiptStatus)

                    ShareLink(item: AnyEncodable(config), preview: .init("Configuration")) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
                .textSelection(.enabled)
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
                LabeledContent("User ID", value: self.model.currentAppUserID ?? "")
                LabeledContent("Original User ID", value: info.originalAppUserId)
                LabeledContent("Entitlements", value: info.entitlementDescription)

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

@available(iOS 16.0, macOS 13.0, *)
private struct DebugOfferingView: View {

    @State private var showingSubscriptionSheet = false
    @State private var showingStoreSheet = false

    var offering: Offering

    var body: some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, *) {
            content
            #if swift(>=5.9)
                .onInAppPurchaseCompletion { _, _ in
                    self.showingSubscriptionSheet = false
                    self.showingStoreSheet = false
                }
            #endif
        } else {
            content
        }
    }

    private var content: some View {
        List {
            Section("Data") {
                LabeledContent("Identifier", value: self.offering.id)
                LabeledContent("Description", value: self.offering.serverDescription)

                if !self.offering.metadata.isEmpty {
                    NavigationLink(value: DebugViewPath.offeringMetadata(self.offering)) {
                        Text("Metadata")
                    }
                } else {
                    LabeledContent("Metadata", value: "{}")
                }

                if let paywall = self.offering.paywall {
                    NavigationLink(value: DebugViewPath.paywall(paywall)) {
                        Text("RevenueCatUI paywall")
                    }
                } else {
                    LabeledContent("RevenueCatUI", value: "No paywall")
                }
            }

            Section("Packages") {
                ForEach(self.offering.availablePackages) { package in
                    NavigationLink(value: DebugViewPath.package(package)) {
                        Text(package.identifier)
                    }
                }
            }

            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, *) {
                Section("Paywalls") {
                    Button {
                        self.showingSubscriptionSheet = true
                    } label: {
                        Text("Display SubscriptionStoreView")
                    }

                    Button {
                        self.showingStoreSheet = true
                    } label: {
                        Text("Display StoreView")
                    }
                }
            }
        }
        .navigationTitle("Offering")
        #if swift(>=5.9)
        .sheet(isPresented: self.$showingSubscriptionSheet) {
            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, *) {
                self.subscriptionStoreView
            }
        }
        .sheet(isPresented: self.$showingStoreSheet) {
            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, *) {
                StoreView.forOffering(self.offering)
            }
        }
        #endif
    }

    #if swift(>=5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
    private var subscriptionStoreView: some View {
        SubscriptionStoreView.forOffering(self.offering) {
            VStack {
                VStack {
                    Text("🐈")
                    Text("RevenueCat Demo Paywall")
                }
                .font(.title)

                Text(self.offering.getMetadataValue(for: "title", default: "Premium Access"))
                    .font(.title2)
                    .foregroundStyle(.primary)

                Text(self.offering.getMetadataValue(for: "subtitle",
                                                    default: "Unlimited access to premium content."))
                .foregroundStyle(.secondary)
                .font(.subheadline)
            }
            #if !VISION_OS
            .containerBackground(for: .subscriptionStoreFullHeight) {
                Rectangle()
                    .edgesIgnoringSafeArea(.all)
                    .foregroundStyle(Color.blue.gradient.quaternary)
            }
            #endif
        }
        .backgroundStyle(.clear)
        .subscriptionStoreButtonLabel(.multiline)
        .subscriptionStorePickerItemBackground(.thickMaterial)
    }
    #endif

}

@available(iOS 16.0, macOS 13.0, *)
private struct DebugOfferingMetadataView: View {

    var offering: Offering

    var body: some View {
        DebugJSONView(value: AnyEncodable(self.offering.metadata))
            .navigationTitle("Offering Metadata")
    }

}

@available(iOS 16.0, macOS 13.0, *)
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
                    _ = Task<Void, Never> { @MainActor in
                        do {
                            self.purchasing = true
                            try await self.purchase()
                        } catch {
                            self.error = error as NSError
                        }

                        self.purchasing = false
                    }
                } label: {
                    Text("Purchase with RevenueCat")
                }

                #if swift(>=5.9)
                if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                    ProductView(id: self.package.storeProduct.productIdentifier)
                        .productViewStyle(ProductStyle())
                }
                #endif
            }
            .disabled(self.purchasing)
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

    @MainActor
    private func purchase() async throws {
        _ = try await Purchases.shared.purchase(package: self.package)
    }

}

@available(iOS 16.0, macOS 13.0, *)
private struct DebugPaywallJSONView: View {

    let paywall: PaywallData

    var body: some View {
        DebugJSONView(value: AnyEncodable(self.paywall))
            .navigationTitle("RevenueCatUI Paywall")
    }

}

@available(iOS 16.0, macOS 13.0, *)
private struct DebugJSONView<Value: Encodable & Transferable>: View {

    let value: Value

    var body: some View {
        ScrollView(.vertical) {
            Text(self.json)
                .multilineTextAlignment(.leading)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: self.value, preview: .init("JSON")) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    private var json: String {
        return (try? self.value.prettyPrintedJSON) ?? "{}"
    }

}

// MARK: - Locale

private extension Locale {

    var display: String {
        return "\(self.identifier) (\(self.rc_currencyCode ?? "unknown"))"
    }

}

// MARK: - Transferable

@available(iOS 16.0, macOS 13.0, *)
extension AnyEncodable: Transferable {

    static var transferRepresentation: some TransferRepresentation {
        return CodableRepresentation(
            for: Self.self,
            contentType: .plainText,
            encoder: JSONEncoder.prettyPrinted,
            decoder: JSONDecoder.default
        )
    }

}

#if swift(>=5.9)
@available(iOS 17.0, macOS 14.0, *)
private struct ProductStyle: ProductViewStyle {

    func makeBody(configuration: ProductViewStyleConfiguration) -> some View {
        switch configuration.state {
        case .loading:
            ProgressView()
                .progressViewStyle(.circular)

        case .success:
            Button {
                configuration.purchase()
            } label: {
                Text("Purchase with StoreKit")
            }

        default:
            ProductView(configuration)
        }
    }

}
#endif

#if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION

private extension CustomerInfo {

    var entitlementDescription: String {
        let total = self.entitlements.all.count
        let active = self.entitlements.active.values

        let activeList = active.isEmpty
        ? ""
        : ": \(active.map(\.identifier).joined(separator: ", "))"

        return "\(total) total, \(active.count) active\(activeList)"
    }

}

#endif

#endif
