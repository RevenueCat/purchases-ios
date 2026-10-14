//
// Copyright RevenueCat Inc. All Rights Reserved.
// Licensed under the MIT License.
//

@_spi(Internal) import RevenueCat
import SwiftUI

#if DEBUG && os(iOS)
import UIKit

/// Real loaded-paywall renderer with an explicit safe area, captured by Emerge SnapshotPreviews.
@available(iOS 15.0, *)
@MainActor
struct ResponsiveHeroSafeAreaPreview: UIViewControllerRepresentable {
    let width: CGFloat
    var zlayer = false

    func makeUIViewController(context: Context) -> UIHostingController<AnyView> {
        let provider = UIConfigProvider(uiConfig: PreviewUIConfig.make())
        let offering = Offering(identifier: "pweng317-preview", serverDescription: "", availablePackages: [],
                                webCheckoutUrl: nil)
        let eligibility = IntroOfferEligibilityContext(introEligibilityChecker: .producing(eligibility: .eligible))
        let package = PackageContext(package: nil, variableContext: .init(packages: []))
        let result = PaywallsV2View.createPaywallState(
            componentsConfig: Self.componentsConfig(zlayer: zlayer),
            componentsLocalizations: ["en_US": ["overlay": .string("Overlay content")]],
            preferredLocales: [Locale(identifier: "en_US")], defaultLocale: "en_US", uiConfigProvider: provider,
            offering: offering, introEligibilityChecker: .producing(eligibility: .eligible),
            showZeroDecimalPlacePrices: false, colorScheme: .light
        )
        let state: PaywallState
        switch result {
        case .success(let loaded): state = loaded
        case .failure(let error): fatalError("Invalid PWENG-317 preview: \(error)")
        }
        let view = LoadedPaywallsV2View(
            introOfferEligibilityContext: eligibility, paywallState: state, uiConfigProvider: provider,
            selectedPackageContext: package, workflowDefaultPackage: nil, onDismiss: {}
        )
        .measurePaywallWindowSize()
        .environmentObject(eligibility)
        .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
        .environmentObject(PurchaseHandler.default())
        .environment(\.isRunningSnapshots, true)
        .environment(\.colorScheme, .light)
        let controller = UIHostingController(rootView: AnyView(view))
        controller.additionalSafeAreaInsets = UIEdgeInsets(top: 60, left: 0, bottom: 0, right: 0)
        controller.view.backgroundColor = .white
        controller.preferredContentSize = CGSize(width: width, height: 700)
        return controller
    }

    func updateUIViewController(_ controller: UIHostingController<AnyView>, context: Context) {}

    private static func componentsConfig(zlayer: Bool) -> PaywallComponentsData.PaywallComponentsConfig {
        let side = PaywallComponent.stack(.init(
            visible: false, components: [Self.image(color: .green, name: "side", width: .fixed(200))],
            overrides: [.init(
                extendedConditions: [.windowWidth(operator: .greaterThanOrEqual, value: 800)],
                properties: .init(visible: true)
            )]
        ))
        let overlay = PaywallComponent.text(.init(
            text: "overlay", color: .init(light: .hex("#0000FF")),
            size: .init(width: .fill, height: .fixed(60)), fontSize: 16
        ))
        return .init(
            stack: .init(
                components: [side, Self.image(color: .red, name: "hero", width: .fill)] + (zlayer ? [overlay] : []),
                dimension: zlayer ? .zlayer(.top) : .vertical(.leading, .start),
                size: .init(width: .fill, height: .fill), spacing: 0
            ),
            stickyFooter: nil, background: .color(.init(light: .hex("#FFFFFF")))
        )
    }

    private static func image(
        color: UIColor, name: String, width: PaywallComponent.SizeConstraint
    ) -> PaywallComponent {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pweng317-preview-\(name).png")
        if !FileManager.default.fileExists(atPath: url.path) {
            let image = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { context in
                color.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
            }
            guard let data = image.pngData() else { fatalError("Unable to encode PWENG-317 preview image") }
            do {
                try data.write(to: url, options: .atomic)
            } catch {
                fatalError("Unable to save PWENG-317 preview image: \(error)")
            }
        }
        return .image(.init(
            source: .init(light: .init(width: 400, height: 240, original: url, heic: url, heicLowRes: url)),
            size: .init(width: width, height: .fixed(240)), fitMode: .fill
        ))
    }
}

@available(iOS 15.0, *)
@MainActor
struct ResponsiveHeroSafeAreaPreview_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ResponsiveHeroSafeAreaPreview(width: 400)
                .previewDisplayName("PWENG-317 narrow: hidden side preserves hero bleed")
                .previewLayout(.fixed(width: 400, height: 700))
            ResponsiveHeroSafeAreaPreview(width: 900)
                .previewDisplayName("PWENG-317 wide: visible side retains safe area")
                .previewLayout(.fixed(width: 900, height: 700))
            ResponsiveHeroSafeAreaPreview(width: 400, zlayer: true)
                .previewDisplayName("PWENG-317 ZLayer: hero bleeds while text clears safe area")
                .previewLayout(.fixed(width: 400, height: 700))
        }
        .emergeExpansion(false)
    }
}
#endif
