//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@_spi(Internal) import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
import XCTest
#if canImport(UIKit)
import UIKit
#endif

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class FooterLayoutTests: TestCase {
    private typealias Footer = PaywallComponent.StickyFooterComponent
    private typealias Partial = PaywallComponent.PartialStickyFooterComponent

    func testLegacyFooterHasNoLayoutOrOverrides() throws {
        let footer = try decode(#"{"stack":{"type":"stack","components":[]}}"#)
        XCTAssertNil(footer.layout)
        XCTAssertNil(footer.overrides)
    }

    func testLayoutValuesRoundTrip() throws {
        for layout in [Footer.Layout.normal, .hidden, .splitLeading, .splitTrailing] {
            let footer = Footer(stack: .init(components: []), layout: layout)
            let data = try JSONEncoder().encode(footer)
            XCTAssertEqual(try JSONDecoder().decode(Footer.self, from: data), footer)
        }
    }

    func testUnknownLayoutFallsBackToNormal() throws {
        XCTAssertEqual(try decode(#"{"layout":"future","stack":{"type":"stack","components":[]}}"#).layout,
                       .normal)
    }

    func testViewportOverrideUsesFullPaywallBoundsAndResetsOnResize() throws {
        let footer = try decode(#"""
        {"stack":{"type":"stack","components":[]},"overrides":[
          {"conditions":[{"type":"window_width_condition","operator":">=","value":700}],
           "properties":{"layout":"split_trailing"}}
        ]}
        """#)
        let overrides = footer.overrides?.toPresentedOverrides()
        func resolved(width: CGFloat) -> Footer.Layout {
            Partial.buildPartial(state: .default, condition: .compact,
                                 isEligibleForIntroOffer: false, isEligibleForPromoOffer: false,
                                 conditionContext: .init(windowSize: CGSize(width: width, height: 600)),
                                 with: overrides)?.layout ?? footer.layout ?? .normal
        }
        XCTAssertEqual(resolved(width: 390), .normal)
        XCTAssertEqual(resolved(width: 800), .splitTrailing)
        XCTAssertEqual(resolved(width: 390), .normal)
    }

    func testUnsupportedFooterConditionDiscardsRules() throws {
        let footer = try decode(#"""
        {"stack":{"type":"stack","components":[]},"overrides":[
          {"conditions":[{"type":"future_condition"}],"properties":{"layout":"hidden"}}
        ]}
        """#)
        XCTAssertTrue(PaywallComponent.stickyFooter(footer).containsUnsupportedConditions())
        XCTAssertTrue(footer.overrides?.toPresentedOverrides(discardRules: true).isEmpty == true)
    }

    #if canImport(UIKit) && !os(watchOS)
    @MainActor
    func testSplitFooterBackgroundFillsColumn() throws {
        let size = CGSize(width: 800, height: 600)
        for layout in [Footer.Layout.splitLeading, .splitTrailing] {
            let footer = PaywallComponent.StackComponent(
                components: [.stack(.init(
                    components: [], size: .init(width: .fill, height: .fixed(40)),
                    backgroundColor: .init(light: .hex("#00FF00"))
                ))],
                dimension: .vertical(.center, .center),
                size: .init(width: .fill, height: .fit(nil)),
                backgroundColor: .init(light: .hex("#FF0000"))
            )
            let viewModel = try PaywallsV2LayoutFixtures.makeRootViewModel(componentsConfig: .init(
                stack: .init(components: [], size: .init(width: .fill, height: .fill)),
                stickyFooter: .init(stack: footer, layout: layout),
                background: .color(.init(light: .hex("#0000FF")))
            ))
            let view = PaywallsV2LayoutFixtures.makeRootView(viewModel: viewModel, size: size).ignoresSafeArea()
            let controller = UIHostingController(rootView: view)
            let window = UIWindow(frame: CGRect(origin: .zero, size: size))
            window.rootViewController = controller
            window.makeKeyAndVisible()
            defer { window.isHidden = true }
            controller.view.frame = window.bounds
            window.layoutIfNeeded()
            controller.beginAppearanceTransition(true, animated: false)
            controller.endAppearanceTransition()
            let format = UIGraphicsImageRendererFormat.default()
            format.scale = 1
            let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { context in
                window.layer.render(in: context.cgContext)
            }
            let columnX = layout == .splitLeading ? 200 : 600
            try assertRedPixel(image, column: columnX, row: 4)
            try assertRedPixel(image, column: columnX, row: 596)
        }
    }

    private func assertRedPixel(_ image: UIImage, column: Int, row: Int) throws {
        let cgImage = try XCTUnwrap(image.cgImage)
        var pixels = [UInt8](repeating: 0, count: cgImage.width * cgImage.height * 4)
        let context = try XCTUnwrap(CGContext(
            data: &pixels, width: cgImage.width, height: cgImage.height, bitsPerComponent: 8,
            bytesPerRow: cgImage.width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        let offset = (row * cgImage.width + column) * 4
        XCTAssertEqual(Array(pixels[offset..<(offset + 3)]), [255, 0, 0], "Footer background at \(column), \(row)")
    }
    #endif

    private func decode(_ json: String) throws -> Footer {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let stack = try JSONEncoder().encode(PaywallComponent.StackComponent(components: []))
        let stackJSON = try XCTUnwrap(String(data: stack, encoding: .utf8))
        let payload = json.replacingOccurrences(of: #"{"type":"stack","components":[]}"#, with: stackJSON)
        return try decoder.decode(Footer.self, from: Data(payload.utf8))
    }
}
#endif
