//
//  SamplePaywallsList.swift
//  PaywallsPreview
//
//  Created by Nacho Soto on 7/27/23.
//



import RevenueCat
import RevenueCatUI
import SwiftUI

struct SamplePaywallsList: View {

    #if os(iOS)
    @State
    private var display: Display?
    #endif

    @State
    private var presentingCustomerCenterSheet: Bool = false

    @State
    private var presentingCustomerCenterFullScreen: Bool = false

    var body: some View {
        NavigationView {
            self.list
                .navigationTitle("Examples")
        }
        #if os(iOS)
        .sheet(item: self.$display) { display in
            self.view(for: display)
        }
        #endif
        .navigationTitle("Paywalls")
        .navigationViewStyle(StackNavigationViewStyle())
    }

    #if os(iOS)
    @ViewBuilder
    private func view(for display: Display) -> some View {
        switch display {
        case .customerCenterSheet,
                .customerCenterFullScreen,
                .customerCenterNavigationView:
            // handled by view modifier
            EmptyView()
        case .uiKitCustomerCenter:
            CustomerCenterUIKitView(
                customerCenterActionHandler: self.handleCustomerCenterAction
            )
        }
    }
    #endif

    private var list: some View {
        List {
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

    @available(watchOS, unavailable)
    enum Display {
        case customerCenterSheet
        case customerCenterFullScreen
        case customerCenterNavigationView
        case uiKitCustomerCenter

    }

}

@available(watchOS, unavailable)
extension SamplePaywallsList.Display: Identifiable {

    public var id: String {
        switch self {
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

struct SamplePaywallsList_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SamplePaywallsList()
        }
    }
}

