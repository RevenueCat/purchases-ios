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
    private var selectedTemplate: PaywallTemplate?

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
                .sheet(item: self.$selectedTemplate) { template in
                    PaywallView(offering: loader.offering(for: template))
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
                        self.selectedTemplate = template
                    } label: {
                        Text(template.name)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

}

// MARK: -

extension PaywallTemplate: Identifiable {

    public var id: String {
        return self.rawValue
    }

}

private extension PaywallTemplate {

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
