//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

#if DEBUG && !os(tvOS)

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

/// Discovered by the existing RevenueCatUI SwiftUI preview snapshot suite.
@MainActor
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
struct NativePaywallNavigationPreview_Previews: PreviewProvider {

    static var previews: some View {
        NativePaywallNavigationPreview()
            .previewDisplayName("Native navigation: Close, button-only header collapsed")
        NativePaywallNavigationPreview(canNavigateBack: true)
            .previewDisplayName("Native navigation: Back and Close")
        NativePaywallNavigationPreview(retainsHeaderContent: true)
            .previewDisplayName("Native navigation: header content retained")
        NativePaywallNavigationPreview(nativeEnabled: false)
            .previewDisplayName("Native navigation: configured fallback")
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private struct NativePaywallNavigationPreview: View {
    var canNavigateBack = false
    var retainsHeaderContent = false
    var nativeEnabled = true

    var body: some View {
        Group {
            switch Result(catching: self.makeFixture) {
            case .success(let fixture):
                PaywallsV2View(
                    paywallComponents: fixture.paywallComponents,
                    offering: fixture.offering,
                    purchaseHandler: .default(),
                    introEligibilityChecker: .producing(eligibility: .ineligible),
                    showZeroDecimalPlacePrices: true,
                    onDismiss: {}, failedToLoadFont: { _ in }, colorScheme: .light
                )
                .environment(\.workflowRenderingContext, .init(canNavigateBack: self.canNavigateBack))
                .modifier(NativePaywallNavigationModifier(requested: self.nativeEnabled))
                .environment(\.nativePaywallNavigationContext, .standalone)
                .previewRequiredPaywallsV2Properties()
                .environment(\.paywallLoadingOverride, false)
            case .failure(let error):
                Text("Invalid native navigation preview: \(error.localizedDescription)")
            }
        }
        .environment(\.locale, Locale(identifier: "en_US"))
        .preferredColorScheme(.light)
        .emergeExpansion(false)
        .previewLayout(.fixed(width: 400, height: 860))
    }

    private func makeFixture() throws -> PaywallPreviewRenderer.Fixture {
        // Start with the existing dashboard-shaped payload so decoding and real component rendering
        // are covered. close_workflow intentionally goes through the decoder's internal action marker.
        guard var payload = try JSONSerialization.jsonObject(
            with: Data(PaywallPreviewRenderer.sampleJSON.utf8)
        ) as? [String: Any],
              var configs = payload["components_config"] as? [String: Any],
              var base = configs["base"] as? [String: Any],
              let bodyStack = base["stack"] as? [String: Any],
              let components = bodyStack["components"] as? [[String: Any]],
              let title = components.first else {
            throw CocoaError(.fileReadCorruptFile)
        }
        var buttonStack = bodyStack
        buttonStack["components"] = [title.merging(["text_lid": "close", "font_size": 16]) { _, new in new }]
        buttonStack["padding"] = ["leading": 16, "trailing": 16, "top": 12, "bottom": 12]
        func button(_ action: String, label: String) -> [String: Any] {
            var stack = buttonStack
            stack["components"] = [title.merging(["text_lid": label, "font_size": 16]) { _, new in new }]
            return ["type": "button", "action": ["type": action, "use_native_if_possible": self.nativeEnabled],
                    "stack": stack]
        }
        var headerStack = bodyStack
        var header = [button("close_workflow", label: "close")]
        if self.canNavigateBack { header.insert(button("navigate_back", label: "back"), at: 0) }
        if self.retainsHeaderContent {
            header.insert(title.merging(["text_lid": "header_title", "font_size": 18]) { _, new in new }, at: 0)
        }
        headerStack["components"] = header
        headerStack["dimension"] = ["type": "horizontal", "alignment": "center", "distribution": "space_between"]
        base["header"] = ["stack": headerStack]
        var paddedBody = bodyStack
        paddedBody["padding"] = ["leading": 24, "trailing": 24, "top": 120, "bottom": 24]
        base["stack"] = paddedBody
        configs["base"] = base
        payload["components_config"] = configs
        payload["components_localizations"] = ["en_US": ["title": "Choose your plan", "header_title": "Membership",
                                                          "close": "Close paywall", "back": "Go back"]]
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        guard let json = String(data: data, encoding: .utf8) else { throw CocoaError(.fileReadCorruptFile) }
        return try PaywallPreviewRenderer.load(json: json)
    }
}

#endif
