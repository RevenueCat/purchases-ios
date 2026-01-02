import RevenueCat
import RevenueCatUI
import SwiftUI

struct PaywallsTabView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(HealthViewModel.self) private var healthViewModel
    @Environment(UserViewModel.self) private var userViewModel
    @State private var selectedOffering: Offering?

    var body: some View {
        ScrollView {
            ConceptIntroductionView(imageName: "visual-revenuecat-ui",
                                    title: "Paywalls",
                                    description: "Display beautiful, customizable paywalls to showcase your offerings and drive conversions.")

            VStack(spacing: 12) {
                if let offerings = userViewModel.offerings?.all.values {
                    ForEach(Array(offerings), id: \.id) { offering in
                        Button {
                            selectedOffering = offering
                        } label: {
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(offering.paywall?.templateName ?? offering.identifier)
                                        .font(.headline)
                                    Text("\(offering.availablePackages.count) package\(offering.availablePackages.count > 1 ? "s" : "")")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(scheme == .dark ? Color.black : Color.white)
                            .foregroundStyle(Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .blur(radius: healthViewModel.isfetchingHealthReport ? 5 : 0)
            .overlay {
                if healthViewModel.isfetchingHealthReport {
                    Spinner()
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background {
            ContentBackgroundView(color: Color("RC-royal-blue"))
        }
        .sheet(item: $selectedOffering) { offering in
            PaywallView(offering: offering, displayCloseButton: true)
        }
        .task {
            guard !healthViewModel.isfetchingHealthReport, healthViewModel.offerings.isEmpty else { return }

            await healthViewModel.fetchHealthReport()
        }
        .refreshable(action: healthViewModel.fetchHealthReport)
    }
}
