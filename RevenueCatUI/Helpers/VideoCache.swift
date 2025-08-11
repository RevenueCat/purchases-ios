//
//  VideoCache.swift
//
//
//  Created by Jacob Rakidzich on 8/11/25.
//

import Foundation

class VideoCache {
    static let shared = VideoCache()

    private let fileManager = FileManager.default
    private lazy var cacheDirectory: URL = {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[0]
    }()

    private func cacheUrl(for url: URL) -> URL {
        return cacheDirectory.appendingPathComponent(url.lastPathComponent)
    }

    func getVideoURL(for url: URL, completion: @escaping (URL?) -> Void) {
        let cachedUrl = cacheUrl(for: url)
        if fileManager.fileExists(atPath: cachedUrl.path) {
            completion(cachedUrl)
            return
        }

        downloadVideo(from: url) { data in
            if let data = data {
                try? data.write(to: cachedUrl)
                completion(cachedUrl)
            } else {
                completion(nil)
            }
        }
    }

    private func downloadVideo(from url: URL, completion: @escaping (Data?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            completion(data)
        }.resume()
    }
}
