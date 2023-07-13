import RevenueCat
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct Example1Template: TemplateViewType {

    private var data: Result<Example1TemplateContent.Data, Example1TemplateContent.Error>

    init(
        packages: [Package],
        localization: PaywallData.LocalizedConfiguration,
        configuration: PaywallData.Configuration
    ) {
        // Fix-me: move this logic out to be used by all templates
        if packages.isEmpty {
            self.data = .failure(.noPackages)
        } else {
            let packages = Self.filter(packages: packages, with: configuration.packages)

            if let package = packages.first {
                self.data = .success(.init(
                    package: package,
                    localization: localization.processVariables(with: package),
                    configuration: configuration
                ))
            } else {
                self.data = .failure(.couldNotFindAnyPackages(expectedTypes: configuration.packages))
            }
        }
    }

    // Fix-me: this can be extracted to be used by all templates
    var body: some View {
        switch self.data {
        case let .success(data):
            Example1TemplateContent(data: data)
        case let .failure(error):
            #if DEBUG
            // Fix-me: implement a proper production error screen
            EmptyView()
                .onAppear {
                    Logger.warning("Couldn't load paywall: \(error.description)")
                }
            #else
            Text(error.description)
                .background(
                    Color.red
                        .edgesIgnoringSafeArea(.all)
                )
            #endif
        }
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private struct Example1TemplateContent: View {

    private var data: Data

    init(data: Data) {
        self.data = data
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
                Text(verbatim: self.data.localization.title)
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .padding(.bottom)

                Text(verbatim: self.data.localization.subtitle)
                    .font(.subheadline)
                    .padding(.horizontal)

                Spacer()

                self.offerDetails

                self.button
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var offerDetails: some View {
        // Fix-me: this needs to handle other types of intro discounts
        let text = self.data.package.storeProduct.introductoryDiscount == nil
            ? self.data.localization.offerDetails
            : self.data.localization.offerDetailsWithIntroOffer

        Text(verbatim: text)
            .font(.callout)
    }

    @ViewBuilder
    private var button: some View {
        Button {

        } label: {
            Text(self.data.localization.callToAction)
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

// MARK: -

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension Example1TemplateContent {

    struct Data {
        let package: Package
        let localization: ProcessedLocalizedConfiguration
        let configuration: PaywallData.Configuration
    }

    enum Error: Swift.Error {

        case noPackages
        case couldNotFindAnyPackages(expectedTypes: [PackageType])

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

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension Example1TemplateContent.Error {

    var description: String {
        switch self {
        case .noPackages:
            return "Attempted to display paywall with no packages."
        case let .couldNotFindAnyPackages(expectedTypes):
            return "Couldn't find any requested packages: \(expectedTypes)"
        }
    }

}
