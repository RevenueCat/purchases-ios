import RevenueCat
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct Example1Template: TemplateViewType {

    private var data: Result<Example1TemplateContent.Data, Example1TemplateContent.Error>

    init(
        packages: [Package],
        localization: PaywallData.LocalizedConfiguration,
        paywall: PaywallData
    ) {
        // Fix-me: move this logic out to be used by all templates
        if packages.isEmpty {
            self.data = .failure(.noPackages)
        } else {
            let allPackages = paywall.config.packages
            let packages = Self.filter(packages: packages, with: allPackages)

            if let package = packages.first {
                self.data = .success(.init(
                    package: package,
                    localization: localization.processVariables(with: package),
                    configuration: paywall.config,
                    headerImageURL: paywall.headerImageURL
                ))
            } else {
                self.data = .failure(.couldNotFindAnyPackages(expectedTypes: allPackages))
            }
        }
    }

    // Fix-me: this can be extracted to be used by all templates
    var body: some View {
        switch self.data {
        case let .success(data):
            Example1TemplateContent(data: data)
        case let .failure(error):
            DebugErrorView(error)
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
            AsyncImage(url: self.data.headerImageURL) { phase in
                if let image = phase.image {
                    image
                        .fitToAspect(Self.imageAspectRatio, contentMode: .fill)
                        .edgesIgnoringSafeArea(.top)
                } else if let error = phase.error {
                    DebugErrorView("Error loading image from '\(self.data.headerImageURL)': \(error)")
                } else {
                    Rectangle()
                        .hidden()
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(Self.imageAspectRatio, contentMode: .fit)
            .clipShape(
                Circle()
                    .offset(y: -100)
                    .scale(3.0)
            )

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

    private static let imageAspectRatio = 0.7

}

// MARK: -

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension Example1TemplateContent {

    struct Data {
        let package: Package
        let localization: ProcessedLocalizedConfiguration
        let configuration: PaywallData.Configuration
        let headerImageURL: URL
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
extension Example1TemplateContent.Error: CustomNSError {

    var errorUserInfo: [String: Any] {
        return [
            NSLocalizedDescriptionKey: self.description
        ]
    }

    private var description: String {
        switch self {
        case .noPackages:
            return "Attempted to display paywall with no packages."
        case let .couldNotFindAnyPackages(expectedTypes):
            return "Couldn't find any requested packages: \(expectedTypes)"
        }
    }

}
