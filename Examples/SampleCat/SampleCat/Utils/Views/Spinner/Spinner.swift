import SwiftUI

struct Spinner: View {
    @State private var ballRotation: Double = 0
    @State private var yarnAngle: Double = 0
    @State private var yarnDirection: Double = 1

    let tint: Color

    init(tint: Color = .accent) {
        self.tint = tint
    }

    var body: some View {
        ZStack {
            YarnShape()
                .stroke(tint, lineWidth: 2)
                .rotationEffect(.degrees(yarnAngle), anchor: .trailing)

            BallShape()
                .fill(tint)
                .rotationEffect(.degrees(ballRotation), anchor: UnitPoint(x: 0.5, y: 0.51))
        }
        .frame(width: 40, height: 40)
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
