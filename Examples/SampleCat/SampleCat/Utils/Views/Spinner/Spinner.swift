import SwiftUI

struct Spinner: View {
    @State private var ballRotation: Double = 0
    @State private var yarnAngle: Double = 0
    @State private var yarnDirection: Double = 1
    
    var body: some View {
        ZStack {
            YarnShape()
                .stroke(Color.primary, lineWidth: 2)
                .rotationEffect(.degrees(yarnAngle), anchor: .trailing)
            
            BallShape()
                .fill(Color.primary)
                .rotationEffect(.degrees(ballRotation), anchor: UnitPoint(x: 0.5, y: 0.51))
        }
        .frame(width: 40, height: 40) // Scales from 16x16 viewBox
        .onAppear {
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                ballRotation = 360
            }
            
            Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
                Task {
                    await MainActor.run {
                        yarnAngle += yarnDirection * (2.0 / (0.8 * 60.0))
                        if abs(yarnAngle) >= 2 {
                            yarnDirection *= -1
                        }
                    }
                }
            }
        }
    }
}
