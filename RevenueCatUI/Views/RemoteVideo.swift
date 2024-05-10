//
//  File.swift
//  
//
//  Created by Andrés Boedo on 5/10/24.
//

import Foundation
import SwiftUI
import AVKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct RemoteVideo: View {
    var videoURL: URL
    @State private var player = AVPlayer()
    
    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                prepareVideoPlayer()
            }
            .edgesIgnoringSafeArea(.all)
    }
    
    private func prepareVideoPlayer() {
        let asset = AVURLAsset(url: videoURL)
        let keys = ["playable", "hasProtectedContent", "preferredTransform"]
        
        asset.loadValuesAsynchronously(forKeys: keys) {
            var error: NSError?
            for key in keys {
                let status = asset.statusOfValue(forKey: key, error: &error)
                if status == .failed {
                    print("Error loading \(key): \(String(describing: error))")
                    return
                }
            }
            
            // Check if the asset is playable
            if asset.isPlayable {
                DispatchQueue.main.async {
                    self.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
                    self.player.play()  // Autoplay once the player is set up
                }
            }
        }
    }
}
