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

    @MainActor
    func testHeroDetectionUsesRenderedStackVisibility() throws {
        let hero = PaywallComponent.image(.init(
            source: .init(light: .init(
                width: 400, height: 240,
                original: Self.sampleURL, heic: Self.sampleURL, heicLowRes: Self.sampleURL
            )),
            size: .init(width: .fill, height: .fixed(240))
        ))
        let side = PaywallComponent.stack(.init(
            visible: false, components: [.webView(Self.webViewComponent(width: .fixed(200)))],
            overrides: [.init(
                extendedConditions: [.windowWidth(operator: .greaterThanOrEqual, value: 800)],
                properties: .init(visible: true)
            )]
        ))
        let provider = try Self.createUIConfigProvider()
        let factory = ViewModelFactory()
        let stack = try factory.toStackViewModel(
            component: .init(components: [.fallbackHeader, side, hero], dimension: .zlayer(.top)),
            packageValidator: factory.packageValidator, purchaseButtonCollector: nil,
            localizationProvider: .init(locale: .current, localizedStrings: [:]),
            uiConfigProvider: provider, offering: Self.mockOffering, colorScheme: .light
        )
        for width in [400, 900, 400] {
            let visible: (StackComponentViewModel) -> Bool = { stack in
                stack.styles(
                    state: .default, condition: .compact, isEligibleForIntroOffer: false,
                    isEligibleForPromoOffer: false, selectedPackageId: nil, customVariables: [:],
                    windowSize: CGSize(width: CGFloat(width), height: 700), colorScheme: .light
                ).visible
            }
            let resolvedMedia: (PaywallComponentViewModel) -> StackComponentViewModel.ResolvedMedia? = {
                self.resolvedMedia(for: $0, windowWidth: CGFloat(width))
            }
            XCTAssertEqual(
                stack.firstVisibleMedia(isStackVisible: visible, resolvedMedia: resolvedMedia) != nil,
                width < 800
            )
            XCTAssertEqual(
                stack.safeAreaExemptChildIndex(
                    dimension: stack.component.dimension,
                    isStackVisible: visible,
                    resolvedMedia: resolvedMedia
                ),
                width < 800 ? 1 : nil
            )
        }
    }

    @MainActor
    func testHeroDetectionPreservesVisibleLeadingComponents() throws {
        let hero = PaywallComponent.webView(Self.webViewComponent(width: .fill))
        let text = PaywallComponent.text(.init(text: "text", color: Self.black))
        let cases: [([PaywallComponent], Bool, Int?)] = [
            ([hero], true, 0),
            ([.fallbackHeader, hero], true, 0),
            ([.webView(Self.webViewComponent(width: .fixed(200))), hero], false, nil),
            ([text, hero], false, nil),
            ([.stack(.init(components: [])), hero], false, nil),
            ([.stack(.init(components: [hero]))], true, nil),
            ([.stack(.init(visible: false, components: [text])), hero], true, 1),
            ([.stack(.init(components: [
                .stack(.init(visible: false, components: [text])), hero
            ]))], false, nil),
            ([.stack(.init(visible: false, components: [text])), .stack(.init(components: [hero]))], true, 1),
            ([.stack(.init(visible: false, components: [hero])), .stack(.init(components: [hero]))], true, 1),
            ([.stack(.init(visible: false, components: [hero])), .stack(.init(components: [text]))], false, nil),
            ([.stack(.init(visible: false, components: [text])), .stack(.init(
                components: [.stack(.init(components: [hero])), text], dimension: .zlayer(.top)
            ))], false, nil),
            ([.stack(.init(visible: false, components: [text])), .stack(.init(components: [
                .stack(.init(visible: false, components: [hero])), text
            ]))], false, nil)
        ]
        let factory = ViewModelFactory()
        for (components, expectsMedia, directIndex) in cases {
            let stack = try factory.toStackViewModel(
                component: .init(components: components, dimension: .zlayer(.top)),
                packageValidator: factory.packageValidator, purchaseButtonCollector: nil,
                localizationProvider: .init(locale: .current, localizedStrings: ["text": .string("Text")]),
                uiConfigProvider: try Self.createUIConfigProvider(), offering: Self.mockOffering, colorScheme: .light
            )
            let visible: (StackComponentViewModel) -> Bool = { stack in
                stack.styles(
                    state: .default, condition: .compact, isEligibleForIntroOffer: false,
                    isEligibleForPromoOffer: false, selectedPackageId: nil,
                    customVariables: [:], colorScheme: .light
                ).visible
            }
            let resolvedMedia: (PaywallComponentViewModel) -> StackComponentViewModel.ResolvedMedia? = {
                self.resolvedMedia(for: $0)
            }
            XCTAssertEqual(
                stack.firstVisibleMedia(isStackVisible: visible, resolvedMedia: resolvedMedia) != nil,
                expectsMedia
            )
            XCTAssertEqual(
                stack.safeAreaExemptChildIndex(
                    dimension: stack.component.dimension,
                    isStackVisible: visible,
                    resolvedMedia: resolvedMedia
                ),
                directIndex
            )
        }
    }

    @MainActor
    func testHeroDetectionUsesRenderedMediaVisibilityAndSize() throws {
        func image(
            visible: Bool? = nil,
            overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialImageComponent>? = nil
        ) -> PaywallComponent {
            .image(.init(
                visible: visible,
                source: .init(light: .init(
                    width: 400, height: 240,
                    original: Self.sampleURL, heic: Self.sampleURL, heicLowRes: Self.sampleURL
                )),
                size: .init(width: .fill, height: .fixed(240)),
                overrides: overrides
            ))
        }
        let cases: [([PaywallComponent], CGFloat, Bool)] = [
            ([image(visible: false)], 400, false),
            ([image(visible: false), image()], 400, true),
            ([image(overrides: [.init(
                extendedConditions: [.windowWidth(operator: .greaterThanOrEqual, value: 800)],
                properties: .init(size: .init(width: .fixed(200), height: .fixed(240)))
            )])], 900, false),
            ([image()], 400, true)
        ]
        let factory = ViewModelFactory()
        for (components, width, expected) in cases {
            let stack = try factory.toStackViewModel(
                component: .init(components: components),
                packageValidator: factory.packageValidator,
                purchaseButtonCollector: nil,
                localizationProvider: .init(locale: .current, localizedStrings: [:]),
                uiConfigProvider: try Self.createUIConfigProvider(),
                offering: Self.mockOffering,
                colorScheme: .light
            )
            XCTAssertEqual(
                stack.firstVisibleMedia(
                    isStackVisible: { _ in true },
                    resolvedMedia: { self.resolvedMedia(for: $0, windowWidth: width) }
                ) != nil,
                expected
            )
        }
    }

    @MainActor
    func testSafeAreaExemptChildUsesRenderedDimension() throws {
        let hero = PaywallComponent.webView(Self.webViewComponent(width: .fill))
        let factory = ViewModelFactory()
        let stack = try factory.toStackViewModel(
            component: .init(components: [hero], dimension: .vertical(.center, .start)),
            packageValidator: factory.packageValidator,
            purchaseButtonCollector: nil,
            localizationProvider: .init(locale: .current, localizedStrings: [:]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            offering: Self.mockOffering,
            colorScheme: .light
        )
        let resolvedMedia: (PaywallComponentViewModel) -> StackComponentViewModel.ResolvedMedia? = {
            self.resolvedMedia(for: $0)
        }
        XCTAssertEqual(
            stack.safeAreaExemptChildIndex(
                dimension: .zlayer(.top),
                isStackVisible: { _ in true },
                resolvedMedia: resolvedMedia
            ),
            0
        )
        XCTAssertNil(stack.safeAreaExemptChildIndex(
            dimension: stack.component.dimension,
            isStackVisible: { _ in true },
            resolvedMedia: resolvedMedia
        ))
    }

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

        expect(root.firstItemIsFullWidthMedia).to(beTrue())

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
                        size: .init(width: .fill, height: .fit(nil))
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

        expect(root.firstItemIsFullWidthMedia).to(beFalse())
        expect(root.headerViewModel?.firstItemIgnoresSafeArea).to(beTrue())
        expect(root.shouldOverlayHeader).to(beTrue())
    }

    @MainActor
    func testRootImageInZStackAtNonZeroIndexDoesNotDetectHero() throws {
        // With simplified detection (matching dashboard), only the first non-stack
        // component is checked. A text at index 0 means no hero is detected.
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
                        size: .init(width: .fill, height: .fit(nil))
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

        expect(root.firstItemIsFullWidthMedia).to(beFalse())
        expect(root.shouldOverlayHeader).to(beFalse())
    }

    @MainActor
    func testStackBackgroundImageDoesNotDetectHero() throws {
        // Background images on stacks are no longer detected as hero images
        // (matching dashboard/Android behavior).
        let heroStack = PaywallComponent.StackComponent(
            components: [
                .text(.init(text: "badge_text_lid", color: Self.black))
            ],
            dimension: .vertical(.leading, .start),
            size: .init(width: .fill, height: .fit(nil)),
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

        expect(root.firstItemIsFullWidthMedia).to(beFalse())

        expect(root.shouldOverlayHeader).to(beFalse())
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
                    size: .init(width: .fill, height: .fit(nil))
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

        // With simplified detection, image at non-zero index in ZStack is not detected
        expect(root.headerViewModel?.firstItemIgnoresSafeArea).to(beFalse())
        expect(root.shouldOverlayHeader).to(beFalse())
    }

    @MainActor
    func testRootVideoOverlaysHeader() throws {
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
                    size: .init(width: .fill, height: .fit(nil))
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

        expect(root.firstItemIsFullWidthMedia).to(beTrue())

        expect(root.headerViewModel?.firstItemIgnoresSafeArea).to(beFalse())
        expect(root.shouldOverlayHeader).to(beTrue())
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
                    size: .init(width: .fill, height: .fit(nil))
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
        expect(root.shouldOverlayHeader).to(beFalse())
    }

    // MARK: - Web View Hero Tests

    @MainActor
    func testRootWebViewOverlaysHeader() throws {
        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: [
                .webView(Self.webViewComponent(width: .fill))
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

        expect(root.firstItemIsFullWidthMedia).to(beTrue())

        // Like a video hero, a web view hero overlays the header but does not remove the
        // header's own top safe-area inset.
        expect(root.headerViewModel?.firstItemIgnoresSafeArea).to(beFalse())
        expect(root.shouldOverlayHeader).to(beTrue())
    }

    @MainActor
    func testRootWebViewNotFullWidthDoesNotDetectHero() throws {
        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: [
                .webView(Self.webViewComponent(width: .fixed(100)))
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

        expect(root.firstItemIsFullWidthMedia).to(beFalse())
        expect(root.shouldOverlayHeader).to(beFalse())
    }

    @MainActor
    func testRootWebViewNestedInStackDetectsHero() throws {
        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: [
                .stack(.init(
                    components: [
                        .webView(Self.webViewComponent(width: .fill))
                    ],
                    dimension: .vertical(.leading, .start)
                ))
            ]),
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

        // Detection drills through nested stacks to reach the first full-width web view.
        expect(root.firstItemIsFullWidthMedia).to(beTrue())
    }

    @MainActor
    func testHeaderWebViewDoesNotIgnoreSafeAreaOrOverlay() throws {
        let headerStack = PaywallComponent.StackComponent(
            components: [
                .webView(Self.webViewComponent(width: .fill)),
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

        // A web view in the header behaves like a video: it does not remove the header inset.
        expect(root.headerViewModel?.firstItemIgnoresSafeArea).to(beFalse())
        expect(root.shouldOverlayHeader).to(beFalse())
    }

    @MainActor
    func testFallbackHeaderIsSkippedWhenDetectingFirstFullWidthWebView() throws {
        let rootStack = PaywallComponent.StackComponent(
            components: [
                .fallbackHeader,
                .webView(Self.webViewComponent(width: .fill))
            ],
            dimension: .vertical(.leading, .start),
            size: .init(width: .fill, height: .fit(nil))
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
            localizationProvider: .init(locale: .current, localizedStrings: [:]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )

        // fallbackHeader should be skipped; the full-width web view should be detected.
        expect(root.firstItemIsFullWidthMedia).to(beTrue())
    }

    @MainActor
    func testZLayerFirstChildFullWidthWebViewIsDetectedAsMedia() throws {
        let stackComponent = PaywallComponent.StackComponent(
            components: [
                .webView(Self.webViewComponent(width: .fill)),
                .text(.init(text: "text_lid", color: Self.black))
            ],
            dimension: .zlayer(.top)
        )

        let factory = ViewModelFactory()
        let viewModel = try factory.toStackViewModel(
            component: stackComponent,
            packageValidator: factory.packageValidator,
            purchaseButtonCollector: nil,
            localizationProvider: .init(locale: .current, localizedStrings: [
                "text_lid": .string("Hello")
            ]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            offering: Self.mockOffering,
            colorScheme: .light
        )

        expect(viewModel.safeAreaExemptChildIndex(
            dimension: viewModel.component.dimension,
            isStackVisible: { _ in true },
            resolvedMedia: { self.resolvedMedia(for: $0) }
        ) != nil).to(beTrue())
    }

    @MainActor
    func testZLayerFirstChildNonFullWidthWebViewIsNotDetectedAsMedia() throws {
        let stackComponent = PaywallComponent.StackComponent(
            components: [
                .webView(Self.webViewComponent(width: .fixed(100))),
                .text(.init(text: "text_lid", color: Self.black))
            ],
            dimension: .zlayer(.top)
        )

        let factory = ViewModelFactory()
        let viewModel = try factory.toStackViewModel(
            component: stackComponent,
            packageValidator: factory.packageValidator,
            purchaseButtonCollector: nil,
            localizationProvider: .init(locale: .current, localizedStrings: [
                "text_lid": .string("Hello")
            ]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            offering: Self.mockOffering,
            colorScheme: .light
        )

        expect(viewModel.safeAreaExemptChildIndex(
            dimension: viewModel.component.dimension,
            isStackVisible: { _ in true },
            resolvedMedia: { self.resolvedMedia(for: $0) }
        ) != nil).to(beFalse())
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

    // MARK: - Fallback Header Tests

    @MainActor
    func testFallbackHeaderIsFilteredOutFromStackViewModels() throws {
        let stackComponent = PaywallComponent.StackComponent(
            components: [
                .fallbackHeader,
                .text(.init(text: "text_lid", color: Self.black))
            ],
            dimension: .vertical(.leading, .start),
            size: .init(width: .fill, height: .fit(nil))
        )

        let factory = ViewModelFactory()
        let viewModel = try factory.toStackViewModel(
            component: stackComponent,
            packageValidator: factory.packageValidator,
            purchaseButtonCollector: nil,
            localizationProvider: .init(locale: .current, localizedStrings: [
                "text_lid": .string("Hello")
            ]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            offering: Self.mockOffering,
            colorScheme: .light
        )

        // Only the text component should remain; fallbackHeader should be filtered out
        expect(viewModel.viewModels.count) == 1
        guard case .text = viewModel.viewModels.first else {
            fail("Expected a text view model but got \(String(describing: viewModel.viewModels.first))")
            return
        }
    }

    @MainActor
    func testFallbackHeaderIsSkippedWhenDetectingFirstFullWidthImage() throws {
        let imageComponent = PaywallComponent.ImageComponent(
            source: .init(light: .init(
                width: 800, height: 600,
                original: Self.sampleURL,
                heic: Self.sampleURL,
                heicLowRes: Self.sampleURL
            )),
            size: .init(width: .fill, height: .fit(nil))
        )

        let rootStack = PaywallComponent.StackComponent(
            components: [
                .fallbackHeader,
                .image(imageComponent)
            ],
            dimension: .vertical(.leading, .start),
            size: .init(width: .fill, height: .fit(nil))
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
            localizationProvider: .init(locale: .current, localizedStrings: [:]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )

        // fallbackHeader should be skipped; the full-width image should be detected
        expect(root.firstItemIsFullWidthMedia).to(beTrue())

    }

    // MARK: - Helpers

    private static let black = PaywallComponent.ColorScheme(
        light: .hex("#000000")
    )

    // swiftlint:disable:next force_unwrapping
    private static let sampleURL = URL(string: "https://revenuecat.com/image.heic")!

    private static func webViewComponent(
        width: PaywallComponent.SizeConstraint
    ) -> PaywallComponent.WebViewComponent {
        .init(
            id: "web_view_id",
            protocolVersion: PaywallComponent.WebViewComponent.supportedProtocolVersion,
            url: "https://revenuecat.com",
            size: .init(width: width, height: .fit(nil))
        )
    }

    private func resolvedMedia(
        for viewModel: PaywallComponentViewModel,
        windowWidth: CGFloat? = nil
    ) -> StackComponentViewModel.ResolvedMedia? {
        viewModel.resolvedMedia(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            selectedPackageId: nil,
            customVariables: [:],
            stateValues: [:],
            stateDefaults: [:],
            windowSize: windowWidth.map { CGSize(width: $0, height: 700) },
            colorScheme: .light
        )
    }

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
