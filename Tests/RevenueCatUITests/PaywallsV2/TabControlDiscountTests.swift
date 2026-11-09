//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabControlDiscountTests.swift
//

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import Vision
import XCTest

#if os(iOS)

@available(iOS 15.0, *)
@MainActor
final class TabControlDiscountTests: TestCase {

    func testTabDiscountDoesNotFollowTheActiveTab() throws {
        let fixture = try self.makeFixture()
        let (window, view) = Self.host(fixture.view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        XCTAssertTrue(Self.containsText("Yearly: 43%", in: view))
        fixture.model.tabControlContext.selectedTabId = "monthly"
        Self.settle(window)

        XCTAssertEqual(fixture.parent.package?.identifier, fixture.monthly.identifier)
        XCTAssertTrue(Self.containsText("Yearly: 43%", in: view))
    }

    func testTabDiscountKeepsItsSelectionWhenAnOutsidePlanIsSelected() throws {
        let fixture = try self.makeFixture()
        let (window, view) = Self.host(fixture.view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        fixture.parent.update(package: fixture.otherAnnual, variableContext: fixture.parent.variableContext)
        Self.settle(window)
        XCTAssertTrue(Self.containsText("Yearly: 58%", in: view))

        fixture.parent.update(package: fixture.premium, variableContext: .init(packages: [fixture.premium]))
        Self.settle(window)
        XCTAssertEqual(fixture.parent.package?.identifier, fixture.premium.identifier)
        XCTAssertTrue(Self.containsText("Yearly: 58%", in: view))
    }

    func testEmptyTabButtonUsesTheSharedSelection() throws {
        let fixture = try self.makeFixture(emptyAnnualTab: true)
        let (window, view) = Self.host(fixture.view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        XCTAssertTrue(Self.containsText("Yearly: 23%", in: view))
        fixture.parent.update(
            package: fixture.otherAnnual, variableContext: fixture.parent.variableContext, isReconcile: true
        )
        Self.settle(window)
        XCTAssertTrue(Self.containsText("Yearly: 58%", in: view))

        fixture.parent.update(package: fixture.otherAnnual, variableContext: .init(packages: [fixture.otherAnnual]))
        Self.settle(window)
        XCTAssertTrue(Self.containsText("Yearly:", in: view))

        fixture.model.tabControlContext.selectedTabId = "monthly"
        Self.settle(window)
        XCTAssertEqual(fixture.parent.package?.identifier, fixture.monthly.identifier)
    }

    private struct Fixture {

        let view: AnyView
        let model: TabsComponentViewModel
        let parent: PackageContext
        let monthly: Package
        let otherAnnual: Package
        let premium: Package

    }

    private func makeFixture(emptyAnnualTab: Bool = false) throws -> Fixture {
        let annual = Self.package(price: 94.99, annual: true)
        let monthly = Self.package(price: 13.99, annual: false)
        let otherAnnual = Self.package(price: 69.99, annual: true)
        let premium = Self.package(price: 129.99, annual: true)
        let packages = [annual, monthly, otherAnnual, premium]
        let factory = ViewModelFactory()
        let component = PaywallComponent.TabsComponent(
            control: .init(type: .buttons, stack: .init(components: [
                .tabControlButton(.init(tabId: "annual", stack: Self.textStack("badge"))),
                .tabControlButton(.init(tabId: "monthly", stack: Self.textStack("monthly")))
            ])),
            tabs: [
                .init(id: "annual", stack: .init(components: [.tabControl(.init())] + (emptyAnnualTab ? [] : [
                    Self.plan(annual, selected: true), Self.plan(monthly), Self.plan(otherAnnual)
                ]))),
                .init(id: "monthly", stack: .init(components: [
                    .tabControl(.init()), Self.plan(monthly, selected: true), Self.plan(otherAnnual)
                ]))
            ],
            defaultTabId: "annual"
        )
        guard case .tabs(let model) = try factory.toViewModel(
            component: .tabs(component), packageValidator: factory.packageValidator,
            offering: Offering(identifier: "test", serverDescription: "", availablePackages: packages,
                               webCheckoutUrl: nil),
            localizationProvider: LocalizationProvider(locale: Locale(identifier: "en_US"), localizedStrings: [
                "badge": .string("Yearly: {{ product.relative_discount }}"),
                "monthly": .string("Monthly"), "plan": .string("Plan")
            ]),
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make()), colorScheme: .light
        ) else { throw NSError(domain: "Expected tabs", code: 1) }
        let parent = PackageContext(
            package: emptyAnnualTab ? premium : nil, variableContext: .init(packages: packages)
        )
        let view = LoadedTabsComponentView(viewModel: model, parentPackageContext: parent, onDismiss: {})
            .previewRequiredPaywallsV2Properties(packageContext: parent)
            .frame(width: 400, height: 600)
        return Fixture(view: AnyView(view), model: model, parent: parent,
                       monthly: monthly, otherAnnual: otherAnnual, premium: premium)
    }

    private static func plan(_ package: Package, selected: Bool = false) -> PaywallComponent {
        .package(.init(packageID: package.identifier, isSelectedByDefault: selected,
                       visible: nil, applePromoOfferProductCode: nil, stack: Self.textStack("plan")))
    }

    private static func textStack(_ key: String) -> PaywallComponent.StackComponent {
        .init(components: [.text(.init(text: key, color: .init(light: .hex("#000000"))))])
    }

    private static func package(price: Decimal, annual: Bool) -> Package {
        let product = TestStoreProduct(
            localizedTitle: "Subscription", price: price, currencyCode: "USD",
            localizedPriceString: "$\(price)", productIdentifier: "plan_\(price)",
            productType: .autoRenewableSubscription, localizedDescription: "Subscription",
            subscriptionPeriod: .init(value: 1, unit: annual ? .year : .month),
            locale: Locale(identifier: "en_US")
        )
        return Package(identifier: product.productIdentifier, packageType: .custom,
                       storeProduct: product.toStoreProduct(), offeringIdentifier: "test", webCheckoutUrl: nil)
    }

    private static func host<Content: View>(_ view: Content) -> (UIWindow, UIView) {
        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 600))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        Self.settle(window)
        return (window, controller.view)
    }

    private static func settle(_ window: UIWindow) {
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        window.rootViewController?.view.layoutIfNeeded()
    }

    private static func containsText(_ text: String, in view: UIView) -> Bool {
        let image = UIGraphicsImageRenderer(bounds: view.bounds).image { context in
            view.layer.render(in: context.cgContext)
        }
        guard let cgImage = image.cgImage else { return false }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        do {
            try VNImageRequestHandler(cgImage: cgImage).perform([request])
            let strings = request.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
            return strings.contains(text)
        } catch {
            XCTFail("Text recognition failed: \(error)")
            return false
        }
    }
}

#endif
