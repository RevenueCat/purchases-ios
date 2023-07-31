//
//  SamplePaywallsList.swift
//  SimpleApp
//
//  Created by Nacho Soto on 7/27/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

struct SamplePaywallsList: View {

    @State
    private var loader: Result<SamplePaywallLoader, NSError>?

    @State
    private var display: Display?

    var body: some View {
        self.content
            .navigationTitle("Paywalls")
            .task {
                do {
                    self.loader = .success(try await .create())
                } catch let error as NSError {
                    self.loader = .failure(error)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch self.loader {
        case let .success(loader):
            self.list(with: loader)
                .sheet(item: self.$display) { display in
                    switch display {
                    case let .template(template):
                        PaywallView(offering: loader.offering(for: template))
                    case .defaultTemplate:
                        PaywallView(offering: loader.offeringWithDefaultPaywall())
                    }
                }

        case let .failure(error):
            Text(error.description)

        case .none:
            ProgressView()
        }
    }

    private func list(with loader: SamplePaywallLoader) -> some View {
        List {
            Section("Templates") {
                ForEach(PaywallTemplate.allCases, id: \.rawValue) { template in
                    Button {
                        self.display = .template(template)
                    } label: {
                        TemplateLabel(name: template.name)
                    }
                }
            }

            Section("Other") {
                Button {
                    self.display = .defaultTemplate
                } label: {
                    TemplateLabel(name: "Default template")
                }
            }
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
    }

}

private struct TemplateLabel: View {

    var name: String

    var body: some View {
        Text(self.name)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
    }

}

// MARK: -

private extension SamplePaywallsList {

    enum Display {

        case template(PaywallTemplate)
        case defaultTemplate

    }

}

extension SamplePaywallsList.Display: Identifiable {

    public var id: String {
        switch self {
        case let .template(template):
            return template.rawValue
        case .defaultTemplate:
            return "default"
        }
    }

}

extension PaywallTemplate {

    var name: String {
        switch self {
        case .onePackageStandard:
            return "One package standard"
        case .multiPackageBold:
            return "Multi package bold"
        case .onePackageWithFeatures:
            return "One package with features"
        }
    }

}

#if DEBUG

struct SamplePaywallsList_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SamplePaywallsList()
        }
    }
}

#endif
