//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@_spi(Internal) import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

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
