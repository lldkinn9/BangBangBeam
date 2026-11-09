import SwiftUI

/// 体力（HP = 3）をネオン発光ハートで可視化するコンポーネント
struct HealthBarView: View {
    let currentHP: Int
    let maxHP: Int
    var accentColor: Color = .cyberEmerald
    var heartSize: CGFloat = 18

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<maxHP, id: \.self) { index in
                let alive = index < currentHP
                ZStack {
                    if alive {
                        Image(systemName: "heart.fill")
                            .font(.system(size: heartSize, weight: .bold))
                            .foregroundStyle(accentColor)
                            .shadow(color: accentColor, radius: 6)
                            .shadow(color: accentColor.opacity(0.7), radius: 12)

                        Image(systemName: "heart")
                            .font(.system(size: heartSize, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.85))
                    } else {
                        Image(systemName: "heart")
                            .font(.system(size: heartSize, weight: .semibold))
                            .foregroundStyle(accentColor.opacity(0.28))
                    }
                }
                .scaleEffect(alive ? 1.0 : 0.88)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: currentHP)
            }
        }
    }
}

/// チャージ（0〜4個）を縦型バッテリーセルで可視化し、4つ溜まった時点で全セルが黄色く発光＋電気エフェクトが走るコンポーネント
struct EnergyOrbView: View {
    let label: String
    let currentCharge: Int
    let maxCharge: Int
    var accentColor: Color = .cyberCyan
    var showLabel: Bool = false
    var cellWidth: CGFloat = 17
    var cellHeight: CGFloat = 26

    @State private var isUltPulsing: Bool = false

    var body: some View {
        let isUltReady = currentCharge >= maxCharge

        HStack(spacing: 8) {
            if showLabel && !label.isEmpty {
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.68))
            }

            ZStack {
                HStack(spacing: 7) {
                    ForEach(0..<maxCharge, id: \.self) { index in
                        let isFilled = index < currentCharge
                        BatteryCellView(
                            isFilled: isFilled,
                            isUltReady: isUltReady,
                            isPulsing: isUltPulsing,
                            accentColor: accentColor,
                            cellWidth: cellWidth,
                            cellHeight: cellHeight
                        )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 3)

                // 4チャージ到達時：全4セルの周囲に走る稲妻・電気エフェクトアニメーション
                if isUltReady {
                    ElectricChargeEffectOverlay()
                        .allowsHitTesting(false)
                }
            }
        }
        .onChange(of: isUltReady, initial: true) { _, ready in
            if ready {
                withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                    isUltPulsing = true
                }
            } else {
                isUltPulsing = false
            }
        }
    }
}

/// 1つ分の縦型サイバーバッテリーセル描画
private struct BatteryCellView: View {
    let isFilled: Bool
    let isUltReady: Bool
    let isPulsing: Bool
    let accentColor: Color
    let cellWidth: CGFloat
    let cellHeight: CGFloat

    var body: some View {
        let activeColor: Color = isUltReady
            ? Color(red: 1.0, green: 0.90, blue: 0.18)
            : accentColor

        VStack(spacing: 1.5) {
            // バッテリー上部端子突起
            RoundedRectangle(cornerRadius: 1.5)
                .fill(
                    isFilled
                        ? (isUltReady ? Color.white : activeColor.opacity(0.95))
                        : Color.white.opacity(0.18)
                )
                .frame(width: cellWidth * 0.46, height: 3)

            // バッテリー本体
            ZStack {
                RoundedRectangle(cornerRadius: 3.5)
                    .fill(Color.black.opacity(0.55))

                if isFilled {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(
                            LinearGradient(
                                colors: isUltReady
                                    ? [
                                        Color.white,
                                        Color(red: 1.0, green: 0.94, blue: 0.35),
                                        Color(red: 1.0, green: 0.76, blue: 0.08)
                                    ]
                                    : [
                                        Color.white.opacity(0.92),
                                        activeColor,
                                        activeColor.opacity(0.75)
                                    ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(2.2)
                }

                RoundedRectangle(cornerRadius: 3.5)
                    .strokeBorder(
                        isFilled
                            ? (isUltReady ? Color(red: 1.0, green: 0.96, blue: 0.55) : activeColor)
                            : Color.white.opacity(0.22),
                        lineWidth: isFilled ? (isUltReady ? 1.8 : 1.4) : 1.0
                    )
            }
            .frame(width: cellWidth, height: cellHeight)
        }
        .scaleEffect(isUltReady ? (isPulsing ? 1.06 : 0.98) : 1.0)
        .shadow(
            color: isFilled
                ? (isUltReady ? Color(red: 1.0, green: 0.86, blue: 0.15).opacity(0.95) : activeColor.opacity(0.8))
                : .clear,
            radius: isFilled ? (isUltReady ? (isPulsing ? 11 : 6) : 6) : 0
        )
    }
}

/// 4つ溜まったバッテリーゲージ全体にバチバチと走る黄色・白の放電稲妻アニメーション
private struct ElectricChargeEffectOverlay: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            let tick = Int(timeline.date.timeIntervalSinceReferenceDate * 20.0)

            Canvas { context, size in
                let w = size.width
                let h = size.height
                guard w > 10, h > 10 else { return }

                // 3本のランダム風シード稲妻アークを描画
                for boltIndex in 0..<3 {
                    var path = Path()
                    let seed = (tick &* 31 &+ boltIndex &* 97)
                    let startY = h * CGFloat(0.2 + Double((seed + 13) % 60) / 100.0)
                    path.move(to: CGPoint(x: 2, y: startY))

                    let segments = 6
                    for seg in 1...segments {
                        let x = (w - 4) * CGFloat(seg) / CGFloat(segments) + 2
                        let hash = abs((seed &* (seg + 3) &* 1103515245 + 12345) % 100)
                        let yOffset = (CGFloat(hash) / 100.0 - 0.5) * (h * 0.85)
                        let y = min(h - 1, max(1, (h * 0.5) + yOffset))
                        path.addLine(to: CGPoint(x: x, y: y))
                    }

                    // 外側の黄色い発光アーク
                    context.stroke(
                        path,
                        with: .color(Color(red: 1.0, green: 0.88, blue: 0.12).opacity(0.85)),
                        lineWidth: boltIndex == 0 ? 2.6 : 1.8
                    )
                    // 中心の白い電撃コア
                    context.stroke(
                        path,
                        with: .color(Color.white.opacity(0.95)),
                        lineWidth: boltIndex == 0 ? 1.2 : 0.8
                    )
                }

                // スパーク粒子
                for spark in 0..<5 {
                    let sHash = abs((tick &* 73 &+ spark &* 151) % 1000)
                    let sx = CGFloat(sHash % 100) / 100.0 * w
                    let sy = CGFloat((sHash / 10) % 100) / 100.0 * h
                    let r: CGFloat = (spark % 2 == 0) ? 2.2 : 1.5
                    let rect = CGRect(x: sx - r, y: sy - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(Color(red: 1.0, green: 0.95, blue: 0.5)))
                }
            }
            .shadow(color: Color(red: 1.0, green: 0.85, blue: 0.1), radius: 6)
        }
    }
}
