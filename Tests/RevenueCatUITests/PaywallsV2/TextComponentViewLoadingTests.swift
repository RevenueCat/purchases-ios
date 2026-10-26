//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TextComponentViewLoadingTests.swift
//
//  Created by RevenueCat on 5/12/26.

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting
import SwiftUI
import XCTest

#if !os(watchOS) && !os(tvOS) && !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TextComponentViewLoadingTests: BaseSnapshotTest {

    private static let snapshotSize = CGSize(width: 300, height: 60)

    func testTextIsRedactedWhileLoading() throws {
        // The string on screen is still "Hello, world"; an intro-offer override can replace it,
        // so the placeholder stays until eligibility resolves.
        try Self.makeTextComponentView(
            text: "Hello, world",
            isLoading: true,
            introOfferText: "Start your free trial"
        )
        .snapshot(size: Self.snapshotSize)
    }

    func testStaticTextIsVisibleWhileLoading() throws {
        try Self.makeTextComponentView(text: "Hello, world", isLoading: true)
            .snapshot(size: Self.snapshotSize)
    }

    func testTextIsVisibleWhenLoaded() throws {
        try Self.makeTextComponentView(text: "Hello, world", isLoading: false)
            .snapshot(size: Self.snapshotSize)
    }

    func testHostedTextUpdatesRedactionWhenSelectedPackageChanges() throws {
        let packages = [TestData.monthlyPackage, TestData.lifetimePackage]
        let context = PackageContext(package: packages[0], variableContext: .init(packages: packages))
        let view = try Self.makeTextComponentView(
            text: "Hello, world",
            isLoading: true,
            introOfferText: "Start your free trial",
            packageContext: context
        )
        .environment(\.offerEligibilityAvailability,
                     OfferEligibilityAvailability(packageInfos: packages.map { ($0, nil) }))
        let controller = UIHostingController(rootView: view
            .frame(width: Self.snapshotSize.width, height: Self.snapshotSize.height))
        let monthly = try self.render(controller)
        context.update(package: packages[1], variableContext: context.variableContext)
        let lifetime = try self.render(controller)
        XCTAssertNotEqual(monthly, lifetime, "Only the intro-bearing package should redact this static base text.")

        context.update(package: packages[0], variableContext: context.variableContext)
        XCTAssertEqual(try self.render(controller), monthly, "Selecting monthly again must restore redaction.")
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension TextComponentViewLoadingTests {

    func render(_ controller: UIViewController) throws -> Data {
        let rendered = self.expectation(description: "Text rendered")
        var imageData: Data?
        Snapshotting<UIViewController, UIImage>
            .image(size: Self.snapshotSize, traits: .init(userInterfaceStyle: .light))
            .snapshot(controller).run { image in
                imageData = image.pngData()
                rendered.fulfill()
            }
        self.wait(for: [rendered], timeout: 2)
        return try XCTUnwrap(imageData)
    }

    static func makeTextComponentView(
        text: String,
        isLoading: Bool,
        introOfferText: String? = nil,
        packageContext: PackageContext? = nil
    ) throws -> some View {
        var localizedStrings: PaywallComponent.LocalizationDictionary = [
            "text_key": .string(text)
        ]
        var overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialTextComponent>?
        if let introOfferText {
            localizedStrings["intro_text_key"] = .string(introOfferText)
            overrides = [
                .init(
                    conditions: [.introOffer],
                    properties: .init(visible: nil, text: "intro_text_key")
                )
            ]
        }

        let viewModel = try TextComponentViewModel(
            localizationProvider: LocalizationProvider(
                locale: Locale(identifier: "en_US"),
                localizedStrings: localizedStrings
            ),
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make()),
            component: PaywallComponent.TextComponent(
                text: "text_key",
                color: .init(light: .hex("#000000")),
                overrides: overrides
            )
        )
        return TextComponentView(viewModel: viewModel)
            .previewRequiredPaywallsV2Properties(packageContext: packageContext)
            .environment(
                \.offerEligibilityLoading,
                isLoading ? [.intro, .promo] : []
            )
    }

}

#endif
