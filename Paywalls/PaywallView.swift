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

            List {
                ForEach(self.offering.availablePackages, id: \.identifier) { package in
                    Text(package.packageType.debugDescription)
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct PaywallView_Previews: PreviewProvider {

    static var previews: some View {
        PaywallView(offering: TestData.offering)
    }

}
