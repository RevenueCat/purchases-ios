//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ViewModelFactoryBadgeTests.swift
//
//  Created by Facundo Menzella on 2/16/26.

import Nimble
@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class ViewModelFactoryBadgeTests: TestCase {

    // MARK: - Badge Source Selection Tests

    /// When a badge only exists in an override (e.g., "selected" state),
    /// badgeViewModels should be populated from the override's badge components.
    @MainActor
    func testBadgeOnlyInSelectedOverride_UsesBadgeFromOverride() throws {
        // Given: A stack component with no base badge, but a badge in "selected" override
        let badgeStack = PaywallComponent.StackComponent(
            components: [
                .text(PaywallComponent.TextComponent(
                    text: "badge_text_lid",
                    color: Self.black
                ))
            ],
            dimension: .horizontal(.center, .center)
        )
        let badge = PaywallComponent.Badge(
            style: .overlaid,
            alignment: .topTrailing,
            stack: badgeStack
        )

        let stackComponent = PaywallComponent.StackComponent(
            components: [],
            badge: nil, // No base badge
            overrides: [
                .init(conditions: [.selected], properties: .init(badge: badge))
            ]
        )

        // When: Creating StackComponentViewModel
        let viewModel = try makeStackViewModel(component: stackComponent)

        // Then: badgeViewModels should NOT be empty (should use override's badge)
        expect(viewModel.badgeViewModels).toNot(beEmpty())
        expect(viewModel.badgeViewModels.count).to(equal(1))
    }

    /// When a badge exists in the base component, badgeViewModels should use it.
    @MainActor
    func testBadgeInBaseComponent_UsesBaseBadge() throws {
        // Given: A stack component with a base badge
        let badgeStack = PaywallComponent.StackComponent(
            components: [
                .text(PaywallComponent.TextComponent(
                    text: "base_badge_lid",
                    color: Self.black
                ))
            ],
            dimension: .horizontal(.center, .center)
        )
        let badge = PaywallComponent.Badge(
            style: .overlaid,
            alignment: .topLeading,
            stack: badgeStack
        )

        let stackComponent = PaywallComponent.StackComponent(
            components: [],
            badge: badge // Base badge present
        )

        // When: Creating StackComponentViewModel
        let viewModel = try makeStackViewModel(component: stackComponent)

        // Then: badgeViewModels should have the base badge's content
        expect(viewModel.badgeViewModels).toNot(beEmpty())
        expect(viewModel.badgeViewModels.count).to(equal(1))
    }

    /// When no badge exists anywhere, badgeViewModels should be empty.
    @MainActor
    func testNoBadgeAnywhere_BadgeViewModelsEmpty() throws {
        // Given: A stack with no badge anywhere
        let stackComponent = PaywallComponent.StackComponent(
            components: [],
            badge: nil,
            overrides: nil
        )

        // When: Creating StackComponentViewModel
        let viewModel = try makeStackViewModel(component: stackComponent)

        // Then: badgeViewModels should be empty
        expect(viewModel.badgeViewModels).to(beEmpty())
    }

    /// When multiple overrides have badges, the first one should be used.
    @MainActor
    func testMultipleOverridesWithBadges_UsesFirstOne() throws {
        // Given: Multiple overrides with badges
        let firstBadgeStack = PaywallComponent.StackComponent(
            components: [
                .text(PaywallComponent.TextComponent(
                    text: "first_badge_lid",
                    color: Self.black
                ))
            ],
            dimension: .horizontal(.center, .center)
        )
        let secondBadgeStack = PaywallComponent.StackComponent(
            components: [
                .text(PaywallComponent.TextComponent(
                    text: "second_badge_lid_1",
                    color: Self.black
                )),
                .text(PaywallComponent.TextComponent(
                    text: "second_badge_lid_2",
                    color: Self.black
                ))
            ],
            dimension: .horizontal(.center, .center)
        )

        let stackComponent = PaywallComponent.StackComponent(
            components: [],
            badge: nil,
            overrides: [
                .init(conditions: [.selected], properties: .init(
                    badge: PaywallComponent.Badge(
                        style: .overlaid,
                        alignment: .topLeading,
                        stack: firstBadgeStack
                    )
                )),
                .init(conditions: [.introOffer], properties: .init(
                    badge: PaywallComponent.Badge(
                        style: .nested,
                        alignment: .bottomTrailing,
                        stack: secondBadgeStack
                    )
                ))
            ]
        )

        // When: Creating StackComponentViewModel
        let viewModel = try makeStackViewModel(component: stackComponent)

        // Then: Should use first override's badge (1 component, not 2)
        expect(viewModel.badgeViewModels.count).to(equal(1))
    }

    /// When base badge is nil but override has badge, and override also has other properties,
    /// the badge should still be picked up.
    @MainActor
    func testBadgeInOverrideWithOtherProperties_UsesBadgeFromOverride() throws {
        // Given: An override with badge and other properties
        let badgeStack = PaywallComponent.StackComponent(
            components: [
                .text(PaywallComponent.TextComponent(
                    text: "badge_text_lid",
                    color: Self.black
                ))
            ],
            dimension: .horizontal(.center, .center)
        )
        let badge = PaywallComponent.Badge(
            style: .overlaid,
            alignment: .topTrailing,
            stack: badgeStack
        )

        let stackComponent = PaywallComponent.StackComponent(
            components: [],
            badge: nil,
            overrides: [
                .init(conditions: [.selected], properties: .init(
                    spacing: 10,
                    padding: .init(top: 5, bottom: 5, leading: 5, trailing: 5),
                    badge: badge
                ))
            ]
        )

        // When: Creating StackComponentViewModel
        let viewModel = try makeStackViewModel(component: stackComponent)

        // Then: badgeViewModels should be populated
        expect(viewModel.badgeViewModels).toNot(beEmpty())
    }

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
                firstItemIgnoresSafeAreaInfo: nil,
                purchaseButtonCollector: nil,
                offering: Self.mockOffering,
                localizationProvider: .init(locale: .current, localizedStrings: [:]),
                uiConfigProvider: try Self.createUIConfigProvider(),
                colorScheme: .light
            )
        }.toNot(throwError())
    }

    // MARK: - Global discardRules Tests (Cross-Component Unsupported Condition Propagation)

    @MainActor
    func testGlobalUnsupported_DiscardsRulesFromComponentWithoutUnsupported() throws {
        // Component A (text): has an unsupported condition
        let textWithUnsupported = PaywallComponent.TextComponent(
            text: "badge_text_lid",
            color: Self.black,
            overrides: [
                .init(extendedConditions: [.unsupported], properties: .init())
            ]
        )

        // Component B (text): has only a rule condition (no unsupported locally)
        let textWithRule = PaywallComponent.TextComponent(
            text: "badge_text_lid",
            color: Self.black,
            overrides: [
                .init(extendedConditions: [
                    .selectedPackage(operator: .in, packages: ["monthly"])
                ], properties: .init(fontWeight: .bold))
            ]
        )

        // Root stack contains both
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

        // The factory should have detected unsupported conditions globally
        expect(factory.discardRules).to(beTrue())

        // Component B's rule override should have been discarded globally
        // We verify by checking the root's child view models
        let stackVM = root.stackViewModel
        expect(stackVM.viewModels.count).to(equal(2))
    }

    @MainActor
    func testGlobalUnsupported_InStickyFooter_DiscardsRulesFromMainStack() throws {
        // Main stack text: has only a rule condition (no unsupported locally)
        let textWithRule = PaywallComponent.TextComponent(
            text: "badge_text_lid",
            color: Self.black,
            overrides: [
                .init(extendedConditions: [
                    .variable(operator: .equals, variable: "plan", value: .string("pro"))
                ], properties: .init(fontWeight: .bold))
            ]
        )

        let rootStack = PaywallComponent.StackComponent(
            components: [.text(textWithRule)]
        )

        // Sticky footer: has unsupported condition
        let footerText = PaywallComponent.TextComponent(
            text: "badge_text_lid",
            color: Self.black,
            overrides: [
                .init(extendedConditions: [.unsupported], properties: .init())
            ]
        )
        let footerStack = PaywallComponent.StackComponent(
            components: [.text(footerText)]
        )
        let stickyFooter = PaywallComponent.StickyFooterComponent(
            stack: footerStack
        )

        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: rootStack,
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

        // Unsupported in sticky footer should trigger global discard
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

        let rootStack = PaywallComponent.StackComponent(
            components: [.text(textWithRule)]
        )

        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: rootStack,
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
        // Root stack text: has only a rule condition (no unsupported locally)
        let textWithRule = PaywallComponent.TextComponent(
            text: "badge_text_lid",
            color: Self.black,
            overrides: [
                .init(extendedConditions: [
                    .selectedPackage(operator: .in, packages: ["monthly"])
                ], properties: .init(fontWeight: .bold))
            ]
        )

        // Button with sheet destination containing unsupported condition
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

        let rootStack = PaywallComponent.StackComponent(
            components: [.text(textWithRule), .button(button)]
        )

        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: rootStack,
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

        // Unsupported in button sheet should trigger global discard
        expect(factory.discardRules).to(beTrue())
    }

    @MainActor
    func testGlobalUnsupported_InNestedTabsComponent_DiscardsRulesFromSibling() throws {
        // Sibling text: has only a rule condition (no unsupported locally)
        let textWithRule = PaywallComponent.TextComponent(
            text: "badge_text_lid",
            color: Self.black,
            overrides: [
                .init(extendedConditions: [
                    .variable(operator: .equals, variable: "tier", value: .string("pro"))
                ], properties: .init(fontWeight: .bold))
            ]
        )

        // Tabs component: tab contains unsupported condition in its stack
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

        let rootStack = PaywallComponent.StackComponent(
            components: [.text(textWithRule), .tabs(tabs)]
        )

        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: rootStack,
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

        // Unsupported in tabs subtree should trigger global discard
        expect(factory.discardRules).to(beTrue())
    }

    // MARK: - Layout Tests (spec task 4.3)

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

    @MainActor
    private func makeStackViewModel(
        component: PaywallComponent.StackComponent
    ) throws -> StackComponentViewModel {
        let localizations: PaywallComponent.LocalizationDictionary = [
            "badge_text_lid": .string("Badge Text"),
            "base_badge_lid": .string("Base Badge"),
            "first_badge_lid": .string("First"),
            "second_badge_lid_1": .string("Second 1"),
            "second_badge_lid_2": .string("Second 2")
        ]

        let factory = ViewModelFactory()
        return try factory.toStackViewModel(
            component: component,
            packageValidator: factory.packageValidator,
            firstItemIgnoresSafeAreaInfo: nil,
            purchaseButtonCollector: nil,
            localizationProvider: LocalizationProvider(
                locale: .current,
                localizedStrings: localizations
            ),
            uiConfigProvider: try Self.createUIConfigProvider(),
            offering: Self.mockOffering,
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
