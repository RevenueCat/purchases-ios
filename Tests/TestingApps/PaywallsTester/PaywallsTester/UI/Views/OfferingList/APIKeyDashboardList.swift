//
//  APIKeyDashboardList.swift
//  SimpleApp
//
//  Created by Nacho Soto on 7/27/23.
//

@_spi(Internal) import RevenueCat
#if DEBUG
@_spi(Internal) @testable import RevenueCatUI
#else
@_spi(Internal) import RevenueCatUI
#endif
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct APIKeyDashboardList: View {

    fileprivate enum PaywallSection: Hashable, Comparable {
        case legacy(templateName: String)
        case components
        case noPaywall

        init(hasPaywall: Bool, legacyTemplateName: String?) {
            guard hasPaywall else {
                self = .noPaywall
                return
            }

            if let legacyTemplateName {
                self = .legacy(templateName: legacyTemplateName)
            } else {
                self = .components
            }
        }

        init(offering: Offering) {
            self.init(
                hasPaywall: offering.hasPaywall,
                legacyTemplateName: offering.paywall?.templateName
            )
        }

        static func < (lhs: Self, rhs: Self) -> Bool {
            if lhs == .noPaywall { return false }
            if rhs == .noPaywall { return true }
            return lhs.description < rhs.description
        }
    }

    fileprivate struct Data: Hashable {
        var sections: [PaywallSection]
        var offeringsBySection: [PaywallSection: [Offering]]
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
    private var presentWorkflowSheetOffering: Offering?

    @State
    private var presentWorkflowFullOffering: Offering?

    @State
    private var workflowExitOfferOffering: Offering?

    @State
    private var presentedWorkflowExitOffer: Offering?

    #if DEBUG && !os(tvOS)
    @State
    private var workflowRows: [WorkflowRow] = []

    @State
    private var presentedWorkflowSheet: PresentedWorkflow?

    @State
    private var presentedWorkflowFull: PresentedWorkflow?

    @State
    private var workflowLoadError: String?
    #endif

    @State
    private var isLoadingPaywall: Bool = false

    @State
    private var customVariables: [String: CustomVariableValue] = [:]

    @State
    private var isShowingVariablesEditor = false

    @State
    private var searchText = Constants.sandboxPaywallSearch

    var body: some View {
        ZStack {
            NavigationView {
                self.content
                    .navigationTitle(Self.title)
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
                by: PaywallSection.init(offering:)
            )

            #if DEBUG && !os(tvOS)
            self.workflowRows = await WorkflowRow.loadAll()
            #endif

            self.offerings = .success(
                .init(
                    sections: Array(offeringsBySection.keys).sorted(),
                    offeringsBySection: offeringsBySection
                )
            )
        } catch let error as NSError {
            self.offerings = .failure(error)
        }
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

    private func filteredOfferings(for section: PaywallSection, in data: Data) -> [Offering] {
        var offerings = data.offeringsBySection[section] ?? []
        #if DEBUG && !os(tvOS)
        // A claimed offering is opened through its flow in the Flows section.
        let claimed = Set(self.workflowRows.compactMap(\.claimedOfferingIdentifier))
        offerings.removeAll { claimed.contains($0.identifier) }
        #endif
        guard !searchText.isEmpty else { return offerings }
        return offerings.filter {
            $0.id.localizedCaseInsensitiveContains(searchText) ||
            $0.serverDescription.localizedCaseInsensitiveContains(searchText)
        }
    }


    @ViewBuilder
    private func list(with data: Data) -> some View {
        let firstPaywallSection = data.sections.first {
            $0 != .noPaywall && !self.filteredOfferings(for: $0, in: data).isEmpty
        }
        List {
            #if DEBUG && !os(tvOS)
            self.workflowsSection
            self.uiLessWorkflowsSection(data: data)
            #endif
            ForEach(data.sections, id: \.self) { section in
                let offerings = filteredOfferings(for: section, in: data)
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
                                    self.presentPaywallOffering = offering
                                }
                                    #if !os(watchOS)
                                    .contextMenu {
                                        self.contextMenu(for: offering)
                                    }
                                    #endif
                                #endif
                            } else {
                                #if !os(watchOS)
                                OfferButton(offering: offering, detail: self.flowsUsingDescription(offering)) {
                                    self.isLoadingPaywall = true
                                    self.presentedPaywall = .init(offering: offering, mode: .workflow)
                                }
                                .contextMenu {
                                    self.button(for: .workflow, offering: offering)
                                    self.button(for: .presentWorkflow, offering: offering)
                                }
                                #else
                                VStack(alignment: .leading) {
                                    Text(offering.id)
                                    Text(offering.serverDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                #endif
                            }
                        }
                    } header: {
                        SectionHeader(
                            title: section.title,
                            caption: section == firstPaywallSection || section == .noPaywall ? section.caption : nil
                        )
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search")
        .sheet(item: self.$presentedPaywall) { paywall in
            PaywallPresenter(offering: paywall.offering, mode: paywall.mode, introEligility: .eligible)
                .onRestoreCompleted { _ in
                    self.presentedPaywall = nil
                }
                .customPaywallVariables(self.customVariables)
                .onAppear {
                    self.isLoadingPaywall = false
                    if let errorInfo = paywall.offering.internalPaywallComponents?.data.errorInfo {
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
                    if let errorInfo = paywall.offering.internalPaywallComponents?.data.errorInfo {
                        print("Paywall V2 Error:", errorInfo.debugDescription)
                    }
                }
        }
        #endif
                .presentPaywallIfNeededModifier(offering: $offeringToPresent)
                .presentPaywall(offering: $presentPaywallOffering,
                                urlOpened: { url in
                                    print("Paywall Handler - onURLOpened: \(url)")
                                },
                                onDismiss: { })
                // Uses offeringIdentifier content so workflow context resolves correctly.
                // Exit offer is wired manually because presentPaywall doesn't support workflows yet.
                .sheet(item: self.$presentWorkflowSheetOffering, onDismiss: self.handleWorkflowDismiss) { offering in
                    self.workflowPaywallView(for: offering)
                }
                #if os(macOS)
                .sheet(item: self.$presentWorkflowFullOffering, onDismiss: self.handleWorkflowDismiss) { offering in
                    self.workflowPaywallView(for: offering)
                }
                #else
                .fullScreenCover(item: self.$presentWorkflowFullOffering, onDismiss: self.handleWorkflowDismiss) { offering in
                    self.workflowPaywallView(for: offering)
                }
                #endif
                .sheet(item: self.$presentedWorkflowExitOffer) { exitOffering in
                    PaywallView(offering: exitOffering)
                        .customPaywallVariables(self.customVariables)
                }
                .customPaywallVariables(self.customVariables)
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
                .onChange(of: presentWorkflowSheetOffering) { offering in
                    if offering != nil {
                        self.isLoadingPaywall = false
                    }
                }
                .onChange(of: presentWorkflowFullOffering) { offering in
                    if offering != nil {
                        self.isLoadingPaywall = false
                    }
                }
                #if DEBUG && !os(tvOS)
                .sheet(item: self.$presentedWorkflowSheet, onDismiss: self.handleWorkflowDismiss) { workflow in
                    self.workflowPaywallView(for: workflow)
                }
                #if os(macOS)
                .sheet(item: self.$presentedWorkflowFull, onDismiss: self.handleWorkflowDismiss) { workflow in
                    self.workflowPaywallView(for: workflow)
                }
                #else
                .fullScreenCover(item: self.$presentedWorkflowFull, onDismiss: self.handleWorkflowDismiss) { workflow in
                    self.workflowPaywallView(for: workflow)
                }
                #endif
                .alert(
                    "Couldn't open flow",
                    isPresented: .init(
                        get: { self.workflowLoadError != nil },
                        set: { if !$0 { self.workflowLoadError = nil } }
                    ),
                    actions: {},
                    message: { Text(self.workflowLoadError ?? "") }
                )
                #endif
    }

    #if DEBUG && !os(tvOS)
    @ViewBuilder
    private var workflowsSection: some View {
        let rows = self.filteredWorkflowRows.filter { $0.uiLessOfferingIdentifier == nil }

        if !rows.isEmpty {
            Section {
                ForEach(rows) { row in
                    Button {
                        self.openWorkflow(row.id, fullScreen: false)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(row.name ?? row.id)
                            Text(row.subtitle)
                                .font(.caption)
                                .foregroundStyle(row.error == nil ? Color.secondary : Color.red)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    #if !os(watchOS)
                    .contextMenu {
                        Button {
                            self.openWorkflow(row.id, fullScreen: false)
                        } label: {
                            Text("Sheet")
                            Image(systemName: PaywallTesterViewMode.sheet.icon)
                        }
                        Button {
                            self.openWorkflow(row.id, fullScreen: true)
                        } label: {
                            Text("Full screen")
                            Image(systemName: PaywallTesterViewMode.fullScreen.icon)
                        }
                    }
                    #endif
                }
            } header: {
                SectionHeader(
                    title: "Flows",
                    caption: "Opened by id. Shows the offering each flow is attached to."
                )
            }
        }
    }

    private var filteredWorkflowRows: [WorkflowRow] {
        return self.searchText.isEmpty
            ? self.workflowRows
            : self.workflowRows.filter { $0.matches(self.searchText) }
    }

    @ViewBuilder
    private func uiLessWorkflowsSection(data: Data) -> some View {
        let rows = self.filteredWorkflowRows.filter { $0.uiLessOfferingIdentifier != nil }

        if !rows.isEmpty {
            Section {
                ForEach(rows) { row in
                    let offeringIdentifier = row.uiLessOfferingIdentifier ?? ""
                    Button {
                        self.openOffering(offeringIdentifier, in: data)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(row.name ?? row.id)
                            Text("Offering: \(offeringIdentifier)")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                SectionHeader(
                    title: "UI-less flows",
                    caption: "Return only an offering. Opens that offering, like an app."
                )
            }
        }
    }

    private func openOffering(_ identifier: String, in data: Data) {
        guard let offering = data.offeringsBySection.values.joined().first(where: { $0.identifier == identifier })
        else {
            self.workflowLoadError = "Offering '\(identifier)' is not in the offerings."
            return
        }
        #if canImport(UIKit) && !os(watchOS)
        UILessFlowPresenter.present(offering)
        #else
        self.isLoadingPaywall = true
        self.presentedPaywall = .init(offering: offering, mode: .workflow)
        #endif
    }

    private func openWorkflow(_ workflowId: String, fullScreen: Bool) {
        Task {
            do {
                let workflow = try await PresentedWorkflow.load(workflowId: workflowId)
                if fullScreen {
                    self.presentedWorkflowFull = workflow
                } else {
                    self.presentedWorkflowSheet = workflow
                }
            } catch {
                self.workflowLoadError = error.localizedDescription
            }
        }
    }

    private func workflowPaywallView(for workflow: PresentedWorkflow) -> some View {
        PaywallView(workflowContext: workflow.context, displayCloseButton: true)
            .environment(\.workflowExitOfferOfferingBinding, self.$workflowExitOfferOffering)
            .customPaywallVariables(self.customVariables)
            .onURLOpened { url in
                print("Paywall Handler - onURLOpened: \(url)")
            }
    }
    #endif

    #if !os(watchOS)
    @ViewBuilder
    private func contextMenu(for offering: Offering) -> some View {
        ForEach(PaywallTesterViewMode.allCases, id: \.self) { mode in
            self.button(for: mode, offering: offering)
        }

        #if os(iOS)
        // Presents through the UIKit `PaywallViewController` so its dismissal handling and the
        // workflow exit-offer bridge can be exercised.
        Button {
            self.isLoadingPaywall = true
            self.presentUIKitPaywall(for: offering)
        } label: {
            Text("UIKit View Controller")
            Image(systemName: "rectangle.portrait.on.rectangle.portrait")
        }
        #endif
    }
    #endif

    #if os(iOS)
    @MainActor
    private func presentUIKitPaywall(for offering: Offering) {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        guard var top = (windows.first(where: \.isKeyWindow) ?? windows.first)?.rootViewController else {
            self.isLoadingPaywall = false
            return
        }
        while let presented = top.presentedViewController {
            top = presented
        }
        top.present(PaywallViewController(offering: offering, displayCloseButton: true), animated: true)
        self.isLoadingPaywall = false
    }
    #endif

    @ViewBuilder
    private func workflowPaywallView(for offering: Offering) -> some View {
        PaywallView(offeringIdentifier: offering.identifier, displayCloseButton: true)
        #if DEBUG
        .environment(\.workflowExitOfferOfferingBinding, self.$workflowExitOfferOffering)
        #endif
        .customPaywallVariables(self.customVariables)
        .onURLOpened { url in
            print("Paywall Handler - onURLOpened: \(url)")
        }
        .onAppear {
            self.isLoadingPaywall = false
        }
    }

    private func handleWorkflowDismiss() {
        if let exitOffer = self.workflowExitOfferOffering {
            self.presentedWorkflowExitOffer = exitOffer
            self.workflowExitOfferOffering = nil
        }
    }

    @ViewBuilder
    private func button(for selectedMode: PaywallTesterViewMode, offering: Offering) -> some View {
        Button {
            self.isLoadingPaywall = true
            switch selectedMode {
            case .fullScreen:
                self.presentedPaywallCover = .init(offering: offering, mode: selectedMode)
            case .sheet:
                self.presentedPaywall = .init(offering: offering, mode: selectedMode)
            #if !os(watchOS) && !os(macOS)
            case .footer, .condensedFooter:
                self.presentedPaywall = .init(offering: offering, mode: selectedMode)
            #endif
            case .presentIfNeeded:
                self.offeringToPresent = offering
            case .presentPaywall:
                self.presentPaywallOffering = offering
            case .workflow:
                self.presentWorkflowSheetOffering = offering
            case .presentWorkflow:
                self.presentWorkflowFullOffering = offering
            }
        } label: {
            Text(selectedMode.name)
            Image(systemName: selectedMode.icon)
        }
    }

    private struct SectionHeader: View {
        let title: String
        let caption: String?

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: self.title)
                if let caption {
                    Text(verbatim: caption)
                        .font(.caption)
                        .textCase(nil)
                }
            }
        }
    }

    private struct OfferButton: View {
        let offering: Offering
        var detail: String?
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(self.offering.id)
                        Text(self.detail ?? self.offering.serverDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let errorInfo = self.offering.internalPaywallComponents?.data.errorInfo, !errorInfo.isEmpty {
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

    private func flowsUsingDescription(_ offering: Offering) -> String? {
        #if DEBUG && !os(tvOS)
        let names = self.workflowRows.filter { $0.uses(offering.identifier) }.map { $0.name ?? $0.id }
        return names.isEmpty ? nil : "Used by: \(names.joined(separator: ", "))"
        #else
        return nil
        #endif
    }

    #if DEBUG && !os(tvOS)
    static let title = "Flows"
    #else
    static let title = "Live Paywalls"
    #endif

    #if targetEnvironment(macCatalyst)
    private static let modesInstructions = "Right click or ⌘ + click to open in different modes."
    #else
    private static let modesInstructions = "Press and hold to open in different modes."
    #endif

}

extension APIKeyDashboardList.PaywallSection: CustomStringConvertible {

    var description: String {
        switch self {
        case let .legacy(templateName):
            #if DEBUG
            if let template = PaywallTemplate(rawValue: templateName) {
                return template.name
            } else {
                return "Unrecognized template"
            }
            #else
            return "Template \(templateName)"
            #endif
        case .components:
            return "V2"
        case .noPaywall:
            return "Unclaimed offerings"
        }
    }

    var title: String {
        return self == .noPaywall ? self.description : "Paywalls · \(self.description)"
    }

    var caption: String {
        return self == .noPaywall
            ? "No paywall or flow attached. Opens the fallback."
            : "Paywalls attached directly to an offering."
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
                                         urlOpened: { url in
                                             print("Paywall Handler - onURLOpened: \(url)")
                                         },
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
