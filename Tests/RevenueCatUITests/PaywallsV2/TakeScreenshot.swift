//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TakeScreenshot.swift
//
//  Created by Josh Holtz on 5/28/25.

import CoreGraphics
import Nimble
@testable import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting
import SwiftUI
import XCTest

#if !os(watchOS) && !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TakeScreenshotTests: BaseSnapshotTest {

    struct PackageData: Decodable {
        let packages: [OfferingsResponse.Offering.Package]
    }

    func testPaywallValidationScreenshots() {
        let bundle = Bundle(for: Self.self)

        guard let resourcesFolderURL = bundle.url(
            forResource: "paywall-preview-resources", withExtension: nil
        ) else {
            XCTFail("Could not locate paywall-preview-resources")
            return
        }

        let baseResourcesURL = resourcesFolderURL
            .appendingPathComponent("resources")

        let resourceDirectories = (try? FileManager.default.contentsOfDirectory(
            at: baseResourcesURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        ))?.filter { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        } ?? []

        if resourceDirectories.isEmpty {
            XCTFail("No valid resource directories found")
            return
        }

        for resourceURL in resourceDirectories {
            let resource = resourceURL.lastPathComponent
            let offeringsFileName = "offerings.json"

            let packagesPath = baseResourcesURL
                .appendingPathComponent("packages.json")

            let offeringsPath = baseResourcesURL
                .appendingPathComponent(resource)
                .appendingPathComponent(offeringsFileName)

            let originalImagesURL = "https://assets.pawwalls.com"
            let replacementImagesURL = baseResourcesURL
                .appendingPathComponent(resource)
                .appendingPathComponent("pawwalls")
                .appendingPathComponent("assets")
                .absoluteString
            let originalIconsURL = "https://icons.pawwalls.com"
            let replacementIconsURL = baseResourcesURL
                .appendingPathComponent(resource)
                .appendingPathComponent("pawwalls")
                .appendingPathComponent("icons")
                .absoluteString

            // Read original file as String
            guard let offeringsRawString = try? String(contentsOf: offeringsPath) else {
                XCTFail("Couldn't read offerings file as String")
                return
            }

            // Replace URLs
            let modifiedJSON = offeringsRawString
                .replacingOccurrences(of: originalImagesURL, with: replacementImagesURL)
                .replacingOccurrences(of: originalIconsURL, with: replacementIconsURL)

            // Decode updated JSON
            guard let modifiedData = modifiedJSON.data(using: .utf8) else {
                XCTFail("Failed to convert modified JSON to Data")
                return
            }
            guard let offeringsResponse = try? JSONDecoder.default.decode(
                OfferingsResponse.self, from: modifiedData
            ) else {
                XCTFail("Failed to decode modified offerings data")
                return
            }

            // Read and decode or print contents
            guard let packagesData = try? Data(contentsOf: packagesPath) else {
                XCTFail("Couldn't parse packages data")
                return
            }
            guard let packages = try? JSONDecoder.default.decode(PackageData.self, from: packagesData) else {
                XCTFail("Failed to decode packages data")
                return
            }

            let offeringsWithPackages = offeringsResponse.offerings.map { offering in
                return OfferingsResponse.Offering(
                    identifier: offering.identifier,
                    description: offering.description,
                    packages: packages.packages,
                    paywallComponents: offering.paywallComponents,
                    draftPaywallComponents: offering.draftPaywallComponents,
                    webCheckoutUrl: offering.webCheckoutUrl
                )
            }

            let offeringsResponseWithPackages = OfferingsResponse(
                currentOfferingId: offeringsResponse.currentOfferingId,
                offerings: offeringsWithPackages,
                placements: offeringsResponse.placements,
                targeting: offeringsResponse.targeting,
                uiConfig: offeringsResponse.uiConfig
            )

            let offerings = OfferingsFactory().createOfferings(from: [
                "com.revenuecat.lifetime_product": .init(sk1Product: PreviewMock.Product(
                    price: 1.99,
                    unit: .week,
                    localizedTitle: "Lifeime"
                )),
                "com.revenuecat.annual_product": .init(sk1Product: PreviewMock.Product(
                    price: 1.99,
                    unit: .year,
                    localizedTitle: "Annual"
                )),
                "com.revenuecat.semester_product": .init(sk1Product: PreviewMock.Product(
                    price: 1.99,
                    unit: .month,
                    localizedTitle: "6 Month"
                )),
                "com.revenuecat.quarterly_product": .init(sk1Product: PreviewMock.Product(
                    price: 1.99,
                    unit: .week,
                    localizedTitle: "3 Month"
                )),
                "com.revenuecat.bimonthly_product": .init(sk1Product: PreviewMock.Product(
                    price: 1.99,
                    unit: .week,
                    localizedTitle: "2 Month"
                )),
                "com.revenuecat.monthly_product": .init(sk1Product: PreviewMock.Product(
                    price: 1.99,
                    unit: .month,
                    localizedTitle: "Monthly"
                )),
                "com.revenuecat.weekly_product": .init(sk1Product: PreviewMock.Product(
                    price: 1.99,
                    unit: .week,
                    localizedTitle: "Weekly"
                ))
            ], data: offeringsResponseWithPackages)

            for offeringId in offerings!.all.keys {
                let offering = offerings!.all[offeringId]!

                if offering.paywallComponents != nil {
                    let view = Self.createPaywall(offering: offering)
                        .frame(width: 450, height: 1000)
                    self.snapshotAndSave(view: view,
                                         size: CGSize(width: 450, height: 1000),
                                         filename: "\(offeringId)__END.png",
                                         template: offeringId)
                }
            }
        }
    }

    func clearContentsOfDirectory(at url: URL) throws {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)

        for item in contents {
            try fileManager.removeItem(at: item)
        }
    }

    func snapshotAndSave<V: View>(view: V, size: CGSize, filename: String, template: String) {
        let image = view.asImage(wait: 1).resized(toWidth: size.width)

        // Save PNG data
        if let pngData = image.pngData() {
            // 📎 Attach to test
            let attachment = XCTAttachment(data: pngData, uniformTypeIdentifier: "public.png")
            attachment.name = filename
            attachment.userInfo = ["template": template]
            attachment.lifetime = .keepAlways
            self.add(attachment)
        } else {
            print("❌ Failed to generate PNG data from image")
        }
    }

}

extension UIImage {
    func resized(toWidth width: CGFloat) -> UIImage {
        let scale = width / self.size.width
        let height = self.size.height * scale
        let newSize = CGSize(width: width, height: height)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1  // Force actual pixel size
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)

        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

extension View {

  func asImage(wait duration: TimeInterval = 0.1) -> UIImage {

    let controller = UIHostingController(rootView: self)
    let view = controller.view
    let targetSize = controller.view.intrinsicContentSize
    let bounds = CGRect(origin: .zero, size: targetSize)

    let window = UIWindow(frame: bounds)

    window.rootViewController = controller
    window.makeKeyAndVisible()

    view?.bounds = bounds
    view?.backgroundColor = .clear

    // 💡 Wait for SwiftUI rendering to complete
    RunLoop.main.run(until: Date().addingTimeInterval(duration))

    let image = controller.view.asImage()

    return image
  }
}

extension UIView {
  func asImage() -> UIImage {
    let renderer = UIGraphicsImageRenderer(bounds: bounds)
    return renderer.image { rendererContext in
        drawHierarchy(in: bounds, afterScreenUpdates: true)
    }
  }
}

#endif
