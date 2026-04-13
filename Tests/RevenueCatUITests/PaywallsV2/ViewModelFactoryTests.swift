//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ViewModelFactoryTests.swift
//
//  Created by Facundo Menzella on 4/9/26.

import Nimble
@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class ViewModelFactoryTests: TestCase {

    // MARK: - Unsupported Condition Tests

    @MainActor
    func testTabsOverrideWithSelectedPackageCondition_DoesNotThrowUnsupportedCondition() throws {
        let tabs = PaywallComponent.TabsComponent(
            control: .init(
                type: .buttons,
                stack: .init(
                    components: [
                        .tabControlButton(.init(
                            tabId: "tab_1",
                            stack: .init(components: [])
                        ))
                    ]
                )
            ),
            tabs: [
                .init(
                    id: "tab_1",
                    stack: .init(components: [])
                )
            ],
            overrides: [
                .init(
                    extendedConditions: [
                        .selectedPackage(operator: .in, packages: ["annual"])
                    ],
                    properties: .init(visible: false)
                )
            ]
        )

        let factory = ViewModelFactory()
        let packageValidator = PackageValidator()

        expect {
            _ = try factory.toViewModel(
                component: .tabs(tabs),
                packageValidator: packageValidator,
                heroSafeAreaInfo: nil,
                purchaseButtonCollector: nil,
                offering: Self.mockOffering,
                localizationProvider: .init(locale: .current, localizedStrings: [:]),
                uiConfigProvider: try Self.createUIConfigProvider(),
                colorScheme: .light
            )
        }.toNot(throwError())
    }

    @MainActor
    func testGlobalUnsupported_DiscardsRulesFromComponentWithoutUnsupported() throws {
        let textWithUnsupported = PaywallComponent.TextComponent(
            text: "badge_text_lid",
            color: Self.black,
            overrides: [
                .init(extendedConditions: [.unsupported], properties: .init())
            ]
        )

        let textWithRule = PaywallComponent.TextComponent(
            text: "badge_text_lid",
            color: Self.black,
            overrides: [
                .init(extendedConditions: [
                    .selectedPackage(operator: .in, packages: ["monthly"])
                ], properties: .init(fontWeight: .bold))
            ]
        )

        let rootStack = PaywallComponent.StackComponent(
            components: [.text(textWithUnsupported), .text(textWithRule)]
        )

        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: rootStack,
            stickyFooter: nil,
            background: .color(.init(light: .hex("#FFFFFF")))
        )

        var factory = ViewModelFactory()
        let root = try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: Self.mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [
                "badge_text_lid": .string("Text")
            ]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )

        expect(factory.discardRules).to(beTrue())
        expect(root.stackViewModel.viewModels.count).to(equal(2))
    }

    @MainActor
    func testGlobalUnsupported_InStickyFooter_DiscardsRulesFromMainStack() throws {
        let textWithRule = PaywallComponent.TextComponent(
            text: "badge_text_lid",
            color: Self.black,
            overrides: [
                .init(extendedConditions: [
                    .variable(operator: .equals, variable: "plan", value: .string("pro"))
                ], properties: .init(fontWeight: .bold))
            ]
        )

        let footerText = PaywallComponent.TextComponent(
            text: "badge_text_lid",
            color: Self.black,
            overrides: [
                .init(extendedConditions: [.unsupported], properties: .init())
            ]
        )
        let stickyFooter = PaywallComponent.StickyFooterComponent(
            stack: .init(components: [.text(footerText)])
        )

        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: [.text(textWithRule)]),
            stickyFooter: stickyFooter,
            background: .color(.init(light: .hex("#FFFFFF")))
        )

        var factory = ViewModelFactory()
        _ = try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: Self.mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [
                "badge_text_lid": .string("Text")
            ]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )

        expect(factory.discardRules).to(beTrue())
    }

    @MainActor
    func testGlobalUnsupported_InHeader_DiscardsRulesFromMainStack() throws {
        let textWithRule = PaywallComponent.TextComponent(
            text: "badge_text_lid",
            color: Self.black,
            overrides: [
                .init(extendedConditions: [
                    .variable(operator: .equals, variable: "plan", value: .string("pro"))
                ], properties: .init(fontWeight: .bold))
            ]
        )

        let headerText = PaywallComponent.TextComponent(
            text: "badge_text_lid",
            color: Self.black,
            overrides: [
                .init(extendedConditions: [.unsupported], properties: .init())
            ]
        )

        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: [.text(textWithRule)]),
            header: .init(stack: .init(components: [.text(headerText)])),
            stickyFooter: nil,
            background: .color(.init(light: .hex("#FFFFFF")))
        )

        var factory = ViewModelFactory()
        _ = try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: Self.mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [
                "badge_text_lid": .string("Text")
            ]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )

        expect(factory.discardRules).to(beTrue())
    }

    @MainActor
    func testNoUnsupported_DiscardRulesIsFalse() throws {
        let textWithRule = PaywallComponent.TextComponent(
            text: "badge_text_lid",
            color: Self.black,
            overrides: [
                .init(extendedConditions: [
                    .selectedPackage(operator: .in, packages: ["monthly"])
                ], properties: .init(fontWeight: .bold))
            ]
        )

        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: [.text(textWithRule)]),
            stickyFooter: nil,
            background: .color(.init(light: .hex("#FFFFFF")))
        )

        var factory = ViewModelFactory()
        _ = try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: Self.mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [
                "badge_text_lid": .string("Text")
            ]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )

        expect(factory.discardRules).to(beFalse())
    }

    @MainActor
    func testGlobalUnsupported_InButtonSheetDestination_DiscardsRulesFromRootStack() throws {
        let textWithRule = PaywallComponent.TextComponent(
            text: "badge_text_lid",
            color: Self.black,
            overrides: [
                .init(extendedConditions: [
                    .selectedPackage(operator: .in, packages: ["monthly"])
                ], properties: .init(fontWeight: .bold))
            ]
        )

        let sheetText = PaywallComponent.TextComponent(
            text: "badge_text_lid",
            color: Self.black,
            overrides: [
                .init(extendedConditions: [.unsupported], properties: .init())
            ]
        )
        let button = PaywallComponent.ButtonComponent(
            action: .navigateTo(destination: .sheet(sheet: .init(
                id: "sheet_1",
                name: nil,
                stack: .init(components: [.text(sheetText)]),
                backgroundBlur: false,
                size: nil
            ))),
            stack: .init(components: [
                .text(.init(text: "badge_text_lid", color: Self.black))
            ])
        )

        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: [.text(textWithRule), .button(button)]),
            stickyFooter: nil,
            background: .color(.init(light: .hex("#FFFFFF")))
        )

        var factory = ViewModelFactory()
        _ = try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: Self.mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [
                "badge_text_lid": .string("Text")
            ]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )

        expect(factory.discardRules).to(beTrue())
    }

    @MainActor
    func testGlobalUnsupported_InNestedTabsComponent_DiscardsRulesFromSibling() throws {
        let textWithRule = PaywallComponent.TextComponent(
            text: "badge_text_lid",
            color: Self.black,
            overrides: [
                .init(extendedConditions: [
                    .variable(operator: .equals, variable: "tier", value: .string("pro"))
                ], properties: .init(fontWeight: .bold))
            ]
        )

        let tabText = PaywallComponent.TextComponent(
            text: "badge_text_lid",
            color: Self.black,
            overrides: [
                .init(extendedConditions: [.unsupported], properties: .init())
            ]
        )
        let tabs = PaywallComponent.TabsComponent(
            control: .init(
                type: .buttons,
                stack: .init(components: [
                    .tabControlButton(.init(tabId: "tab_1", stack: .init(components: [])))
                ])
            ),
            tabs: [.init(
                id: "tab_1",
                stack: .init(components: [.text(tabText)])
            )]
        )

        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: [.text(textWithRule), .tabs(tabs)]),
            stickyFooter: nil,
            background: .color(.init(light: .hex("#FFFFFF")))
        )

        var factory = ViewModelFactory()
        _ = try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: Self.mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [
                "badge_text_lid": .string("Text")
            ]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )

        expect(factory.discardRules).to(beTrue())
    }

    // MARK: - Header Tests

    @MainActor
    func testRootViewModelCreatesHeaderViewModelWhenHeaderPresent() throws {
        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: []),
            header: .init(stack: .init(components: [
                .text(.init(text: "badge_text_lid", color: Self.black))
            ])),
            stickyFooter: nil,
            background: .color(.init(light: .hex("#FFFFFF")))
        )

        var factory = ViewModelFactory()
        let root = try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: Self.mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [
                "badge_text_lid": .string("Text")
            ]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )

        expect(root.headerViewModel).toNot(beNil())
        expect(root.headerViewModel?.stackViewModel.viewModels).to(haveCount(1))
    }

    @MainActor
    func testNonImageHeaderDoesNotBlockRootSafeAreaIgnoreInfo() throws {
        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: [
                .image(
                    .init(
                        source: .init(light: .init(
                            width: 1,
                            height: 1,
                            original: Self.sampleURL,
                            heic: Self.sampleURL,
                            heicLowRes: Self.sampleURL
                        ))
                    )
                )
            ]),
            header: .init(stack: .init(components: [
                .text(.init(text: "badge_text_lid", color: Self.black))
            ])),
            stickyFooter: nil,
            background: .color(.init(light: .hex("#FFFFFF")))
        )

        var factory = ViewModelFactory()
        let root = try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: Self.mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [
                "badge_text_lid": .string("Text")
            ]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )

        expect(root.heroSafeAreaInfo).toNot(beNil())
        expect(root.headerViewModel?.firstItemIgnoresSafeArea).to(beFalse())
        expect(root.shouldOverlayHeader).to(beTrue())
    }

    @MainActor
    func testHeaderHeroUsesHeaderSafeAreaIgnoreInfoWithoutAffectingRootHeroInfo() throws {
        let headerStack = PaywallComponent.StackComponent(
            components: [
                .image(
                    .init(
                        source: .init(light: .init(
                            width: 1,
                            height: 1,
                            original: Self.sampleURL,
                            heic: Self.sampleURL,
                            heicLowRes: Self.sampleURL
                        )),
                        size: .init(width: .fill, height: .fit)
                    )
                ),
                .text(.init(text: "badge_text_lid", color: Self.black))
            ],
            dimension: .zlayer(.top)
        )
        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: []),
            header: .init(stack: headerStack),
            stickyFooter: nil,
            background: .color(.init(light: .hex("#FFFFFF")))
        )

        var factory = ViewModelFactory()
        let root = try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: Self.mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [:]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )

        expect(root.heroSafeAreaInfo).to(beNil())
        expect(root.headerViewModel?.firstItemIgnoresSafeArea).to(beTrue())
        expect(root.headerViewModel?.stackViewModel.shouldApplySafeAreaInsetToZStackChildren).to(beTrue())
        expect(root.shouldOverlayHeader).to(beTrue())
    }

    @MainActor
    func testRootHeroImageInZStackAtNonZeroIndexStillInsetsOverlayContent() throws {
        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(
                components: [
                    .text(.init(text: "badge_text_lid", color: Self.black)),
                    .image(.init(
                        source: .init(light: .init(
                            width: 1,
                            height: 1,
                            original: Self.sampleURL,
                            heic: Self.sampleURL,
                            heicLowRes: Self.sampleURL
                        )),
                        size: .init(width: .fill, height: .fit)
                    ))
                ],
                dimension: .zlayer(.top)
            ),
            header: .init(stack: .init(components: [
                .text(.init(text: "badge_text_lid", color: Self.black))
            ])),
            stickyFooter: nil,
            background: .color(.init(light: .hex("#FFFFFF")))
        )

        var factory = ViewModelFactory()
        let root = try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: Self.mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [
                "badge_text_lid": .string("Text")
            ]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )

        expect(root.heroSafeAreaInfo?.imageComponent).toNot(beNil())
        expect(root.heroSafeAreaInfo?.parentZStackBackgroundIndex).to(equal(1))
        expect(root.stackViewModel.shouldApplySafeAreaInsetToZStackChildren).to(beTrue())
        expect(root.stackViewModel.safeAreaInsetExemptChildIndex).to(equal(1))
        expect(root.shouldOverlayHeader).to(beTrue())
    }

    @MainActor
    func testRootHeroImageBackgroundStackInsetsContentAndOverlaysHeader() throws {
        let heroStack = PaywallComponent.StackComponent(
            components: [
                .text(.init(text: "badge_text_lid", color: Self.black))
            ],
            dimension: .vertical(.leading, .start),
            size: .init(width: .fill, height: .fit),
            background: .image(
                .init(light: .init(
                    width: 1,
                    height: 1,
                    original: Self.sampleURL,
                    heic: Self.sampleURL,
                    heicLowRes: Self.sampleURL
                )),
                .fill,
                nil
            )
        )
        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: [
                .stack(heroStack),
                .text(.init(text: "badge_text_lid", color: Self.black))
            ]),
            header: .init(stack: .init(components: [
                .text(.init(text: "badge_text_lid", color: Self.black))
            ])),
            stickyFooter: nil,
            background: .color(.init(light: .hex("#FFFFFF")))
        )

        var factory = ViewModelFactory()
        let root = try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: Self.mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [
                "badge_text_lid": .string("Text")
            ]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )

        guard case let .stack(heroViewModel)? = root.stackViewModel.viewModels.first else {
            fail("Expected first root component to be a stack view model")
            return
        }

        expect(root.heroSafeAreaInfo?.parentBackgroundStack).toNot(beNil())
        expect(root.rootStartsWithHeroImage).to(beTrue())
        expect(heroViewModel.shouldApplySafeAreaInsetToSelf).to(beTrue())
        expect(root.shouldOverlayHeader).to(beTrue())
    }

    @MainActor
    func testHeaderHeroImageInZStackAtNonZeroIndexStillInsetsOverlayContent() throws {
        let headerStack = PaywallComponent.StackComponent(
            components: [
                .text(.init(text: "badge_text_lid", color: Self.black)),
                .image(.init(
                    source: .init(light: .init(
                        width: 1,
                        height: 1,
                        original: Self.sampleURL,
                        heic: Self.sampleURL,
                        heicLowRes: Self.sampleURL
                    )),
                    size: .init(width: .fill, height: .fit)
                ))
            ],
            dimension: .zlayer(.top)
        )
        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: []),
            header: .init(stack: headerStack),
            stickyFooter: nil,
            background: .color(.init(light: .hex("#FFFFFF")))
        )

        var factory = ViewModelFactory()
        let root = try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: Self.mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [
                "badge_text_lid": .string("Text")
            ]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )

        expect(root.headerViewModel?.firstItemIgnoresSafeArea).to(beTrue())
        expect(root.headerViewModel?.stackViewModel.shouldApplySafeAreaInsetToZStackChildren).to(beTrue())
        expect(root.headerViewModel?.stackViewModel.safeAreaInsetExemptChildIndex).to(equal(1))
        expect(root.shouldOverlayHeader).to(beTrue())
    }

    @MainActor
    func testRootVideoDoesNotOverlayHeader() throws {
        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: [
                .video(.init(
                    source: .init(light: .init(
                        width: 1,
                        height: 1,
                        url: Self.sampleURL,
                        checksum: nil,
                        urlLowRes: nil,
                        checksumLowRes: nil
                    )),
                    size: .init(width: .fill, height: .fit)
                ))
            ]),
            header: .init(stack: .init(components: [
                .text(.init(text: "badge_text_lid", color: Self.black))
            ])),
            stickyFooter: nil,
            background: .color(.init(light: .hex("#FFFFFF")))
        )

        var factory = ViewModelFactory()
        let root = try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: Self.mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [
                "badge_text_lid": .string("Text")
            ]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )

        expect(root.heroSafeAreaInfo?.videoComponent).toNot(beNil())
        expect(root.headerViewModel?.firstItemIgnoresSafeArea).to(beFalse())
        expect(root.rootStartsWithHeroImage).to(beFalse())
        expect(root.shouldOverlayHeader).to(beFalse())
    }

    @MainActor
    func testHeaderVideoDoesNotIgnoreSafeAreaOrOverlay() throws {
        let headerStack = PaywallComponent.StackComponent(
            components: [
                .video(.init(
                    source: .init(light: .init(
                        width: 1,
                        height: 1,
                        url: Self.sampleURL,
                        checksum: nil,
                        urlLowRes: nil,
                        checksumLowRes: nil
                    )),
                    size: .init(width: .fill, height: .fit)
                )),
                .text(.init(text: "badge_text_lid", color: Self.black))
            ],
            dimension: .zlayer(.top)
        )
        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: []),
            header: .init(stack: headerStack),
            stickyFooter: nil,
            background: .color(.init(light: .hex("#FFFFFF")))
        )

        var factory = ViewModelFactory()
        let root = try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: Self.mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [
                "badge_text_lid": .string("Text")
            ]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )

        expect(root.headerViewModel?.firstItemIgnoresSafeArea).to(beFalse())
        expect(root.headerViewModel?.stackViewModel.shouldApplySafeAreaInsetToZStackChildren).to(beTrue())
        expect(root.shouldOverlayHeader).to(beFalse())
    }

    // MARK: - Layout Tests

    @MainActor
    func testLayout_HeaderAndStickyFooter_BothViewModelsPresent() throws {
        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: []),
            header: .init(stack: .init(components: [])),
            stickyFooter: .init(stack: .init(components: [])),
            background: .color(.init(light: .hex("#FFFFFF")))
        )

        var factory = ViewModelFactory()
        let root = try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: Self.mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [:]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )

        expect(root.headerViewModel).toNot(beNil())
        expect(root.stickyFooterViewModel).toNot(beNil())
    }

    @MainActor
    func testLayout_HeaderOnly_StickyFooterViewModelNil() throws {
        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: []),
            header: .init(stack: .init(components: [])),
            stickyFooter: nil,
            background: .color(.init(light: .hex("#FFFFFF")))
        )

        var factory = ViewModelFactory()
        let root = try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: Self.mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [:]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )

        expect(root.headerViewModel).toNot(beNil())
        expect(root.stickyFooterViewModel).to(beNil())
        expect(root.shouldOverlayHeader).to(beFalse())
    }

    @MainActor
    func testLayout_StickyFooterOnly_HeaderViewModelNil() throws {
        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: []),
            stickyFooter: .init(stack: .init(components: [])),
            background: .color(.init(light: .hex("#FFFFFF")))
        )

        var factory = ViewModelFactory()
        let root = try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: Self.mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [:]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )

        expect(root.headerViewModel).to(beNil())
        expect(root.stickyFooterViewModel).toNot(beNil())
    }

    @MainActor
    func testLayout_BodyOnly_BothViewModelsNil() throws {
        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: []),
            stickyFooter: nil,
            background: .color(.init(light: .hex("#FFFFFF")))
        )

        var factory = ViewModelFactory()
        let root = try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: Self.mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [:]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )

        expect(root.headerViewModel).to(beNil())
        expect(root.stickyFooterViewModel).to(beNil())
    }

    // MARK: - Helpers

    private static let black = PaywallComponent.ColorScheme(
        light: .hex("#000000")
    )

    // swiftlint:disable:next force_unwrapping
    private static let sampleURL = URL(string: "https://revenuecat.com/image.heic")!

    private static func createUIConfigProvider() throws -> UIConfigProvider {
        let json = """
        {
          "app": {
            "colors": {},
            "fonts": {}
          },
          "localizations": {},
          "variable_config": {
            "variable_compatibility_map": {},
            "function_compatibility_map": {}
          }
        }
        """
        let jsonData = try XCTUnwrap(json.data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let uiConfig = try decoder.decode(UIConfig.self, from: jsonData)
        return UIConfigProvider(uiConfig: uiConfig)
    }

    private static var mockOffering: Offering {
        return .init(
            identifier: "test_offering",
            serverDescription: "Test Offering",
            metadata: [:],
            availablePackages: [],
            webCheckoutUrl: nil
        )
    }

}

#endif
