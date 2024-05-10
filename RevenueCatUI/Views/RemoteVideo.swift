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
    let videoURL: URL

    var body: some View {
        VideoPlayer(player: AVPlayer(url: videoURL))
            .onAppear {
                // Optionally, start playing the video automatically
                AVPlayer(url: videoURL).play()
            }
            .edgesIgnoringSafeArea(.all)
    }
}
