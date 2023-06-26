//
//  LocalReceiptView.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 1/11/23.
//

import Foundation
import SwiftUI
import RevenueCat
import ReceiptParser

private typealias AppleReceipt = ReceiptParser.AppleReceipt

@MainActor
struct LocalReceiptView: View {

    @State
    private var receipt: Result<AppleReceipt, Error>?

    var body: some View {
        VStack {
            if #available(iOS 16.0, macCatalyst 16.0, macOS 13.0, watchOS 9.0, *) {
                self.form
                    .scrollContentBackground(.hidden)
            } else {
                self.form
            }

            Spacer(minLength: 10)

            Button {
                Task<Void, Never> {
                    // There's no public API to refresh the receipt other than this.
                    // This is the simplest way to force a receipt refresh before fetching it again.
                    // Ignoring error, since the receipt might have actually been refreshed
                    // and that's all we care about here.
                    _ = try? await Purchases.shared.restorePurchases()
                    await self.refreshReceipt()
                }
            } label: {
                Text("Refresh receipt")
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Local Receipt")
        .task {
            await self.refreshReceipt()
        }
    }

    @ViewBuilder
    private var form: some View {
        Form {
            switch self.receipt {
            case .none: Text("Loading...")
            case let .success(receipt)?: ReceiptDataView(receipt: receipt)
            case let .failure(error)?: Text("Error loading receipt: \(error.localizedDescription)")
            }
        }
    }

    private func refreshReceipt() async {
        self.receipt = await Self.loadReceipt()
    }

    private static func loadReceipt() async -> Result<ReceiptParser.AppleReceipt, Error> {
        return await Task
            .detached {
                Result(
                    catching: { try ReceiptParser.PurchasesReceiptParser.default.fetchAndParseLocalReceipt() }
                )
            }
            .value
    }

}

private struct ReceiptDataView: View {

    private let values: [DataView.Value]
    private let purchases: [AppleReceipt.InAppPurchase]

    init(receipt: AppleReceipt) {
        self.init(
            values: [
                .init("Bundle", receipt.bundleId),
                .init("App Version", receipt.applicationVersion),
                .init("Creation", receipt.creationDate.formatted()),
                .init("Hash", receipt.sha1Hash.base64EncodedString())
            ],
            purchases: receipt.inAppPurchases
        )
    }
    fileprivate init(values: [DataView.Value], purchases: [AppleReceipt.InAppPurchase]) {
        self.values = values
        self.purchases = purchases
    }

    var body: some View {
        Section(header: Text("Receipt Data")) {
            ForEach(self.values) { value in
                DataView(value: value)
            }
        }

        Section(header: Text("Purchases")) {
            if self.purchases.isEmpty {
                Text("No purchases found in this receipt.")
            } else {
                PurchasesView(purchases: self.purchases)
            }
        }
    }

}


private struct PurchasesView: View {

    private struct Item: Identifiable {
        let index: Int
        let purchase: AppleReceipt.InAppPurchase

        var id: String { return "\(self.index)-\(self.purchase.transactionId)" }
    }

    let purchases: [AppleReceipt.InAppPurchase]

    var body: some View {
        List(self.purchases.enumerated().map(Item.init)) {
            PurchaseView(purchase: $0.purchase)
        }
    }

    private struct PurchaseView: View {

        let purchase: AppleReceipt.InAppPurchase

        var body: some View {
            VStack {
                Text(self.purchase.productId)
                    .font(.title3.bold())
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .padding(.bottom, 5)

                DataView(name: "Transaction", display: self.purchase.transactionId)
                    .font(.caption2)

                DataView(name: "Product Type", display: self.purchase.productType.display)

                DataView(name: "Purchase Date", display: self.purchase.purchaseDate.formatted())

                if let expiration = self.purchase.expiresDate {
                    DataView(name: "Expiration", display: expiration.formatted())
                }

                if let cancellation = self.purchase.cancellationDate {
                    DataView(name: "Cancellation", display: cancellation.formatted())
                }

                if let promoOffer = self.purchase.promotionalOfferIdentifier {
                    DataView(name: "Promo Offer", display: promoOffer)
                }

                DataView(
                    name: "In Trial Period",
                    display: self.purchase.isInTrialPeriod?.description ?? "unknown"
                )
                DataView(
                    name: "In Intro Offer Period",
                    display: self.purchase.isInIntroOfferPeriod?.description ?? "unknown"
                )
            }
        }

    }

}

private struct DataView: View {

    struct Value: Equatable, Identifiable {

        let name: String
        let display: String

        init(_ name: String, _ display: String) {
            self.name = name
            self.display = display
        }

        var id: String { return self.name }

    }

    let value: Value

    init(value: Value) { self.value = value }
    init(name: String, display: String) { self.init(value: .init(name, display)) }

    var body: some View {
        HStack {
            Text(self.value.name)
                .font(.headline)

            Spacer()

            Text(self.value.display)
                .font(.body)
        }
    }

}

private extension AppleReceipt.InAppPurchase.ProductType {

    var display: String {
        switch self {
        case .nonConsumable: return "Non Consumable"
        case .consumable: return "Consumable"
        case .nonRenewingSubscription: return "Non-renewing Subscription"
        case .autoRenewableSubscription: return "Auto-renewable Subscription"

        case .unknown: fallthrough
        @unknown default: return "unknown"
        }
    }

}

#if DEBUG

struct LocalReceiptView_Previews: PreviewProvider {

    static var previews: some View {
        ReceiptDataView(
            values: [
                .init("Bundle", "com.revenuecat.purchasetester"),
                .init("App Version", "1.0"),
                .init("Creation", Date().formatted())
            ],
            purchases: []
        )
    }

}

#endif
