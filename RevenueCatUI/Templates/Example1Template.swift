import RevenueCat
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct Example1Template: TemplateViewType {

    private let package: Package
    private let localization: ProcessedLocalizedConfiguration
    private let configuration: PaywallData.Configuration

    init(
        packages: [Package],
        localization: PaywallData.LocalizedConfiguration,
        configuration: PaywallData.Configuration
    ) {
        // The RC SDK ensures this when constructing Offerings
        precondition(!packages.isEmpty)

        self.package = packages[0]
        self.localization = localization.processVariables(with: self.package)
        self.configuration = configuration

        precondition(
            self.package.storeProduct.productCategory == .subscription,
            "Unexpected product type for this template: \(self.package.storeProduct.productType)"
        )
    }

    var body: some View {
        ZStack {
            self.content
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack {
            Image("image", bundle: .module)
                .resizable()
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fill)
                .edgesIgnoringSafeArea(.top)
                .padding(.bottom)
                .mask(alignment: .top) {
                    Circle()
                        .offset(y: -160)
                        .scale(2.5)
                }

            Spacer()

            VStack {
                Text(verbatim: self.localization.title)
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .padding(.bottom)

                Text(verbatim: self.localization.subtitle)
                    .font(.subheadline)
                    .padding(.horizontal)

                Spacer()

                Text(verbatim: self.localization.offerDetails)
                    .font(.callout)

                self.button
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var button: some View {
        Button {

        } label: {
            Text(self.localization.callToAction)
                .frame(maxWidth: .infinity)
        }
        .font(.title2)
        .fontWeight(.semibold)
        .tint(Color.green.gradient.opacity(0.8))
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension Example1Template {

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
