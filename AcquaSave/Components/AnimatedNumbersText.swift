//
//  AnimatedNumbersText.swift
//  AcquaSave
//
//  Created by Foundation 44 on 05/03/26.
//

import SwiftUI

struct AnimatedNumberText: View {
    let value: Double
    let formatter: (Double) -> String

    @State private var animatedValue: Double = 0

    var body: some View {
        Text(formatter(animatedValue))
            .monospacedDigit()
            .onAppear {
                animatedValue = value
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.easeInOut(duration: 0.45)) {
                    animatedValue = newValue
                }
            }
            .contentTransition(.numericText(value: animatedValue))
    }
}
