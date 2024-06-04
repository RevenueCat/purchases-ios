// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import RevenueCat

public struct TestView: View {

    public init() { }

    public var body: some View {
        let text = RCMessages.message()
        Text("\(text)")
    }
}
