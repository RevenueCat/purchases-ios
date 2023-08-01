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
    private var display: Display?

    var body: some View {
        self.list(with: Self.loader)
            .sheet(item: self.$display) { display in
                switch display {
                case let .template(template):
                    PaywallView(offering: Self.loader.offering(for: template))
                case .defaultTemplate:
                    PaywallView(offering: Self.loader.offeringWithDefaultPaywall())
                }
            }
            .navigationTitle("Paywalls")
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

    private static let loader: SamplePaywallLoader = .init()

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
        case .multiPackageHorizontal:
            return "Multi package horizontal"
        }
    }

}

#if DEBUG

struct SamplePaywallsList_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SamplePaywallsList()
        }
    }
}

#endif
