//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabsComponentView.swift
//
//  Created by Josh Holtz on 1/9/25.
// swiftlint:disable file_length

import Foundation
import RevenueCat
import SwiftUI

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TabControlContext: ObservableObject {

    @Published
    var selectedIndex: Int = 0

    let controlStackViewModel: StackComponentViewModel
    let tabControlStackViewModels: [StackComponentViewModel]

    init(controlStackViewModel: StackComponentViewModel,
         tabControlStackViewModels: [StackComponentViewModel]) {
        self.controlStackViewModel = controlStackViewModel
        self.tabControlStackViewModels = tabControlStackViewModels
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TabsComponentView: View {

    @EnvironmentObject
    private var packageContext: PackageContext

    private let viewModel: TabsComponentViewModel
    private let onDismiss: () -> Void

    init(viewModel: TabsComponentViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        LoadedTabsComponentView(
            viewModel: self.viewModel,
            parentPackageContext: self.packageContext,
            onDismiss: self.onDismiss
        )
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct LoadedTabsComponentView: View {

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @EnvironmentObject
    private var packageContext: PackageContext

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition

    private let viewModel: TabsComponentViewModel
    private let onDismiss: () -> Void

    @StateObject
    private var tabControlContext: TabControlContext

    @State
    private var tierPackageContexts: [PackageContext]

    var activeTabViewModel: TabViewModel {
        return self.viewModel.tabViewModels[self.tabControlContext.selectedIndex]
    }

    init(viewModel: TabsComponentViewModel,
         parentPackageContext: PackageContext,
         onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss

        self._tabControlContext = .init(wrappedValue: TabControlContext(
            controlStackViewModel: viewModel.controlStackViewModel,
            tabControlStackViewModels: viewModel.tabViewModels.map({ tabViewModel in
                tabViewModel.stackViewModel
            })
        ))

        let variableContext = parentPackageContext.variableContext
        self._tierPackageContexts = .init(initialValue: viewModel.tabViewModels.map({ tvm in
            return .init(
                package: tvm.defaultSelectedPackage,
                variableContext: .init(
                    packages: tvm.packages,
                    showZeroDecimalPlacePrices: variableContext.showZeroDecimalPlacePrices
                )
            )
        }))
    }

    var body: some View {
        self.viewModel.styles(
            state: self.componentViewState,
            condition: self.screenCondition,
            isEligibleForIntroOffer: self.introOfferEligibilityContext.isEligible(
                package: self.packageContext.package
            )
        ) { style in
            if style.visible {
                LoadedTabComponentView(
                    stackViewModel: self.activeTabViewModel.stackViewModel,
                    onChange: { context in
                        self.packageContext.update(
                            package: context.package,
                            variableContext: context.variableContext
                        )
                    },
                    onDismiss: self.onDismiss
                )
                .environmentObject(self.tabControlContext)
                .environmentObject(self.tierPackageContexts[self.tabControlContext.selectedIndex])
            }
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct LoadedTabComponentView: View {

    @EnvironmentObject
    private var tabPackageContext: PackageContext

    private let stackViewModel: StackComponentViewModel
    private let onChange: (PackageContext) -> Void
    private let onDismiss: () -> Void

    init(stackViewModel: StackComponentViewModel,
         onChange: @escaping (PackageContext) -> Void,
         onDismiss: @escaping () -> Void) {
        self.stackViewModel = stackViewModel
        self.onChange = onChange
        self.onDismiss = onDismiss
    }

    var body: some View {
        StackComponentView(
            viewModel: self.stackViewModel,
            onDismiss: self.onDismiss
        )
        .environmentObject(self.tabPackageContext)
        // Comparing on tabPackageContext.package but sending tabPackageContext to parent
        .onChangeOf(self.tabPackageContext.package) { _ in
            self.onChange(self.tabPackageContext)
        }
    }

}

#if DEBUG

// swiftlint:disable type_body_length
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TabsComponentView_Previews: PreviewProvider {

    static let segmentTabs = PaywallComponent.tabs(
        .init(
            control: .init(
                type: .buttons,
                stack: .init(
                    components: [
                        // Tab 1
                        .tabControlButton(
                            .init(
                                tabIndex: 0,
                                stack: .init(
                                    components: [
                                        .text(.init(
                                            text: "tab_1_button",
                                            color: .init(light: .hex("#000000")),
                                            size: .init(width: .fit, height: .fit),
                                            overrides: [
                                                .init(conditions: [
                                                    .selected
                                                ], properties: .init(
                                                    color: .init(light: .hex("#ffffff"))
                                                ))
                                            ]
                                        ))
                                    ],
                                    size: .init(width: .fit, height: .fit),
                                    padding: .init(top: 4, bottom: 4, leading: 16, trailing: 16),
                                    shape: .pill,
                                    overrides: [
                                        .init(conditions: [
                                            .selected
                                        ], properties: .init(
                                            backgroundColor: .init(light: .hex("#3d6787"))
                                        ))
                                    ]
                                )
                            )
                        ),
                        // Divider
                        .stack(.init(
                            components: [],
                            size: .init(width: .fixed(2), height: .fixed(20)),
                            backgroundColor: .init(light: .hex("#8d8d8d"))
                        )),
                        // Tab 2
                        .tabControlButton(
                            .init(
                                tabIndex: 1,
                                stack: .init(
                                    components: [
                                        .text(.init(
                                            text: "tab_2_button",
                                            color: .init(light: .hex("#000000")),
                                            size: .init(width: .fit, height: .fit),
                                            overrides: [
                                                .init(conditions: [
                                                    .selected
                                                ], properties: .init(
                                                    color: .init(light: .hex("#ffffff"))
                                                ))
                                            ]
                                        ))
                                    ],
                                    size: .init(width: .fit, height: .fit),
                                    padding: .init(top: 4, bottom: 4, leading: 16, trailing: 16),
                                    shape: .pill,
                                    overrides: [
                                        .init(conditions: [
                                            .selected
                                        ], properties: .init(
                                            backgroundColor: .init(light: .hex("#3d6787"))
                                        ))
                                    ]
                                )
                            )
                        ),
                        // Divider
                        .stack(.init(
                            components: [],
                            size: .init(width: .fixed(2), height: .fixed(20)),
                            backgroundColor: .init(light: .hex("#8d8d8d"))
                        )),
                        // Tab 3
                        .tabControlButton(
                            .init(
                                tabIndex: 2,
                                stack: .init(
                                    components: [
                                        .text(.init(
                                            text: "tab_3_button",
                                            color: .init(light: .hex("#000000")),
                                            size: .init(width: .fit, height: .fit),
                                            overrides: [
                                                .init(conditions: [
                                                    .selected
                                                ], properties: .init(
                                                    color: .init(light: .hex("#ffffff"))
                                                ))
                                            ]
                                        ))
                                    ],
                                    size: .init(width: .fit, height: .fit),
                                    padding: .init(top: 4, bottom: 4, leading: 16, trailing: 16),
                                    shape: .pill,
                                    overrides: [
                                        .init(conditions: [
                                            .selected
                                        ], properties: .init(
                                            backgroundColor: .init(light: .hex("#3d6787"))
                                        ))
                                    ]
                                )
                            )
                        )
                    ],
                    dimension: .horizontal(.center, .start),
                    size: .init(width: .fit, height: .fit),
                    backgroundColor: .init(light: .hex("#dedede")),
                    padding: .init(top: 3, bottom: 3, leading: 3, trailing: 3),
                    shape: .pill
                )
            ),
            tabs: [
                // Tab 1
                .init(stack: .init(
                    components: [
                        .text(.init(
                            text: "tab_1_text_1",
                            color: .init(light: .hex("#000000")),
                            size: .init(width: .fit, height: .fit)
                        )),
                        .tabControl(.init()),
                        .text(.init(
                            text: "tab_1_text_2",
                            color: .init(light: .hex("#000000")),
                            size: .init(width: .fit, height: .fit)
                        ))
                    ]
                )),
                // Tab 2
                .init(stack: .init(
                    components: [
                        .text(.init(
                            text: "tab_2_text_1",
                            color: .init(light: .hex("#000000")),
                            size: .init(width: .fit, height: .fit)
                        )),
                        .tabControl(.init()),
                        .text(.init(
                            text: "tab_2_text_2",
                            color: .init(light: .hex("#000000")),
                            size: .init(width: .fit, height: .fit)
                        ))
                    ]
                )),
                // Tab 3
                .init(stack: .init(
                    components: [
                        .text(.init(
                            text: "tab_3_text_1",
                            color: .init(light: .hex("#000000")),
                            size: .init(width: .fit, height: .fit)
                        )),
                        .tabControl(.init()),
                        .text(.init(
                            text: "tab_3_text_2",
                            color: .init(light: .hex("#000000")),
                            size: .init(width: .fit, height: .fit)
                        ))
                    ]
                ))
            ]
        )
    )

    static let buttonTabs = PaywallComponent.tabs(
        .init(
            control: .init(
                type: .buttons,
                stack: .init(
                    components: [
                        // Tab 1
                        .tabControlButton(
                            .init(
                                tabIndex: 0,
                                stack: .init(
                                    components: [
                                        .text(.init(
                                            text: "tab_1_button",
                                            color: .init(light: .hex("#000000")),
                                            size: .init(width: .fit, height: .fit),
                                            overrides: [
                                                .init(conditions: [
                                                    .selected
                                                ], properties: .init(
                                                    color: .init(light: .hex("#ffffff"))
                                                ))
                                            ]
                                        ))
                                    ],
                                    size: .init(width: .fit, height: .fit),
                                    padding: .init(top: 4, bottom: 4, leading: 16, trailing: 16),
                                    shape: .rectangle(.init(topLeading: 8,
                                                            topTrailing: 8,
                                                            bottomLeading: 8,
                                                            bottomTrailing: 8)),
                                    overrides: [
                                        .init(conditions: [
                                            .selected
                                        ], properties: .init(
                                            backgroundColor: .init(light: .hex("#3d6787"))
                                        ))
                                    ]
                                )
                            )
                        ),
                        // Tab 2
                        .tabControlButton(
                            .init(
                                tabIndex: 1,
                                stack: .init(
                                    components: [
                                        .text(.init(
                                            text: "tab_2_button",
                                            color: .init(light: .hex("#000000")),
                                            size: .init(width: .fit, height: .fit),
                                            overrides: [
                                                .init(conditions: [
                                                    .selected
                                                ], properties: .init(
                                                    color: .init(light: .hex("#ffffff"))
                                                ))
                                            ]
                                        ))
                                    ],
                                    size: .init(width: .fit, height: .fit),
                                    padding: .init(top: 4, bottom: 4, leading: 16, trailing: 16),
                                    shape: .rectangle(.init(topLeading: 8,
                                                            topTrailing: 8,
                                                            bottomLeading: 8,
                                                            bottomTrailing: 8)),
                                    overrides: [
                                        .init(conditions: [
                                            .selected
                                        ], properties: .init(
                                            backgroundColor: .init(light: .hex("#3d6787"))
                                        ))
                                    ]
                                )
                            )
                        ),
                        // Tab 3
                        .tabControlButton(
                            .init(
                                tabIndex: 2,
                                stack: .init(
                                    components: [
                                        .text(.init(
                                            text: "tab_3_button",
                                            color: .init(light: .hex("#000000")),
                                            size: .init(width: .fit, height: .fit),
                                            overrides: [
                                                .init(conditions: [
                                                    .selected
                                                ], properties: .init(
                                                    color: .init(light: .hex("#ffffff"))
                                                ))
                                            ]
                                        ))
                                    ],
                                    size: .init(width: .fit, height: .fit),
                                    padding: .init(top: 4, bottom: 4, leading: 16, trailing: 16),
                                    shape: .rectangle(.init(topLeading: 8,
                                                            topTrailing: 8,
                                                            bottomLeading: 8,
                                                            bottomTrailing: 8)),
                                    overrides: [
                                        .init(conditions: [
                                            .selected
                                        ], properties: .init(
                                            backgroundColor: .init(light: .hex("#3d6787"))
                                        ))
                                    ]
                                )
                            )
                        )
                    ],
                    dimension: .horizontal(.center, .start),
                    size: .init(width: .fit, height: .fit)
                )
            ),
            tabs: [
                // Tab 1
                .init(stack: .init(
                    components: [
                        .text(.init(
                            text: "tab_1_text_1",
                            color: .init(light: .hex("#000000")),
                            size: .init(width: .fit, height: .fit)
                        )),
                        .tabControl(.init()),
                        .text(.init(
                            text: "tab_1_text_2",
                            color: .init(light: .hex("#000000")),
                            size: .init(width: .fit, height: .fit)
                        ))
                    ]
                )),
                // Tab 2
                .init(stack: .init(
                    components: [
                        .text(.init(
                            text: "tab_2_text_1",
                            color: .init(light: .hex("#000000")),
                            size: .init(width: .fit, height: .fit)
                        )),
                        .tabControl(.init()),
                        .text(.init(
                            text: "tab_2_text_2",
                            color: .init(light: .hex("#000000")),
                            size: .init(width: .fit, height: .fit)
                        ))
                    ]
                )),
                // Tab 3
                .init(stack: .init(
                    components: [
                        .text(.init(
                            text: "tab_3_text_1",
                            color: .init(light: .hex("#000000")),
                            size: .init(width: .fit, height: .fit)
                        )),
                        .tabControl(.init()),
                        .text(.init(
                            text: "tab_3_text_2",
                            color: .init(light: .hex("#000000")),
                            size: .init(width: .fit, height: .fit)
                        ))
                    ]
                ))
            ]
        )
    )

    static let toggleTabs = PaywallComponent.tabs(
        .init(
            control: .init(
                type: .toggle,
                stack: .init(
                    components: [
                        .text(.init(
                            text: "tab_toggle",
                            color: .init(light: .hex("#000000")),
                            size: .init(width: .fit, height: .fit)
                        )),
                        .tabControlToggle(.init(
                            defaultValue: false,
                            thumbColorOn: .init(light: .hex("#3d6787")),
                            thumbColorOff: .init(light: .hex("#ffffff")),
                            trackColorOn: .init(light: .hex("#cecece")),
                            trackColorOff: .init(light: .hex("#cecece"))
                        ))
                    ],
                    dimension: .horizontal(.center, .start),
                    size: .init(width: .fit, height: .fit)
                )
            ),
            tabs: [
                // Tab 1
                .init(stack: .init(
                    components: [
                        .text(.init(
                            text: "tab_1_text_1",
                            color: .init(light: .hex("#000000")),
                            size: .init(width: .fit, height: .fit)
                        )),
                        .tabControl(.init()),
                        .text(.init(
                            text: "tab_1_text_2",
                            color: .init(light: .hex("#000000")),
                            size: .init(width: .fit, height: .fit)
                        ))
                    ]
                )),
                // Tab 2
                .init(stack: .init(
                    components: [
                        .text(.init(
                            text: "tab_2_text_1",
                            color: .init(light: .hex("#000000")),
                            size: .init(width: .fit, height: .fit)
                        )),
                        .tabControl(.init()),
                        .text(.init(
                            text: "tab_2_text_2",
                            color: .init(light: .hex("#000000")),
                            size: .init(width: .fit, height: .fit)
                        ))
                    ]
                )),
                // Tab 3
                .init(stack: .init(
                    components: [
                        .text(.init(
                            text: "tab_3_text_1",
                            color: .init(light: .hex("#000000")),
                            size: .init(width: .fit, height: .fit)
                        )),
                        .tabControl(.init()),
                        .text(.init(
                            text: "tab_3_text_2",
                            color: .init(light: .hex("#000000")),
                            size: .init(width: .fit, height: .fit)
                        ))
                    ]
                ))
            ]
        )
    )

    static var previews: some View {
        // Segment Tabs
        StackComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! StackComponentViewModel(
                component: .init(
                    components: [
                        segmentTabs
                    ],
                    dimension: .vertical(.center, .start),
                    size: .init(
                        width: .fill,
                        height: .fill
                    ),
                    backgroundColor: .init(light: .hex("#ffffff"))
                ),
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "tab_1_button": .string("Tab 1"),
                        "tab_1_text_1": .string("1 Content above control"),
                        "tab_1_text_2": .string("1 Content below control"),
                        "tab_2_button": .string("Tab 2"),
                        "tab_2_text_1": .string("2 Content above control"),
                        "tab_2_text_2": .string("2 Content below control"),
                        "tab_3_button": .string("Tab 3"),
                        "tab_3_text_1": .string("3 Content above control"),
                        "tab_3_text_2": .string("3 Content below control")
                    ]
                )
            ),
            onDismiss: {}
        )
        .previewRequiredEnvironmentProperties()
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Segment Tabs")

        // Button Tabs
        StackComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! StackComponentViewModel(
                component: .init(
                    components: [
                        buttonTabs
                    ],
                    dimension: .vertical(.center, .start),
                    size: .init(
                        width: .fill,
                        height: .fill
                    ),
                    backgroundColor: .init(light: .hex("#ffffff"))
                ),
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "tab_1_button": .string("Tab 1"),
                        "tab_1_text_1": .string("1 Content above control"),
                        "tab_1_text_2": .string("1 Content below control"),
                        "tab_2_button": .string("Tab 2"),
                        "tab_2_text_1": .string("2 Content above control"),
                        "tab_2_text_2": .string("2 Content below control"),
                        "tab_3_button": .string("Tab 3"),
                        "tab_3_text_1": .string("3 Content above control"),
                        "tab_3_text_2": .string("3 Content below control")
                    ]
                )
            ),
            onDismiss: {}
        )
        .previewRequiredEnvironmentProperties()
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Button Tabs")

        // Toggle Tabs
        StackComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! StackComponentViewModel(
                component: .init(
                    components: [
                        toggleTabs
                    ],
                    dimension: .vertical(.center, .start),
                    size: .init(
                        width: .fill,
                        height: .fill
                    ),
                    backgroundColor: .init(light: .hex("#ffffff"))
                ),
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "tab_1_button": .string("Tab 1"),
                        "tab_1_text_1": .string("1 Content above control"),
                        "tab_1_text_2": .string("1 Content below control"),
                        "tab_2_button": .string("Tab 2"),
                        "tab_2_text_1": .string("2 Content above control"),
                        "tab_2_text_2": .string("2 Content below control"),
                        "tab_3_button": .string("Tab 3"),
                        "tab_3_text_1": .string("3 Content above control"),
                        "tab_3_text_2": .string("3 Content below control"),
                        "tab_toggle": .string("Free trial?")
                    ]
                )
            ),
            onDismiss: {}
        )
        .previewRequiredEnvironmentProperties()
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Toggle Tabs")
    }
}

#endif

#endif
