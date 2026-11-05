import SwiftUI

/// 体力（HP = 3）をサイバーハート／シールドセルで可視化するコンポーネント
struct HealthBarView: View {
    let currentHP: Int
    let maxHP: Int
    var accentColor: Color = .cyberEmerald

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<maxHP, id: \.self) { index in
                let alive = index < currentHP
                Image(systemName: alive ? "heart.fill" : "heart.slash")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(alive ? accentColor : Color.white.opacity(0.2))
                    .shadow(color: alive ? accentColor.opacity(0.85) : .clear, radius: 5)
                    .scaleEffect(alive ? 1.0 : 0.88)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: currentHP)
            }
        }
    }
}

/// チャージ（0〜4個：4個満タンで一撃必殺解放）をオーブで可視化するコンポーネント
struct EnergyOrbView: View {
    let label: String
    let currentCharge: Int
    let maxCharge: Int
    var accentColor: Color = .cyberCyan

    var body: some View {
        let isUltReady = currentCharge >= maxCharge

        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.68))

            HStack(spacing: 6) {
                ForEach(0..<maxCharge, id: \.self) { index in
                    let isFilled = index < currentCharge
                    ZStack {
                        Circle()
                            .fill(
                                isFilled
                                    ? (isUltReady ? Color.cyberAmber : accentColor)
                                    : Color.white.opacity(0.08)
                            )
                            .frame(width: 14, height: 14)

                        Circle()
                            .strokeBorder(
                                isFilled
                                    ? Color.white.opacity(0.9)
                                    : accentColor.opacity(0.35),
                                lineWidth: isFilled ? 1.4 : 1.0
                            )
                            .frame(width: 14, height: 14)
                    }
                    .shadow(
                        color: isFilled
                            ? (isUltReady ? Color.cyberAmber.opacity(0.9) : accentColor.opacity(0.85))
                            : .clear,
                        radius: isFilled ? 6 : 0
                    )
                }
            }

            Text(isUltReady ? "MAX!" : "\(currentCharge)/\(maxCharge)")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(isUltReady ? Color.cyberAmber : accentColor)
        }
    }
}
