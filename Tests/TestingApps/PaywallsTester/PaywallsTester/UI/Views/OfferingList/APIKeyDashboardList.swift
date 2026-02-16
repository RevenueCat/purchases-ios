//
//  APIKeyDashboardList.swift
//  SimpleApp
//
//  Created by Nacho Soto on 7/27/23.
//

import RevenueCat
#if DEBUG
@testable import RevenueCatUI
#else
import RevenueCatUI
#endif
import SwiftUI

struct APIKeyDashboardList: View {

    fileprivate struct Template: Hashable {
        var name: String?
    }

    fileprivate struct Data: Hashable {
        var sections: [Template]
        var offeringsBySection: [Template: [Offering]]
    }

    fileprivate struct PresentedPaywall: Hashable {
        var offering: Offering
        var mode: PaywallTesterViewMode
    }

    @State
    private var offerings: Result<Data, NSError>?

    @State
    private var presentedPaywall: PresentedPaywall?

    @State
    private var presentedPaywallCover: PresentedPaywall?
    
    @State
    private var offeringToPresent: Offering?

    @State
    private var presentPaywallOffering: Offering?
    
    @State
    private var isLoadingPaywall: Bool = false

    @State
    private var customVariables: [String: CustomVariableValue] = [:]

    @State
    private var isShowingVariablesEditor = false

    @State
    private var searchText = ""

    var body: some View {
        ZStack {
            NavigationView {
                self.content
                    .navigationTitle("Live Paywalls")
                    #if !os(macOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .automatic) {
                            HStack(spacing: 16) {
                                Button {
                                    isShowingVariablesEditor = true
                                } label: {
                                    Image(systemName: "curlybraces")
                                }

                                Button {
                                    Task {
                                        await fetchOfferings()
                                    }
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                }
                                #if !os(watchOS)
                                .keyboardShortcut("r", modifiers: .shift)
                                #endif
                            }
                        }
                    }
                    .sheet(isPresented: $isShowingVariablesEditor) {
                        CustomVariablesEditorView(variables: $customVariables)
                    }
            }
            .task {
                await fetchOfferings()
            }
            .refreshable {
                await fetchOfferings()
            }
            
            if isLoadingPaywall {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                SwiftUI.ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
    }

    private func fetchOfferings() async {
        do {
            // Force refresh offerings
            _ = try await Purchases.shared.syncAttributesAndOfferingsIfNeeded()

            let offerings = try await Purchases.shared.offerings()
                .all
                .map(\.value)
                .sorted { $0.id < $1.id }

            if let presentedPaywall = presentedPaywall {
                for offering in offerings {
                    if presentedPaywall.offering.id == offering.id {
                        self.presentedPaywall = nil
                        Task {
                            // Need to wait for the paywall sheet to be dismissed before presenting again.
                            // We cannot modify the presented paywall in-place because the paywall components are
                            // cached in a @StateObject on initialization time.
                            #if DEBUG
                            await Task.sleep(seconds: 1)
                            #endif
                            self.presentedPaywall = .init(offering: offering, mode: .default)
                        }
                    }
                }
            }

            let offeringsBySection = Dictionary(
                grouping: offerings,
                by: { Template(name: templateGroupName(offering: $0)) }
            )

            self.offerings = .success(
                .init(
                    sections: Array(offeringsBySection.keys).sorted { $0.description < $1.description },
                    offeringsBySection: offeringsBySection
                )
            )
        } catch let error as NSError {
            self.offerings = .failure(error)
        }
    }

    private func templateGroupName(offering: Offering) -> String? {
        offering.paywall?.templateName ?? offering.paywallComponents?.data.templateName
    }

    @ViewBuilder
    private var content: some View {
        switch self.offerings {
        case let .success(data):
            VStack {
                Text(Self.modesInstructions)
                    .font(.footnote)
                self.list(with: data)
            }

        case let .failure(error):
            Text(error.description)

        case .none:
            SwiftUI.ProgressView()
        }
    }

    private func filteredOfferings(for template: Template, in data: Data) -> [Offering] {
        let offerings = data.offeringsBySection[template] ?? []
        guard !searchText.isEmpty else { return offerings }
        return offerings.filter {
            $0.id.localizedCaseInsensitiveContains(searchText) ||
            $0.serverDescription.localizedCaseInsensitiveContains(searchText)
        }
    }


    @ViewBuilder
    private func list(with data: Data) -> some View {
        List {
            ForEach(data.sections, id: \.self) { template in
                let offerings = filteredOfferings(for: template, in: data)
                if !offerings.isEmpty {
                    Section {
                        ForEach(offerings, id: \.id) { offering in
                            if offering.hasPaywall {
                                #if targetEnvironment(macCatalyst)
                                NavigationLink(
                                    destination: PaywallPresenter(offering: offering,
                                                                  mode: .default,
                                                                  introEligility: .eligible,
                                                                  displayCloseButton: false)
                                        .customPaywallVariables(self.customVariables),
                                    tag: PresentedPaywall(offering: offering, mode: .default),
                                    selection: self.$presentedPaywall
                                ) {
                                    OfferButton(offering: offering) {}
                                    .contextMenu {
                                        self.contextMenu(for: offering)
                                    }
                                }
                                #else
                                OfferButton(offering: offering) {
                                    self.isLoadingPaywall = true
                                    self.presentedPaywall = .init(offering: offering, mode: .default)
                                }
                                    #if !os(watchOS)
                                    .contextMenu {
                                        self.contextMenu(for: offering)
                                    }
                                    #endif
                                #endif
                            } else {
                                VStack(alignment: .leading) {
                                    Text(offering.id)
                                    Text(offering.serverDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text(verbatim: template.description)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search offerings")
        .sheet(item: self.$presentedPaywall) { paywall in
            PaywallPresenter(offering: paywall.offering, mode: paywall.mode, introEligility: .eligible)
                .onRestoreCompleted { _ in
                    self.presentedPaywall = nil
                }
                .customPaywallVariables(self.customVariables)
                .onAppear {
                    self.isLoadingPaywall = false
                    if let errorInfo = paywall.offering.paywallComponents?.data.errorInfo {
                        print("Paywall V2 Error:", errorInfo.debugDescription)
                    }
                }
        }
        #if !os(macOS)
        .fullScreenCover(item: self.$presentedPaywallCover) { paywall in
            PaywallPresenter(offering: paywall.offering, mode: paywall.mode, introEligility: .eligible)
                .onRestoreCompleted { _ in
                    self.presentedPaywall = nil
                }
                .customPaywallVariables(self.customVariables)
                .onAppear {
                    self.isLoadingPaywall = false
                    if let errorInfo = paywall.offering.paywallComponents?.data.errorInfo {
                        print("Paywall V2 Error:", errorInfo.debugDescription)
                    }
                }
        }
        #endif
                .presentPaywallIfNeededModifier(offering: $offeringToPresent)
                .presentPaywall(offering: $presentPaywallOffering, onDismiss: { })
                .onChange(of: offeringToPresent) { offering in
                    if offering != nil {
                        self.isLoadingPaywall = false
                    }
                }
                .onChange(of: presentPaywallOffering) { offering in
                    if offering != nil {
                        self.isLoadingPaywall = false
                    }
                }
    }

    #if !os(watchOS)
    @ViewBuilder
    private func contextMenu(for offering: Offering) -> some View {
        ForEach(PaywallTesterViewMode.allCases, id: \.self) { mode in
            self.button(for: mode, offering: offering)
        }
    }
    #endif

    @ViewBuilder
    private func button(for selectedMode: PaywallTesterViewMode, offering: Offering) -> some View {
        Button {
            self.isLoadingPaywall = true
            switch selectedMode {
            case .fullScreen:
                self.presentedPaywallCover = .init(offering: offering, mode: selectedMode)
            case .sheet, .footer, .condensedFooter:
                self.presentedPaywall = .init(offering: offering, mode: selectedMode)
            case .presentIfNeeded:
                self.offeringToPresent = offering
            case .presentPaywall:
                self.presentPaywallOffering = offering
            }
        } label: {
            Text(selectedMode.name)
            Image(systemName: selectedMode.icon)
        }
    }

    private struct OfferButton: View {
        let offering: Offering
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(self.offering.id)
                        Text(self.offering.serverDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let errorInfo = self.offering.paywallComponents?.data.errorInfo, !errorInfo.isEmpty {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(Color.red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    #if targetEnvironment(macCatalyst)
    private static let modesInstructions = "Right click or ⌘ + click to open in different modes."
    #else
    private static let modesInstructions = "Press and hold to open in different modes."
    #endif

}

extension APIKeyDashboardList.Template: CustomStringConvertible {

    var description: String {
        if let name = self.name {
            if name == "components" {
                return "V2"
            } else {
                #if DEBUG
                if let template = PaywallTemplate(rawValue: name) {
                    return template.name
                } else {
                    return "Unrecognized template"
                }
                #else
                return "Template \(name)"
                #endif
            }
        } else {
            return "No paywall"
        }
    }

}

extension APIKeyDashboardList.PresentedPaywall: Identifiable {

    var id: String {
        return "\(self.offering.id)-\(self.mode.name)"
    }

}
// Custom view modifier for conditional paywall presentation
private struct PresentPaywallIfNeededModifier: ViewModifier {
    @Binding var offering: Offering?
    
    func body(content: Content) -> some View {
        if let offering = offering {
            content.presentPaywallIfNeeded(offering: offering,
                                         shouldDisplay: { _ in true },
                                         onDismiss: { self.offering = nil })
        } else {
            content
        }
    }
}

private extension View {
    func presentPaywallIfNeededModifier(offering: Binding<Offering?>) -> some View {
        self.modifier(PresentPaywallIfNeededModifier(offering: offering))
    }
}
