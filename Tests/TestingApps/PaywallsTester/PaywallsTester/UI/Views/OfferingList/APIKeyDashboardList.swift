//
//  APIKeyDashboardList.swift
//  SimpleApp
//
//  Created by Nacho Soto on 7/27/23.
//

import Foundation
@_spi(Internal) import RevenueCat
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
    private var presentWorkflowSheetOffering: Offering?

    @State
    private var presentWorkflowFullOffering: Offering?

    @State
    private var workflowExitOfferOffering: Offering?

    @State
    private var presentedWorkflowExitOffer: Offering?

    @State
    private var isLoadingPaywall: Bool = false

    @State
    private var customVariables: [String: CustomVariableValue] = [:]

    @State
    private var isShowingVariablesEditor = false

    @State
    private var searchText = Constants.sandboxPaywallSearch

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                NavigationLink {
                    RevenueCatDiscoveryDemoView()
                } label: {
                    HStack {
                        Label("RevenueCat Discovery", systemImage: "sparkles")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                    }
                    .padding()
                    .foregroundStyle(.white)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
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
                    sections: Array(offeringsBySection.keys).sorted {
                        switch ($0.name, $1.name) {
                        case (nil, _): return false
                        case (_, nil): return true
                        default: return $0.description < $1.description
                        }
                    },
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
                                OfferButton(offering: offering) {
                                    self.isLoadingPaywall = true
                                    self.presentedPaywall = .init(offering: offering, mode: .workflow)
                                }
                                .contextMenu {
                                    self.button(for: .workflow, offering: offering)
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
                        Text(verbatim: template.description)
                    }
                }
            }

            Section {
                NavigationLink {
                    RevenueCatDiscoveryDemoView()
                } label: {
                    Label("RevenueCat Discovery", systemImage: "sparkles")
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
                // Uses offeringIdentifier content so workflow context resolves correctly.
                // Exit offer is wired manually because presentPaywall doesn't support workflows yet.
                .sheet(item: self.$presentWorkflowSheetOffering, onDismiss: self.handleWorkflowDismiss) { offering in
                    self.workflowPaywallView(for: offering)
                }
                .fullScreenCover(item: self.$presentWorkflowFullOffering, onDismiss: self.handleWorkflowDismiss) { offering in
                    self.workflowPaywallView(for: offering)
                }
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
    private func workflowPaywallView(for offering: Offering) -> some View {
        PaywallView(configuration: .init(
            content: .offeringIdentifier(offering.identifier, presentedOfferingContext: nil),
            displayCloseButton: true,
            purchaseHandler: .default()
        ))
        #if DEBUG
        .environment(\.workflowExitOfferOfferingBinding, self.$workflowExitOfferOffering)
        #endif
        .customPaywallVariables(self.customVariables)
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

    private struct RevenueCatDiscoveryDemoView: View {

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Focus Timer")
                            .font(.largeTitle.bold())
                        Text("A tiny fake productivity app surface for testing RevenueCat Discovery.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Today")
                                    .font(.headline)
                                Text("3 sessions completed")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "timer")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }

                        ProgressView(value: 0.68)

                        HStack(spacing: 12) {
                            stat(title: "Focus", value: "2h 12m")
                            stat(title: "Streak", value: "8 days")
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Partner perks")
                            .font(.headline)
                        Text("Discover apps that pair well with your routine.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        NavigationLink {
                            AppRecommendationsView()
                        } label: {
                            HStack {
                                Label("Get deals from our partners", systemImage: "gift.fill")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                            }
                            .padding()
                            .foregroundStyle(.white)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming")
                            .font(.headline)

                        fakeTask("Deep work session", detail: "25 minutes")
                        fakeTask("Stretch break", detail: "5 minutes")
                        fakeTask("Evening review", detail: "10 minutes")
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }

        private func stat(title: String, value: String) -> some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.headline)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }

        private func fakeTask(_ title: String, detail: String) -> some View {
            HStack {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
                Text(title)
                Spacer()
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

    }

    private struct AppRecommendationsView: View {

        private enum LoadingState {
            case loading
            case loaded(RecommendationsResponse)
            case failed(String)
        }

        private struct RecommendationsResponse: Decodable {
            let placementID: String
            let title: String
            let subtitle: String
            let layout: String
            let items: [RecommendationItem]

            enum CodingKeys: String, CodingKey {
                case placementID = "placement_id"
                case title
                case subtitle
                case layout
                case items
            }
        }

        fileprivate struct RecommendationItem: Decodable, Identifiable {
            let id: String
            let name: String
            let headline: String
            let body: String
            let iconURL: URL?
            let appStoreID: String
            let appStoreURL: URL?
            let cta: String

            enum CodingKeys: String, CodingKey {
                case id
                case name
                case headline
                case body
                case iconURL = "icon_url"
                case appStoreID = "app_store_id"
                case appStoreURL = "app_store_url"
                case cta
            }
        }

        @Environment(\.openURL)
        private var openURL

        @State
        private var state: LoadingState = .loading

        var body: some View {
            Group {
                switch state {
                case .loading:
                    SwiftUI.ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                case let .loaded(response):
                    if response.items.isEmpty {
                        EmptyStateView(
                            title: "No recommendations available",
                            systemImage: "sparkles"
                        )
                    } else {
                        recommendationsList(response)
                    }

                case let .failed(message):
                    VStack(spacing: 16) {
                        EmptyStateView(
                            title: "Couldn’t load recommendations",
                            systemImage: "exclamationmark.triangle",
                            description: message
                        )

                        Button {
                            Task {
                                await fetchRecommendations()
                            }
                        } label: {
                            Label("Retry", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("App Recommendations")
            .task {
                await fetchRecommendations()
            }
            .refreshable {
                await fetchRecommendations()
            }
        }

        private func recommendationsList(_ response: RecommendationsResponse) -> some View {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(response.title)
                            .font(.title2.bold())
                        Text(response.subtitle)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 16)

                    ForEach(response.items) { item in
                        RecommendationCard(item: item) {
                            if let url = item.appStoreURL {
                                Task {
                                    await trackRecommendationClick(item)
                                }
                                openURL(url)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
        }

        @MainActor
        private func fetchRecommendations() async {
            state = .loading

            do {
                let request = try makeRequest()
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }

                guard (200..<300).contains(httpResponse.statusCode) else {
                    throw RecommendationsError.requestFailed(httpResponse.statusCode)
                }

                let decoder = JSONDecoder()
                let recommendations = try decoder.decode(RecommendationsResponse.self, from: data)
                state = .loaded(recommendations)
            } catch {
                state = .failed(error.localizedDescription)
            }
        }

        private func makeRequest() throws -> URLRequest {
            guard var components = URLComponents(string: Constants.proxyURL ?? "https://api.revenuecat.com") else {
                throw RecommendationsError.invalidURL
            }

            components.path = "/v1/subscribers/$RCAnonymousID:paywalls-tester/recommendations"
            components.queryItems = [
                URLQueryItem(name: "placement", value: "paywall_dismissed"),
                URLQueryItem(name: "cache_buster", value: UUID().uuidString)
            ]

            guard let url = components.url else {
                throw RecommendationsError.invalidURL
            }

            var request = URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                timeoutInterval: 30
            )
            request.setValue("Bearer \(Constants.apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("iOS", forHTTPHeaderField: "X-Platform")
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            request.setValue("no-cache", forHTTPHeaderField: "Pragma")
            return request
        }

        private func trackRecommendationClick(_ item: RecommendationItem) async {
            do {
                let request = try makeClickRequest(item)
                _ = try await URLSession.shared.data(for: request)
            } catch {
                // Best effort analytics; opening the app should not depend on tracking.
            }
        }

        private func makeClickRequest(_ item: RecommendationItem) throws -> URLRequest {
            guard var components = URLComponents(string: Constants.proxyURL ?? "https://api.revenuecat.com") else {
                throw RecommendationsError.invalidURL
            }

            components.path = "/v1/subscribers/$RCAnonymousID:paywalls-tester/recommendations/clicks"

            guard let url = components.url else {
                throw RecommendationsError.invalidURL
            }

            var request = URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                timeoutInterval: 30
            )
            request.httpMethod = "POST"
            request.setValue("Bearer \(Constants.apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("iOS", forHTTPHeaderField: "X-Platform")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "recommendation_id": item.id,
                "placement": "paywall_dismissed"
            ])
            return request
        }

    }

    private struct RecommendationCard: View {

        let item: AppRecommendationsView.RecommendationItem
        let open: () -> Void

        var body: some View {
            Button(action: open) {
                HStack(alignment: .top, spacing: 14) {
                    AsyncImage(url: item.iconURL) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Image(systemName: "app.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 54, height: 54)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.name)
                            .font(.headline)

                        Text(item.headline)
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        Text(item.body)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 4) {
                            Text(item.cta)
                                .font(.caption.bold())
                            Image(systemName: "arrow.up.right")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.accentColor)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(item.appStoreURL == nil)
        }

    }

    private struct EmptyStateView: View {

        let title: String
        let systemImage: String
        var description: String?

        var body: some View {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.headline)

                if let description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

    }

    private enum RecommendationsError: LocalizedError {

        case invalidURL
        case requestFailed(Int)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "The recommendations URL is invalid."
            case let .requestFailed(statusCode):
                return "The server returned status code \(statusCode)."
            }
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
