//
//  SampleChart.swift
//  SimpleApp
//
//  Created by Nacho Soto on 7/17/23.
//

import SwiftUI

struct BarChartView: View {

    let data: [Double]
    let color: Color

    private let maxValue: Double

    init(data: [Double], color: Color = .blue) {
        self.data = data
        self.color = color
        self.maxValue = data.max() ?? 0
    }

    var body: some View {
        HStack(alignment: .bottom) {
            ForEach(self.data, id: \.self) { value in
                BarView(value: value,
                        maxValue: self.maxValue,
                        color: self.color)
            }
        }
    }

}

private struct BarView: View {

    let value: Double
    let maxValue: Double
    let color: Color

    var body: some View {
        VStack {
            Rectangle()
                .fill(self.color)
                .frame(width: 30, height: CGFloat(self.value / self.maxValue) * 120)

            Text(String(Int(self.value)))
                .font(.caption)
        }
    }

}

struct ContentView_Previews: PreviewProvider {

    static var previews: some View {
        BarChartView(data: [12, 6, 10, 8, 15, 9])
    }

}
