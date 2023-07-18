//
//  SampleChart.swift
//  SimpleApp
//
//  Created by Nacho Soto on 7/17/23.
//

import SwiftUI

struct BarChartView: View {
    let data: [Double]
    private let maxValue: Double

    init(data: [Double]) {
        self.data = data
        self.maxValue = data.max() ?? 0
    }

    var body: some View {
        HStack(alignment: .bottom) {
            ForEach(self.data, id: \.self) { value in
                BarView(value: value, maxValue: self.maxValue)
            }
        }
    }
}

private struct BarView: View {
    let value: Double
    let maxValue: Double

    var body: some View {
        VStack {
            Rectangle()
                .fill(.blue)
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
