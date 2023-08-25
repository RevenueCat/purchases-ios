//
//  CustomPaywallContent.swift
//  SimpleApp
//
//  Created by Nacho Soto on 8/25/23.
//


import SwiftUI

struct CustomPaywallContent: View {

    @State private var rotation: Double = 0.0
    @State private var starOpacity: Double = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image("cat-picture")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .mask {
                    LinearGradient(colors: [.clear, .white, .white, .white, .clear],
                                   startPoint: .top,
                                   endPoint: .bottom)
                }
                .padding(.top, -60)
                .padding(.bottom, -80)

            HStack(spacing: 0) {
                Text("Pawwall")
                    .font(.system(.largeTitle, design: .rounded).bold())
                    .foregroundColor(Marketing.color5)
                    .padding(.leading)

                Text("Pro")
                    .font(.system(.largeTitle, design: .rounded).bold())

                Spacer(minLength: 0)

                Image(systemName: "star.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 30)
                    .rotationEffect(Angle(degrees: self.rotation))
                    .opacity(self.starOpacity)
                    .padding(.trailing, 24)
                    .onAppear {
                        withAnimation(.linear(duration: 30)
                            .repeatForever(autoreverses: false)) {
                                self.rotation = 360.0
                            }
                        withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                            self.starOpacity = 0.75
                        }
                    }
            }
            .shadow(radius: 10)

            Text("Get your paws on all the great premium features of Pawall Pro! 😻")
                .padding(.horizontal)

            Text("Premium features")
                .font(.headline)
                .padding(.top, 16)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    self.feature(icon: "dollarsign",
                                 name: "Make more money!")
                    self.feature(icon: "figure.run",
                                 name: "Do it fast!")
                    self.feature(icon: "bolt.fill",
                                 name: "Zap the competition")
                    self.feature(icon: "square.fill",
                                 name: "WALLS!")
                }
                .padding(.horizontal)
            }

            Text("What others are saying")
                .font(.headline)
                .padding(.top, 16)
                .padding(.horizontal)

            self.testimonial(name: "Garfield",
                             review: "Five stars for this paywall builder app, because let's face it, lasagna isn't free and neither are my naps – it helps me monetize both with style!")
            self.testimonial(name: "Tom",
                             review: "This paywall builder app is a game-changer in my pursuit of Jerry. With its cunning customization, I'm closer than ever to catching that elusive mouse!")
            self.testimonial(name: "Tony",
                             review: "It's grrreat for locking up premium content behind paywalls. A real frosted flakes of a deal!")
        }
        .foregroundColor(.white)
    }

    private func feature(icon: String, name: String) -> some View {
        VStack(alignment: .center) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.white)
                .frame(height: 40)
            Spacer(minLength: 0)
            Text(name)
                .font(.subheadline)
                .bold()
                .multilineTextAlignment(.center)
        }
        .padding(2)
        .frame(width: 90, height: 90)
        .padding()
        .background(LinearGradient(colors: [Marketing.color2, Marketing.color1],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing))
        .foregroundColor(Marketing.color5)
        .mask {
            RoundedRectangle(cornerSize: .init(width: 10, height: 10), style: .continuous)
        }
    }

    private func testimonial(name: String, review: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("⭐️⭐️⭐️⭐️⭐️")
                    .font(.callout)

                Spacer(minLength: 8)

                Text(name)
                    .bold()
            }

            Text(review)
                .font(.callout)

            Spacer(minLength: 0)
        }
        .frame(height: 119)
        .padding()
        .background(LinearGradient(colors: [Marketing.color5, Marketing.color4.opacity(0.8)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
        .foregroundColor(Marketing.color1)
        .mask {
            RoundedRectangle(cornerSize: .init(width: 10, height: 10), style: .continuous)
        }
        .padding(.horizontal)
    }

    static let backgroundColor = Marketing.color3

}

private enum Marketing {

    static let color1 = Color(red: 0.004, green: 0.067, blue: 0.149)
    static let color2 = Color(red: 0.039, green: 0.231, blue: 0.349)
    static let color3 = Color(red: 0.318, green: 0.463, blue: 0.549)
    static let color4 = Color(red: 0.584, green: 0.686, blue: 0.749)
    static let color5 = Color(red: 0.69, green: 0.804, blue: 0.851)

}

