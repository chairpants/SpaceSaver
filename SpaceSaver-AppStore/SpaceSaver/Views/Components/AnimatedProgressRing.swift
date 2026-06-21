//
//  AnimatedProgressRing.swift
//  SpaceSaver
//
//  An improved progress ring with gradient and smooth animations.
//

import SwiftUI

/// An animated progress ring with gradient stroke and smooth entrance
struct AnimatedProgressRing: View {
    let percentage: Double
    let availableBytes: Int64
    var size: CGFloat = 160
    var lineWidth: CGFloat = 20

    @State private var animatedPercentage: Double = 0

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)

            // Progress arc with gradient
            Circle()
                .trim(from: 0, to: animatedPercentage)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: ringColors),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: ringColors[1].opacity(0.3), radius: 4, x: 0, y: 2)

            // Center content
            VStack(spacing: 4) {
                Text(formattedAvailable)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(primaryRingColor)

                Text("Available")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                animatedPercentage = percentage
            }
        }
        .onChange(of: percentage) { newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedPercentage = newValue
            }
        }
    }

    // MARK: - Helpers

    private var ringColors: [Color] {
        switch percentage {
        case ..<0.7:
            return [.mint, .green]
        case 0.7..<0.9:
            return [.yellow, .orange]
        default:
            return [.orange, .red]
        }
    }

    private var primaryRingColor: Color {
        switch percentage {
        case ..<0.7:  return .green
        case 0.7..<0.9: return .orange
        default:      return .red
        }
    }

    private var formattedAvailable: String {
        FileSizeFormatter.string(fromBytes: availableBytes)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 32) {
        AnimatedProgressRing(percentage: 0.45, availableBytes: 250_000_000_000, size: 160)
        AnimatedProgressRing(percentage: 0.75, availableBytes: 120_000_000_000, size: 160)
        AnimatedProgressRing(percentage: 0.92, availableBytes: 30_000_000_000, size: 160)
    }
    .padding()
}
