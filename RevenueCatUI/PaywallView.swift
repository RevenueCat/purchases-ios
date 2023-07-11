import RevenueCat
import SwiftUI

// swiftlint:disable missing_docs

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
public struct PaywallView: View {

    public let offering: Offering

    public init(offering: Offering) {
        self.offering = offering
    }

    public var body: some View {
        VStack {
            Text(verbatim: "Offering: \(self.offering.identifier)")
                .font(.title)

            List {
                ForEach(self.offering.availablePackages, id: \.identifier) { package in
                    self.label(for: package)
                        .listRowBackground(
                            Rectangle()
                                .foregroundStyle(.thinMaterial)
                        )
                }
            }
            .scrollContentBackground(.hidden)
        }
        .background(.blue.gradient)
    }

    private func label(for package: Package) -> some View {
        HStack {
            Button {

            } label: {
                Text(package.storeProduct.localizedTitle)
                    .padding(.vertical)
            }
            .buttonStyle(.plain)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.body)
        }
    }

}

#if DEBUG

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct PaywallView_Previews: PreviewProvider {

    static var previews: some View {
        PaywallView(offering: TestData.offering)
    }

}

#endif
