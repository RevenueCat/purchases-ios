//
//  SamplePaywallsList.swift
//  PaywallsPreview
//
//  Created by Nacho Soto on 7/27/23.
//



import RevenueCat
#if DEBUG
@_spi(Internal) @testable import RevenueCatUI
#else
@_spi(Internal) import RevenueCatUI
#endif

import SwiftUI

struct SamplePaywallsList: View {

    @State
    private var display: Display?

    @State
    private var presentingCustomerCenterSheet: Bool = false

    @State
    private var presentingCustomerCenterFullScreen: Bool = false

    var body: some View {
        NavigationView {
            self.list
                .navigationTitle("Examples")
        }
        .sheet(item: self.$display) { display in
            self.view(for: display)
        }
        .navigationTitle("Paywalls")
        .navigationViewStyle(.automatic)
    }

    @ViewBuilder
    private func view(for display: Display) -> some View {
        switch display {
        #if DEBUG
        case let .template(template, mode):
            switch mode {
            case .fullScreen, .sheet:
                PaywallView(configuration: .init(
                    offering: Self.loader.offering(for: template),
                    customerInfo: Self.loader.customerInfo,
                    displayCloseButton: Self.displayCloseButton,
                    introEligibility: Self.introEligibility
                ))
            case .presentIfNeeded:
                fatalError()

            case .presentPaywall:
                fatalError()

            #if !os(watchOS) && !os(macOS)
            case .footer, .condensedFooter:
                CustomPaywall(offering: Self.loader.offering(for: template),
                              customerInfo: Self.loader.customerInfo,
                              condensed: mode == .condensedFooter,
                              introEligibility: Self.introEligibility)
            #endif
            }

        case let .customFont(template):
            PaywallView(
                configuration: .init(
                    offering: Self.loader.offering(for: template),
                    customerInfo: Self.loader.customerInfo,
                    fonts: Self.customFontProvider,
                    displayCloseButton: Self.displayCloseButton,
                    introEligibility: Self.introEligibility
                )
            )

        #if os(iOS)
        case let .customPaywall(mode):
            CustomPaywall(customerInfo: Self.loader.customerInfo,
                          condensed: mode == .condensedFooter)
        #endif

        case .missingPaywall:
            PaywallView(
                configuration: .init(
                    offering: Self.loader.offeringWithDefaultPaywall(),
                    customerInfo: Self.loader.customerInfo,
                    introEligibility: Self.introEligibility
                )
            )

        case .unrecognizedPaywall:
            PaywallView(
                configuration: .init(
                    offering: Self.loader.offeringWithUnrecognizedPaywall(),
                    customerInfo: Self.loader.customerInfo,
                    introEligibility: Self.introEligibility
                )
            )

        case .componentPaywall(let data):
            PaywallView(configuration: .init(
                offering: Self.loader.offering(with: data),
                customerInfo: Self.loader.customerInfo,
                displayCloseButton: Self.displayCloseButton,
                introEligibility: Self.introEligibility
            ))

        #if os(iOS)
        case .nestedPaywallsPrototype:
            NestedPaywallsPrototypeView(
                pages: [
                    .init(
                        id: PaywallTemplate.template1.rawValue,
                        title: PaywallTemplate.template1.name,
                        offering: Self.loader.offering(for: .template1)
                    ),
                    .init(
                        id: PaywallTemplate.template3.rawValue,
                        title: PaywallTemplate.template3.name,
                        offering: Self.loader.offering(for: .template3)
                    ),
                    .init(
                        id: PaywallTemplate.template7.rawValue,
                        title: PaywallTemplate.template7.name,
                        offering: Self.loader.offering(for: .template7)
                    )
                ],
                customerInfo: Self.loader.customerInfo,
                introEligibility: Self.introEligibility
            )
        #endif
        #endif
        #if canImport(UIKit) && os(iOS)
        case .customerCenterSheet,
                .customerCenterFullScreen,
                .customerCenterNavigationView:
            // handled by view modifier
            EmptyView()

        case .uiKitCustomerCenter:
            CustomerCenterUIKitView()
        #else
        default:
            EmptyView()
        #endif
        }
    }

    private var list: some View {
        List {
            #if DEBUG
            ForEach(PaywallTemplate.allCases, id: \.rawValue) { template in
                Section(template.name) {
                    ForEach(PaywallTesterViewMode.allCases.filter(\.isAvailableOnExamples), id: \.self) { mode in
                        Button {
                            self.display = .template(template, mode)
                        } label: {
                            TemplateLabel(name: mode.name, icon: mode.icon)
                        }
                    }

                    Button {
                        self.display = .customFont(template)
                    } label: {
                        TemplateLabel(name: "Custom font", icon: "textformat")
                            .font(.body.italic())
                    }
                }
            }

            Section("Other") {
                #if !os(watchOS) && !os(macOS)
                Button {
                    self.display = .customPaywall(.footer)
                } label: {
                    TemplateLabel(name: "Custom + footer",
                                  icon: PaywallTesterViewMode.footer.icon)
                }

                Button {
                    self.display = .customPaywall(.condensedFooter)
                } label: {
                    TemplateLabel(name: "Custom + condensed footer",
                                  icon: PaywallTesterViewMode.condensedFooter.icon)
                }
                #endif

                Button {
                    self.display = .missingPaywall
                } label: {
                    TemplateLabel(name: "Offering with no paywall", icon: "exclamationmark.triangle")
                }

                Button {
                    self.display = .unrecognizedPaywall
                } label: {
                    TemplateLabel(name: "Unrecognized paywall", icon: "exclamationmark.triangle")
                }
            }
            #endif

            #if os(iOS)
            Section("Customer Center") {
                NavigationLink {
                    CustomerCenterView(
                        customerCenterActionHandler: handleCustomerCenterAction,
                        navigationOptions: CustomerCenterNavigationOptions(
                            usesNavigationStack: false,
                            usesExistingNavigation: true,
                            shouldShowCloseButton: false
                        ))
                    .onCustomerCenterPromotionalOfferSucceeded { customerInfo, transaction, offerId in
                        print("CustomerCenter: promotionalOfferSucceeded. " +
                              "OfferId: \(offerId), " +
                              "TransactionId: \(transaction.transactionIdentifier), " +
                              "Entitlements: \(customerInfo.entitlements.active.keys.joined(separator: ", "))")
                    }
                    .onCustomerCenterPromotionalOfferSuccess {
                        print("CustomerCenter: promotionalOfferSuccess (deprecated)")
                    }
                } label: {
                    Text("Pushed in NavigationView")
                }

                Button {
                    self.display = .uiKitCustomerCenter
                } label: {
                    TemplateLabel(name: "UIKit Customer Center", icon: "person.fill.questionmark")
                }

                Button {
                    self.presentingCustomerCenterFullScreen = true
                } label: {
                    TemplateLabel(name: "Fullscreen", icon: "person.fill")
                }

                Button {
                    self.presentingCustomerCenterSheet = true
                } label: {
                    TemplateLabel(name: "Sheet", icon: "person.fill")
                }
            }

            #if DEBUG
            Section("MultiPage POC") {
                Button {
                    self.display = .nestedPaywallsPrototype
                } label: {
                    TemplateLabel(name: "Present", icon: "square.on.square")
                }
            }
            #endif
            #endif

            #if DEBUG && !os(watchOS)
            if #available(iOS 16.0, macOS 13.0, *) {
                Section("Debug") {
                    DebugView()
                }
            }
            #endif
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
        #if os(iOS)
        .presentCustomerCenter(
            isPresented: self.$presentingCustomerCenterSheet,
            managementOptionSelected: { button in
                switch button {
                    case is CustomerCenterManagementOption.Cancel:
                        print("Cancel action triggered")
                    case let customUrl as CustomerCenterManagementOption.CustomUrl:
                        print("Opening URL: \(customUrl.url)")
                case is CustomerCenterManagementOption  .MissingPurchase:
                        print("Missing purchase triggered")
                case is CustomerCenterManagementOption.RefundRequest:
                        print("RefundRequest triggered")
                case is CustomerCenterManagementOption.ChangePlans:
                        print("ChangePlans triggered")
                    default:
                        print("Unknown action")
                 }
            },
            onDismiss: { self.presentingCustomerCenterFullScreen = false }
        )
        .presentCustomerCenter(
            isPresented: self.$presentingCustomerCenterFullScreen,
            customerCenterActionHandler: self.handleCustomerCenterAction,
            presentationMode: .fullScreen,
            onDismiss: { self.presentingCustomerCenterFullScreen = false }
        )
        #endif
    }

    #if os(watchOS)
    private static let customFontProvider = CustomPaywallFontProvider(fontName: "Courier New")
    private static let displayCloseButton = false
    #else
    private static let customFontProvider = CustomPaywallFontProvider(fontName: "Papyrus")
    private static let displayCloseButton = true
    #endif

    #if DEBUG
    private static let loader: SamplePaywallLoader = .init()
    private static let introEligibility: TrialOrIntroEligibilityChecker = .init { packages in
        return Dictionary(
            uniqueKeysWithValues: Set(packages)
                .map { package in
                    let result: IntroEligibilityStatus = package.storeProduct.hasIntroDiscount
                    ? Bool.random() ? .eligible : .ineligible
                    : .noIntroOfferExists

                    return (package, result)
                }
        )
    }
    #endif
}

private struct TemplateLabel: View {

    var name: String
    var icon: String

    var body: some View {
        Label(self.name, systemImage: self.icon)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
    }

}

// MARK: -

#if os(iOS)

extension SamplePaywallsList {

    func handleCustomerCenterAction(action: CustomerCenterAction) {
        switch action {
        case .restoreCompleted(_):
            print("CustomerCenter: restoreCompleted")
        case .restoreStarted:
            print("CustomerCenter: restoreStarted")
        case .restoreFailed(_):
            print("CustomerCenter: restoreFailed")
        case .showingManageSubscriptions:
            print("CustomerCenter: showingManageSubscriptions")
        case .refundRequestStarted(let productId):
            print("CustomerCenter: refundRequestStarted. ProductId: \(productId)")
        case .refundRequestCompleted(let status):
            print("CustomerCenter: refundRequestCompleted. Result: \(status)")
        case .feedbackSurveyCompleted(let surveyOptionID):
            print("CustomerCenter: feedbackSurveyCompleted. Result: \(surveyOptionID)")
        }
    }
}

#endif

private extension SamplePaywallsList {

    enum Display {
        #if DEBUG
        case template(PaywallTemplate, PaywallTesterViewMode)
        case customFont(PaywallTemplate)
        @available(watchOS, unavailable)
        case customPaywall(PaywallViewMode)
        case missingPaywall
        case unrecognizedPaywall
        case componentPaywall(PaywallComponentsData)
        #if os(iOS)
        case nestedPaywallsPrototype
        #endif
        #endif

        @available(watchOS, unavailable)
        case customerCenterSheet
        @available(watchOS, unavailable)
        case customerCenterFullScreen
        @available(watchOS, unavailable)
        case customerCenterNavigationView
        @available(watchOS, unavailable)
        case uiKitCustomerCenter
    }

}

extension SamplePaywallsList.Display: Identifiable {

    public var id: String {
        switch self {
        #if DEBUG
        case let .template(template, mode):
            return "template-\(template.rawValue)-\(mode)"

        case let .customFont(template):
            return "custom-font-" + template.rawValue

        case .customPaywall:
            return "custom-paywall"

        case .missingPaywall:
            return "missing"

        case .unrecognizedPaywall:
            return "unrecognized"

        case .componentPaywall:
            return "component-paywall"

        #if os(iOS)
        case .nestedPaywallsPrototype:
            return "nested-paywalls-prototype"
        #endif

        #endif
        case .customerCenterSheet:
            return "customer-center-sheet"

        case .customerCenterFullScreen:
            return "customer-center-fullscreen"

        case .customerCenterNavigationView:
            return "customer-center-navigationview"

        case .uiKitCustomerCenter:
            return "customer-center-uikit"
        }
    }

}

#if DEBUG
extension PaywallTemplate {

    var name: String {
        switch self {
        case .template1:
            return "1: Minimalist"
        case .template2:
            return "2: Bold packages"
        case .template3:
            return "3: Feature list"
        case .template4:
            return "4: Horizontal packages"
        case .template5:
            return "5: Minimalist with Small Banner"
        case .template7:
            return "7: Multi-tier with Small Banner"
        }
    }

}
#endif

#if DEBUG && os(iOS)

private struct NestedPaywallsPrototypeView: View {

    struct PrototypePage: Identifiable {
        let id: String
        let title: String
        let offering: Offering
    }

    private enum Constants {
        static let sideItemMaxWidth: CGFloat = 128
    }

    private let pages: [PrototypePage]
    private let customerInfo: CustomerInfo
    private let introEligibility: TrialOrIntroEligibilityChecker

    @Environment(\.dismiss)
    private var dismiss

    @StateObject
    private var purchaseHandler: PurchaseHandler

    @State
    private var navigationStack: [PrototypePage.ID]

    @State
    private var transitionIsForward: Bool = true

    @State
    private var leadingItemWidth: CGFloat = 0

    @State
    private var trailingItemWidth: CGFloat = 0

    init(
        pages: [PrototypePage],
        customerInfo: CustomerInfo,
        introEligibility: TrialOrIntroEligibilityChecker
    ) {
        precondition(!pages.isEmpty, "NestedPaywallsPrototypeView requires at least one page")

        self.pages = pages
        self.customerInfo = customerInfo
        self.introEligibility = introEligibility
        self._purchaseHandler = .init(wrappedValue: .default())
        self._navigationStack = .init(initialValue: [pages[0].id])
    }

    var body: some View {
        VStack(spacing: 0) {
            self.navigationBar

            ZStack {
                self.paywallPage(self.currentPage)
                    .id(self.currentPage.id)
                    .transition(self.transition(forward: self.transitionIsForward))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .animation(.easeInOut(duration: 0.25), value: self.navigationStack)
        }
    }

    private var navigationBar: some View {
        ZStack {
            HStack(spacing: 12) {
                self.leadingNavigationItem
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(maxWidth: Constants.sideItemMaxWidth, alignment: .leading)
                    .onWidthChange { width in
                        self.leadingItemWidth = width
                    }

                Spacer(minLength: 0)

                self.trailingNavigationItem
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(maxWidth: Constants.sideItemMaxWidth, alignment: .trailing)
                    .onWidthChange { width in
                        self.trailingItemWidth = width
                    }
            }

            Text(self.currentTitle)
                .font(.system(size: 17, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, self.titleHorizontalInset)
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    @ViewBuilder
    private var leadingNavigationItem: some View {
        if let previousPage = self.previousPage {
            Button {
                self.pop()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                    Text(previousPage.title)
                        .font(.system(size: 17))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        } else {
            Button("Close") {
                self.dismiss()
            }
            .font(.system(size: 17))
            .foregroundStyle(.blue)
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var trailingNavigationItem: some View {
        if let nextPage = self.nextPage {
            Button("Next") {
                self.push(nextPage)
            }
            .font(.system(size: 17))
            .foregroundStyle(.blue)
            .buttonStyle(.plain)
        } else {
            Button("Close") {
                self.dismiss()
            }
            .font(.system(size: 17))
            .foregroundStyle(.blue)
            .buttonStyle(.plain)
        }
    }

    private var currentTitle: String {
        return self.currentPage.title
    }

    private var titleHorizontalInset: CGFloat {
        return max(self.leadingItemWidth, self.trailingItemWidth) + 12
    }

    private var currentPage: PrototypePage {
        return self.page(for: self.navigationStack.last) ?? self.pages[0]
    }

    private var previousPage: PrototypePage? {
        return self.navigationStack.dropLast().last.flatMap(self.page(for:))
    }

    private var nextPage: PrototypePage? {
        guard let currentIndex = self.currentPageIndex else {
            return nil
        }

        let nextIndex = currentIndex + 1
        guard nextIndex < self.pages.count else {
            return nil
        }

        return self.pages[nextIndex]
    }

    private var currentPageIndex: Int? {
        return self.pages.firstIndex(where: { $0.id == self.currentPage.id })
    }

    private func paywallPage(_ page: PrototypePage) -> some View {
        PaywallView(configuration: .init(
            offering: page.offering,
            customerInfo: self.customerInfo,
            mode: .fullScreen,
            displayCloseButton: false,
            introEligibility: self.introEligibility,
            purchaseHandler: self.purchaseHandler
        ))
        .onRequestedDismissal { }
    }

    private func push(_ page: PrototypePage) {
        guard self.navigationStack.last != page.id else {
            return
        }

        self.transitionIsForward = true
        withAnimation(.easeInOut(duration: 0.25)) {
            self.navigationStack.append(page.id)
        }
    }

    private func pop() {
        guard self.navigationStack.count > 1 else {
            return
        }

        self.transitionIsForward = false
        withAnimation(.easeInOut(duration: 0.25)) {
            self.navigationStack.removeLast()
        }
    }

    private func transition(forward: Bool) -> AnyTransition {
        return .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private func page(for id: PrototypePage.ID?) -> PrototypePage? {
        guard let id else {
            return nil
        }

        return self.pages.first(where: { $0.id == id })
    }

}

#endif

struct SamplePaywallsList_Previews: PreviewProvider {
    static var previews: some View {
        SamplePaywallsList()
    }
}
