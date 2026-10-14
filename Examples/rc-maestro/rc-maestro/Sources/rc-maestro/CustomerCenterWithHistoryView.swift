#if DEBUG
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI

/// Customer Center fed with a fixed purchase history: one active and one expired subscription.
/// Maestro cannot create an expired subscription during a run, so this covers the
/// single-purchase screen with "See all purchases".
struct CustomerCenterWithHistoryView: View {

    var body: some View {
        CustomerCenterView(
            uiPreviewPurchaseProvider: MockCustomerCenterPurchases(
                customerInfo: Self.customerInfo,
                customerCenterConfigData: .mock(lastPublishedAppVersion: nil, displayPurchaseHistoryLink: true)
            ),
            navigationOptions: .default
        )
    }

    private static let customerInfo = CustomerInfoFixtures.customerInfo(
        subscriptions: [
            .init(id: "com.revenuecat.product", store: "app_store",
                  purchaseDate: "2022-04-12T00:03:28Z", expirationDate: "2062-04-12T00:03:35Z"),
            .init(id: "com.revenuecat.expired", store: "app_store",
                  purchaseDate: "1999-04-12T00:03:28Z", expirationDate: "2000-04-12T00:03:35Z")
        ],
        entitlements: [
            .init(entitlementId: "premium", productId: "com.revenuecat.product",
                  purchaseDate: "2022-04-12T00:03:28Z", expirationDate: "2062-04-12T00:03:35Z")
        ]
    )
}
#endif
