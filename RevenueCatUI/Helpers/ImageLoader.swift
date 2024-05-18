//
//  ImageLoader.swift
//
//
//  Created by Andrés Boedo on 11/29/23.
//
import Foundation
import RevenueCat

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

import SwiftUI

protocol URLSessionType {
    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

@MainActor
@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class ImageLoader: NSObject, ObservableObject  {

    enum Error: Swift.Error, Equatable {
        case responseError(NSError)
        case badResponse(URLError)
        case invalidImage
    }

    typealias Value = Result<Image, Error>

    @Published
    private(set) var result: Value? {
        didSet {
            if let result {
                Logger.verbose(Strings.image_result(result.map { _ in () }))
            }
        }
    }

    private var urlSession: URLSession!
    private var dataTask: URLSessionDataTask?
    private var receivedData = Data()

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    override convenience init() {
        self.init(urlSession: URLSession(configuration: .default, delegate: nil, delegateQueue: .main))
    }

    init(urlSession: URLSession) {
        super.init()
        let configuration = URLSessionConfiguration.default
        self.urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
    }


    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func load(url: URL) {
        Logger.verbose(Strings.image_starting_request(url))

        // Reset previous image before loading new one
        self.result = nil
        self.receivedData = Data()

        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        self.dataTask = self.urlSession.dataTask(with: request)
        self.dataTask?.resume()
    }

    private func appendData(_ data: Data) {
        self.receivedData.append(data)

        #if os(macOS)
        if let image = NSImage(data: self.receivedData) {
            self.result = .success(.init(nsImage: image))
        }
        #else
        if let image = UIImage(data: self.receivedData) {
            self.result = .success(.init(uiImage: image))
        }
        #endif
    }
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension ImageLoader: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        appendData(data)
    }

    // func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?)
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            self.result = .failure(.responseError(error as NSError))
        }
    }
}
