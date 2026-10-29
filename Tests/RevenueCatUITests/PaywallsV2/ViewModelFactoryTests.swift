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

    // MARK: - Hero overlays

    @MainActor
    func testZLayerLeadingToFullWidthWebViewHeroPushesOverlays() throws {
        let zStack = PaywallComponent.StackComponent(
            components: [
                .webView(Self.webViewComponent(width: .fill)),
                .text(.init(text: "text_lid", color: Self.black))
            ],
            dimension: .zlayer(.top)
        )

        let root = try Self.makeRootViewModel(stack: zStack)

        expect(root.bodyHeroMediaIdentifier).toNot(beNil())
        expect(root.stackViewModel.firstChildLeadsToHero(root.bodyHeroMediaIdentifier)).to(beTrue())
    }

    @MainActor
    func testZLayerWithNonFullWidthWebViewHasNoHero() throws {
        let zStack = PaywallComponent.StackComponent(
            components: [
                .webView(Self.webViewComponent(width: .fixed(100))),
                .text(.init(text: "text_lid", color: Self.black))
            ],
            dimension: .zlayer(.top)
        )

        let root = try Self.makeRootViewModel(stack: zStack)

        expect(root.bodyHeroMediaIdentifier).to(beNil())
        expect(root.stackViewModel.firstChildLeadsToHero(root.bodyHeroMediaIdentifier)).to(beFalse())
    }

    @MainActor
    func testZLayerPushesOverlaysWhenHeroIsWrappedInNestedStack() throws {
        let zStack = PaywallComponent.StackComponent(
            components: [
                .stack(.init(components: [.image(Self.fullWidthImageComponent())])),
                .text(.init(text: "text_lid", color: Self.black))
            ],
            dimension: .zlayer(.top)
        )
        let rootStack = PaywallComponent.StackComponent(components: [.stack(zStack)])

        let root = try Self.makeRootViewModel(stack: rootStack)
        let hero = root.bodyHeroMediaIdentifier

        expect(hero).toNot(beNil())
        let zStackViewModel = try XCTUnwrap(Self.stackViewModel(root.stackViewModel.viewModels.first))
        expect(zStackViewModel.firstChildLeadsToHero(hero)).to(beTrue())
        let wrapperViewModel = try XCTUnwrap(Self.stackViewModel(zStackViewModel.viewModels.first))
        expect(wrapperViewModel.firstChildLeadsToHero(hero)).to(beTrue())
        expect(zStackViewModel.viewModels.first?.firstNativeMediaIdentifier).to(equal(hero))
    }

    @MainActor
    func testEveryZLayerLeadingToHeroPushesOverlays() throws {
        let innerZStack = PaywallComponent.StackComponent(
            components: [
                .image(Self.fullWidthImageComponent()),
                .text(.init(text: "text_lid", color: Self.black))
            ],
            dimension: .zlayer(.bottom)
        )
        let outerZStack = PaywallComponent.StackComponent(
            components: [
                .stack(innerZStack),
                .stack(.init(components: [.text(.init(text: "text_lid", color: Self.black))]))
            ],
            dimension: .zlayer(.top)
        )

        let root = try Self.makeRootViewModel(stack: outerZStack)
        let hero = root.bodyHeroMediaIdentifier

        expect(root.stackViewModel.firstChildLeadsToHero(hero)).to(beTrue())
        let innerViewModel = try XCTUnwrap(Self.stackViewModel(root.stackViewModel.viewModels.first))
        expect(innerViewModel.firstChildLeadsToHero(hero)).to(beTrue())
    }

    @MainActor
    func testZLayerOffHeroPathDoesNotPushOverlays() throws {
        let zStack = PaywallComponent.StackComponent(
            components: [
                .image(Self.fullWidthImageComponent()),
                .text(.init(text: "text_lid", color: Self.black))
            ],
            dimension: .zlayer(.top)
        )
        let rootStack = PaywallComponent.StackComponent(components: [
            .text(.init(text: "text_lid", color: Self.black)),
            .stack(zStack)
        ])

        let root = try Self.makeRootViewModel(stack: rootStack)

        expect(root.firstItemIsFullWidthMedia).to(beFalse())
        expect(root.bodyHeroMediaIdentifier).to(beNil())
        let zStackViewModel = try XCTUnwrap(Self.stackViewModel(root.stackViewModel.viewModels.last))
        expect(zStackViewModel.firstChildLeadsToHero(root.bodyHeroMediaIdentifier)).to(beFalse())
    }

    @MainActor
    func testOnlyTheHeroZLayerPushesWhenAnotherMediaZLayerFollows() throws {
        func mediaZStack() -> PaywallComponent.StackComponent {
            .init(
                components: [
                    .image(Self.fullWidthImageComponent()),
                    .text(.init(text: "text_lid", color: Self.black))
                ],
                dimension: .zlayer(.top)
            )
        }
        let rootStack = PaywallComponent.StackComponent(components: [
            .stack(mediaZStack()),
            .stack(mediaZStack())
        ])

        let root = try Self.makeRootViewModel(stack: rootStack)
        let hero = root.bodyHeroMediaIdentifier

        let first = try XCTUnwrap(Self.stackViewModel(root.stackViewModel.viewModels.first))
        let second = try XCTUnwrap(Self.stackViewModel(root.stackViewModel.viewModels.last))
        expect(first.firstChildLeadsToHero(hero)).to(beTrue())
        expect(second.firstChildLeadsToHero(hero)).to(beFalse())
    }

    @MainActor
    func testStickyFooterMediaZLayerDoesNotLeadToTheBodyHero() throws {
        let footerZStack = PaywallComponent.StackComponent(
            components: [
                .image(Self.fullWidthImageComponent()),
                .text(.init(text: "text_lid", color: Self.black))
            ],
            dimension: .zlayer(.top)
        )
        let body = PaywallComponent.StackComponent(components: [.image(Self.fullWidthImageComponent())])

        let root = try Self.makeRootViewModel(stack: body, stickyFooter: footerZStack)

        let footer = try XCTUnwrap(root.stickyFooterViewModel?.stackViewModel)
        expect(root.bodyHeroMediaIdentifier).toNot(beNil())
        expect(footer.firstChildLeadsToHero(root.bodyHeroMediaIdentifier)).to(beFalse())
    }

    @MainActor
    func testFallbackHeaderBeforeHeroDoesNotHideTheHero() throws {
        let zStack = PaywallComponent.StackComponent(
            components: [
                .fallbackHeader,
                .image(Self.fullWidthImageComponent()),
                .text(.init(text: "text_lid", color: Self.black))
            ],
            dimension: .zlayer(.top)
        )

        let root = try Self.makeRootViewModel(stack: .init(components: [.stack(zStack)]))

        let zStackViewModel = try XCTUnwrap(Self.stackViewModel(root.stackViewModel.viewModels.first))
        expect(root.firstItemIsFullWidthMedia).to(beTrue())
        expect(zStackViewModel.firstChildLeadsToHero(root.bodyHeroMediaIdentifier)).to(beTrue())
    }

    @MainActor
    func testHeaderImageHeroIsPushedOnlyForImages() throws {
        func headerZStack(_ media: PaywallComponent) -> PaywallComponent.StackComponent {
            .init(
                components: [media, .text(.init(text: "text_lid", color: Self.black))],
                dimension: .zlayer(.top)
            )
        }
        let body = PaywallComponent.StackComponent(components: [
            .text(.init(text: "text_lid", color: Self.black))
        ])

        let image = try Self.makeRootViewModel(
            stack: body, header: headerZStack(.image(Self.fullWidthImageComponent()))
        )
        let imageHeader = try XCTUnwrap(image.headerViewModel)
        expect(imageHeader.heroMediaIdentifier).toNot(beNil())
        expect(imageHeader.stackViewModel.firstChildLeadsToHero(imageHeader.heroMediaIdentifier)).to(beTrue())

        let webView = try Self.makeRootViewModel(
            stack: body, header: headerZStack(.webView(Self.webViewComponent(width: .fill)))
        )
        let webViewHeader = try XCTUnwrap(webView.headerViewModel)
        expect(webViewHeader.heroMediaIdentifier).to(beNil())
        expect(webViewHeader.stackViewModel.firstChildLeadsToHero(webViewHeader.heroMediaIdentifier)).to(beFalse())
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

    private static func fullWidthImageComponent() -> PaywallComponent.ImageComponent {
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
    }

    @MainActor
    private static func makeRootViewModel(
        stack: PaywallComponent.StackComponent,
        header: PaywallComponent.StackComponent? = nil,
        stickyFooter: PaywallComponent.StackComponent? = nil
    ) throws -> RootViewModel {
        var factory = ViewModelFactory()
        return try factory.toRootViewModel(
            componentsConfig: .init(
                stack: stack,
                header: header.map { .init(stack: $0) },
                stickyFooter: stickyFooter.map { .init(stack: $0) },
                background: .color(.init(light: .hex("#FFFFFF")))
            ),
            offering: Self.mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [
                "text_lid": .string("Hello")
            ]),
            uiConfigProvider: try Self.createUIConfigProvider(),
            colorScheme: .light
        )
    }

    private static func stackViewModel(_ viewModel: PaywallComponentViewModel?) -> StackComponentViewModel? {
        guard case let .stack(stackViewModel) = viewModel else { return nil }
        return stackViewModel
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
