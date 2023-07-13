import RevenueCat
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct Example1Template: TemplateViewType {

    private let packages: [Package]
    private let localization: PaywallData.LocalizedConfiguration
    private let configuration: PaywallData.Configuration

    init(
        packages: [Package],
        localization: PaywallData.LocalizedConfiguration,
        configuration: PaywallData.Configuration
    ) {
        self.packages = packages
        self.localization = localization
        self.configuration = configuration
    }

    var body: some View {
        VStack {
            Text(verbatim: self.localization.title)
                .font(.title)

            List {
                ForEach(self.packages, id: \.identifier) { package in
                    self.label(for: package)
                        .listRowBackground(
                            Rectangle()
                                .foregroundStyle(.thinMaterial)
                        )
                }
            }
            .scrollContentBackground(.hidden)

            Button {

            } label: {
                Text(self.localization.callToAction)
            }
            .buttonStyle(.borderedProminent)
            .font(.title2)
            .tint(Color.indigo.gradient)
            .buttonBorderShape(.roundedRectangle)
            .controlSize(.large)
        }
        .background(.blue.gradient)
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
