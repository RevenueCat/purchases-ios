import RevenueCat
import RevenueCatUI
import SwiftUI

struct CustomerCenterTabView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(HealthViewModel.self) private var healthViewModel
    @State private var showCustomerCenter = false

    var body: some View {
        ScrollView {
            ConceptIntroductionView(imageName: "visual-customer-center",
                                    title: "Customer Center",
                                    description: "Help your customers manage their subscriptions with a self-service Customer Center.")

            VStack(spacing: 12) {
                Button {
                    showCustomerCenter = true
                } label: {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Open Customer Center")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .font(.headline)
                    .padding()
                    .background(scheme == .dark ? Color.black : Color.white)
                    .foregroundStyle(Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
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
            ContentBackgroundView(color: Color("RC-purple"))
        }
        .sheet(isPresented: $showCustomerCenter) {
            CustomerCenterView()
        }
        .task {
            guard !healthViewModel.isfetchingHealthReport, healthViewModel.offerings.isEmpty else { return }

            await healthViewModel.fetchHealthReport()
        }
        .refreshable(action: healthViewModel.fetchHealthReport)
    }
}
