import SwiftUI

/// 気力（Charge）0〜5個をオーブで可視化するコンポーネント
struct EnergyOrbView: View {
    let label: String
    let currentCharge: Int
    let maxCharge: Int
    var accentColor: Color = .cyberCyan

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.72))

            HStack(spacing: 8) {
                ForEach(0..<maxCharge, id: \.self) { index in
                    let isFilled = index < currentCharge
                    let isMegaReady = currentCharge >= 2 && isFilled

                    ZStack {
                        Circle()
                            .fill(
                                isFilled
                                    ? (isMegaReady ? Color.cyberAmber : accentColor)
                                    : Color.white.opacity(0.08)
                            )
                            .frame(width: 16, height: 16)

                        Circle()
                            .strokeBorder(
                                isFilled
                                    ? Color.white.opacity(0.9)
                                    : accentColor.opacity(0.35),
                                lineWidth: isFilled ? 1.5 : 1.0
                            )
                            .frame(width: 16, height: 16)
                    }
                    .shadow(
                        color: isFilled
                            ? (isMegaReady ? Color.cyberAmber.opacity(0.85) : accentColor.opacity(0.85))
                            : .clear,
                        radius: isFilled ? 6 : 0
                    )
                    .scaleEffect(isFilled ? 1.08 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.65), value: currentCharge)
                }
            }

            Text("\(currentCharge)/\(maxCharge)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(currentCharge >= 2 ? Color.cyberAmber : accentColor)
        }
    }
}

