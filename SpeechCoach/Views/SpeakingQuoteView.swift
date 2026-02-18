//
//  SpeakingQuoteView.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import SwiftUI

/// Rotating motivational quotes shown during loading states
struct SpeakingQuoteView: View {
    @State private var currentIndex = Int.random(in: 0..<Self.quotes.count)
    @State private var opacity: Double = 1.0

    private let timer = Timer.publish(every: 7, on: .main, in: .common).autoconnect()

    var body: some View {
        Text("\"\(Self.quotes[currentIndex])\"")
            .font(.callout)
            .italic()
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 40)
            .opacity(opacity)
            .animation(.easeInOut(duration: 0.5), value: opacity)
            .onReceive(timer) { _ in
                withAnimation(.easeInOut(duration: 0.4)) {
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    currentIndex = (currentIndex + 1) % Self.quotes.count
                    withAnimation(.easeInOut(duration: 0.4)) {
                        opacity = 1
                    }
                }
            }
    }

    static let quotes: [String] = [
        "Speak clearly, if you speak at all; carve every word before you let it fall.",
        "The most powerful person in the world is the storyteller.",
        "Your voice is your most powerful instrument — tune it well.",
        "Brevity is the soul of wit.",
        "It's not what you say, it's how you say it.",
        "Great speakers are not born, they're coached.",
        "Silence is as important as the words you choose.",
        "A well-placed pause speaks louder than a hundred words.",
        "The best way to sound like you know what you're talking about is to know what you're talking about.",
        "Confidence is silent. Insecurities are loud.",
        "Words mean more when spoken with intention.",
        "Every great speech started as a rough draft.",
        "Clarity is kindness. Say what you mean.",
        "The audience doesn't know your script — own the moment.",
        "Progress, not perfection.",
    ]
}
