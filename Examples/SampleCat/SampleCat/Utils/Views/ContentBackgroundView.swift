//
//  ContentBackgroundView.swift
//  SampleCat
//
//  Created by Hidde van der Ploeg on 15/4/25.
//

import SwiftUI

struct ContentBackgroundView: View {
    let color: Color
    var body: some View {
        ZStack {
            LinearGradient(colors: [
                color.opacity(0.15   ),
                color.opacity(0)
            ], startPoint: .top, endPoint: .bottom)
            PatternBackground()
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentBackgroundView(color: .accent)
}

struct PatternBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(patternImage: UIImage(named: "noise-pattern")!)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

