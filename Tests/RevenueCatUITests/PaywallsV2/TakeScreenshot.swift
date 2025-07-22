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

    func testPaywallValidationScreenshots() throws {
        let bundle = Bundle(for: Self.self)

        guard let resourcesFolderURL = bundle.url(
            forResource: "paywall-preview-resources", withExtension: nil
        ) else {
            XCTFail("Could not locate paywall-preview-resources")
            return
        }

        let baseResourcesURL = resourcesFolderURL
            .appendingPathComponent("resources")

        let paywallPreviewsResourceLoader = try PaywallPreviewResourcesLoader(baseResourcesURL: baseResourcesURL)

        for offering in paywallPreviewsResourceLoader.allOfferings {
            let offeringId = offering.id

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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

  func asImage(wait duration: TimeInterval = 0.1) -> UIImage {

    let controller = UIHostingController(rootView: self.ignoresSafeArea())
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
    return renderer.image { _ in
        drawHierarchy(in: bounds, afterScreenUpdates: true)
    }
  }
}

#endif
