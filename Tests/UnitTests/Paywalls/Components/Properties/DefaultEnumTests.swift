import Nimble
@testable import RevenueCat
import XCTest

#if !os(macOS) && !os(tvOS) // For Paywalls V2

class DefaultEnumTests: TestCase {

    func testButtonComponentAction() throws {
        let json = """
        {
            "prop": {
                "type": "notvalidvalue"
            }
        }
        """

        struct Thing: Decodable {
            let prop: PaywallComponent.ButtonComponent.Action
        }

        let thing = try JSONDecoder.default.decode(
            Thing.self,
            from: json.data(using: .utf8)!
        )

        expect(thing.prop).to(equal(.unknown))
    }

    func testButtonComponentDestination() throws {
        let json = """
        {
            "prop": {
                "destination": "notvalidvalue"
            }
        }
        """

        struct Thing: Decodable {
            let prop: PaywallComponent.ButtonComponent.Destination
        }

        let thing = try JSONDecoder.default.decode(
            Thing.self,
            from: json.data(using: .utf8)!
        )

        expect(thing.prop).to(equal(.unknown))
    }

    func testButtonComponentURLMethod() throws {
        let json = """
        {
            "prop": "notvalidvalue",
        }
        """

        struct Thing: Decodable {
            let prop: PaywallComponent.ButtonComponent.URLMethod
        }

        let thing = try JSONDecoder.default.decode(
            Thing.self,
            from: json.data(using: .utf8)!
        )

        expect(thing.prop).to(equal(.unknown))
    }

    func testBadgeStyle() throws {
        let json = """
        {
            "prop": "notvalidvalue",
        }
        """

        struct Thing: Decodable {
            let prop: PaywallComponent.BadgeStyle
        }

        let thing = try JSONDecoder.default.decode(
            Thing.self,
            from: json.data(using: .utf8)!
        )

        expect(thing.prop).to(equal(.overlaid))
    }

    func testCarouselComponentPageControlPosition() throws {
        let json = """
        {
            "prop": "notvalidvalue",
        }
        """

        struct Thing: Decodable {
            let prop: PaywallComponent.CarouselComponent.PageControl.Position
        }

        let thing = try JSONDecoder.default.decode(
            Thing.self,
            from: json.data(using: .utf8)!
        )

        expect(thing.prop).to(equal(.bottom))
    }

    func testDimension() throws {
        let json = """
        {
            "prop": "notvalidvalue",
        }
        """

        struct Thing: Decodable {
            let prop: PaywallComponent.Dimension
        }

        expect {
            try JSONDecoder.default.decode(
                Thing.self,
                from: json.data(using: .utf8)!
            )
        }.to(throwError())
    }

    func testFitMode() throws {
        let json = """
        {
            "prop": "notvalidvalue",
        }
        """

        struct Thing: Decodable {
            let prop: PaywallComponent.FitMode
        }

        let thing = try JSONDecoder.default.decode(
            Thing.self,
            from: json.data(using: .utf8)!
        )

        expect(thing.prop).to(equal(.fit))
    }

    func testFlexDistribution() throws {
        let json = """
        {
            "prop": "notvalidvalue",
        }
        """

        struct Thing: Decodable {
            let prop: PaywallComponent.FlexDistribution
        }

        let thing = try JSONDecoder.default.decode(
            Thing.self,
            from: json.data(using: .utf8)!
        )

        expect(thing.prop).to(equal(.start))
    }

    func testFontSize() throws {
        let json = """
        {
            "prop": "notvalidvalue",
        }
        """

        struct Thing: Decodable {
            let prop: PaywallComponent.FontSize
        }

        let thing = try JSONDecoder.default.decode(
            Thing.self,
            from: json.data(using: .utf8)!
        )

        expect(thing.prop).to(equal(.bodyM))
    }

    func testFontWeight() throws {
        let json = """
        {
            "prop": "notvalidvalue",
        }
        """

        struct Thing: Decodable {
            let prop: PaywallComponent.FontWeight
        }

        let thing = try JSONDecoder.default.decode(
            Thing.self,
            from: json.data(using: .utf8)!
        )

        expect(thing.prop).to(equal(.regular))
    }

    func testHorizontalAlignment() throws {
        let json = """
        {
            "prop": "notvalidvalue",
        }
        """

        struct Thing: Decodable {
            let prop: PaywallComponent.HorizontalAlignment
        }

        let thing = try JSONDecoder.default.decode(
            Thing.self,
            from: json.data(using: .utf8)!
        )

        expect(thing.prop).to(equal(.leading))
    }

    func testMaskShape() throws {
        let json = """
        {
            "prop": {
                "type": "notvalidvalue"
            }
        }
        """

        struct Thing: Decodable {
            let prop: PaywallComponent.MaskShape
        }

        let thing = try JSONDecoder.default.decode(
            Thing.self,
            from: json.data(using: .utf8)!
        )

        expect(thing.prop).to(equal(.rectangle(nil)))
    }

    func testShape() throws {
        let json = """
        {
            "prop": {
                "type": "notvalidvalue"
            }
        }
        """

        struct Thing: Decodable {
            let prop: PaywallComponent.Shape
        }

        let thing = try JSONDecoder.default.decode(
            Thing.self,
            from: json.data(using: .utf8)!
        )

        expect(thing.prop).to(equal(.rectangle(nil)))
    }

    func testSizeConstraint() throws {
        let json = """
        {
            "prop": "notvalidvalue",
        }
        """

        struct Thing: Decodable {
            let prop: PaywallComponent.SizeConstraint
        }

        let thing = try JSONDecoder.default.decode(
            Thing.self,
            from: json.data(using: .utf8)!
        )

        expect(thing.prop).to(equal(.fit))
    }

    func testStackComponentOverflow() throws {
        let json = """
        {
            "prop": "notvalidvalue",
        }
        """

        struct Thing: Decodable {
            let prop: PaywallComponent.StackComponent.Overflow
        }

        let thing = try JSONDecoder.default.decode(
            Thing.self,
            from: json.data(using: .utf8)!
        )

        expect(thing.prop).to(equal(.default))
    }

    func testTimelineComponentIconAlignment() throws {
        let json = """
        {
            "prop": "notvalidvalue",
        }
        """

        struct Thing: Decodable {
            let prop: PaywallComponent.TimelineComponent.IconAlignment
        }

        let thing = try JSONDecoder.default.decode(
            Thing.self,
            from: json.data(using: .utf8)!
        )

        expect(thing.prop).to(equal(.title))
    }

    func testTwoDimensionalAlignment() throws {
        let json = """
        {
            "prop": "notvalidvalue",
        }
        """

        struct Thing: Decodable {
            let prop: PaywallComponent.TwoDimensionAlignment
        }

        let thing = try JSONDecoder.default.decode(
            Thing.self,
            from: json.data(using: .utf8)!
        )

        expect(thing.prop).to(equal(.top))
    }

    func testVerticalAlignment() throws {
        let json = """
        {
            "prop": "notvalidvalue",
        }
        """

        struct Thing: Decodable {
            let prop: PaywallComponent.VerticalAlignment
        }

        let thing = try JSONDecoder.default.decode(
            Thing.self,
            from: json.data(using: .utf8)!
        )

        expect(thing.prop).to(equal(.top))
    }

    func testIconBackgroundShape() throws {
        let json = """
        {
            "prop": "notvalidvalue",
        }
        """

        struct Thing: Decodable {
            let prop: PaywallComponent.IconBackgroundShape
        }

        let thing = try JSONDecoder.default.decode(
            Thing.self,
            from: json.data(using: .utf8)!
        )

        expect(thing.prop).to(equal(.rectangle(nil)))
    }

}

#endif
