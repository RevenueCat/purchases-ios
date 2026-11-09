//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import AVFoundation
@_spi(Internal) import RevenueCat
@_spi(Internal) import RevenueCatUI
import SwiftUI

struct VideoCloseFixtureView: View {

    static let name = "video_close"

    @State private var offering: Offering?
    @State private var dismissed = false
    @State private var error: String?

    var body: some View {
        Group {
            if self.dismissed {
                Text("Paywall dismissed")
            } else if let offering {
                PaywallView(
                    offering: offering,
                    performPurchase: { _ in (userCancelled: true, error: nil) },
                    performRestore: { (success: false, error: nil) }
                )
                .onRequestedDismissal { self.dismissed = true }
            } else if let error {
                Text(error)
            } else {
                ProgressView()
            }
        }
        .task {
            do {
                let url = try await Self.makeVideo()
                self.offering = Self.makeOffering(videoURL: url)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private static func makeOffering(videoURL: URL) -> Offering {
        let base = PaywallFixture.sheetOverContent.offering
        let stack = PaywallComponent.StackComponent(
            components: [
                .button(.init(
                    action: .navigateBack,
                    stack: .init(
                        components: [.text(.init(text: "close", color: .init(light: .hex("#000000"))))],
                        size: .init(width: .fill, height: .fixed(64))
                    ),
                    useNativeIfPossible: false
                )),
                .video(.init(
                    source: .init(light: .init(
                        width: 320, height: 180, url: videoURL,
                        checksum: nil, urlLowRes: nil, checksumLowRes: nil
                    )),
                    showControls: true,
                    autoPlay: true,
                    loop: true,
                    muteAudio: true,
                    size: .init(width: .fill, height: .fit(nil)),
                    fitMode: .fit,
                    maskShape: ProcessInfo.processInfo.environment["VIDEO_CIRCLE_SHAPE"] == "1" ? .circle : nil
                ))
            ],
            dimension: .vertical(.center, .start),
            size: .init(width: .fill, height: .fill)
        )
        let data = PaywallComponentsData(
            templateName: Self.name,
            assetBaseURL: videoURL.deletingLastPathComponent(),
            componentsConfig: .init(base: .init(
                stack: stack, stickyFooter: nil, background: .color(.init(light: .hex("#ffffff")))
            )),
            componentsLocalizations: ["en_US": ["close": .string("Close")]],
            revision: 1, defaultLocaleIdentifier: "en_US"
        )
        return Offering(
            identifier: Self.name, serverDescription: "Video with Close button",
            paywallComponents: .init(uiConfig: base.paywallComponents!.uiConfig, data: data),
            availablePackages: base.availablePackages, webCheckoutUrl: nil
        )
    }

    private static func makeVideo() async throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("video-close.mp4")
        if FileManager.default.fileExists(atPath: url.path) { return url }
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 320,
            AVVideoHeightKey: 180
        ])
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? CocoaError(.fileWriteUnknown) }
        writer.startSession(atSourceTime: .zero)
        var buffer: CVPixelBuffer?
        guard CVPixelBufferCreate(kCFAllocatorDefault, 320, 180, kCVPixelFormatType_32ARGB, nil, &buffer)
                == kCVReturnSuccess, let buffer else {
            throw CocoaError(.fileWriteUnknown)
        }
        CVPixelBufferLockBaseAddress(buffer, [])
        memset(CVPixelBufferGetBaseAddress(buffer), 128, CVPixelBufferGetDataSize(buffer))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        for seconds in [0, 30] {
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 10_000_000)
            }
            guard adaptor.append(buffer, withPresentationTime: CMTime(seconds: Double(seconds), preferredTimescale: 1))
            else { throw writer.error ?? CocoaError(.fileWriteUnknown) }
        }
        input.markAsFinished()
        await writer.finishWriting()
        guard writer.status == .completed else { throw writer.error ?? CocoaError(.fileWriteUnknown) }
        return url
    }

}
