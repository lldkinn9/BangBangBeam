import SwiftUI

/// 戦闘開始前の「事前画面（VS画面）」オーバーレイ（対戦相手によって名前・立ち絵が動的に変化）
struct PreBattleVsOverlayView: View {
    let enemy: CharacterProfile
    let stageLabel: String
    let winStreak: Int

    @State private var animateIn: Bool = false

    private let neonMagenta = Color(red: 0.95, green: 0.18, blue: 0.82)
    private let neonPurple = Color(red: 0.68, green: 0.22, blue: 0.96)

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // 1. ベース背景（サイバー都市暗色＋3Dパースペクティブグリッド）
                Color.cyberBlack
                    .ignoresSafeArea()

                BattlePerspectiveGridView(gridColor: Color.cyberCyan.opacity(0.22))
                    .ignoresSafeArea()

                // 2. 斜め分割の背景ネオンフィールド（右上＝敵マゼンタ領域、左下＝Reoシアン/エメラルド領域）
                Canvas { context, size in
                    let sw = size.width
                    let sh = size.height

                    // 右上：敵キャラ側のマゼンタ発光ポリゴン
                    var topPoly = Path()
                    topPoly.move(to: CGPoint(x: sw * 0.66, y: 0))
                    topPoly.addLine(to: CGPoint(x: sw, y: 0))
                    topPoly.addLine(to: CGPoint(x: sw, y: sh * 0.43))
                    topPoly.addLine(to: CGPoint(x: sw * 0.46, y: sh * 0.52))
                    topPoly.closeSubpath()

                    context.fill(
                        topPoly,
                        with: .linearGradient(
                            Gradient(colors: [
                                neonMagenta.opacity(0.62),
                                neonPurple.opacity(0.28),
                                Color.clear
                            ]),
                            startPoint: CGPoint(x: sw * 0.85, y: sh * 0.18),
                            endPoint: CGPoint(x: sw * 0.35, y: sh * 0.52)
                        )
                    )

                    // 左下：Reo側のエメラルド／シアン発光ポリゴン
                    var bottomPoly = Path()
                    bottomPoly.move(to: CGPoint(x: 0, y: sh * 0.56))
                    bottomPoly.addLine(to: CGPoint(x: sw * 0.52, y: sh * 0.48))
                    bottomPoly.addLine(to: CGPoint(x: sw * 0.33, y: sh))
                    bottomPoly.addLine(to: CGPoint(x: 0, y: sh))
                    bottomPoly.closeSubpath()

                    context.fill(
                        bottomPoly,
                        with: .linearGradient(
                            Gradient(colors: [
                                Color.cyberEmerald.opacity(0.55),
                                Color.cyberCyan.opacity(0.32),
                                Color.clear
                            ]),
                            startPoint: CGPoint(x: sw * 0.18, y: sh * 0.78),
                            endPoint: CGPoint(x: sw * 0.62, y: sh * 0.48)
                        )
                    )
                }
                .ignoresSafeArea()

                // 3. 右上：対戦相手キャラクター立ち絵（斜め境界でクリップ）
                ZStack {
                    Image(enemy.standingAsset(for: .normal))
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(w * 0.64, 260), height: min(h * 0.44, 340))
                        .shadow(color: neonMagenta.opacity(0.85), radius: 18)
                        .position(x: w * 0.74, y: h * 0.24)
                        .offset(x: animateIn ? 0 : 90, y: animateIn ? 0 : -30)
                }
                .clipShape(UpperRightVsClipShape())

                // 4. 左下：主人公 REO 立ち絵（斜め境界でクリップ）
                ZStack {
                    Image(CharacterProfile.reo.standingAsset(for: .normal))
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(w * 0.64, 260), height: min(h * 0.44, 340))
                        .shadow(color: Color.cyberCyan.opacity(0.85), radius: 18)
                        .position(x: w * 0.27, y: h * 0.77)
                        .offset(x: animateIn ? 0 : -90, y: animateIn ? 0 : 30)
                }
                .clipShape(LowerLeftVsClipShape())

                // 5. 斜めに走るバチバチ稲妻エフェクト＆スパーク粒子
                VsDiagonalLightningEffectView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                // 6. 左上：敵ネームプレート枠（対戦相手に応じて動的に表示）
                VStack(alignment: .leading, spacing: 4) {
                    ZStack(alignment: .leading) {
                        CyberShape(cutSize: 14)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.22, green: 0.04, blue: 0.28).opacity(0.92),
                                        Color(red: 0.10, green: 0.02, blue: 0.16).opacity(0.88)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        CyberShape(cutSize: 14)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [neonMagenta, neonPurple, neonMagenta.opacity(0.65)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.2
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("////// \(stageLabel)")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(neonMagenta.opacity(0.85))
                                Spacer()
                            }

                            Text(enemy.codeName)
                                .font(.system(size: 40, weight: .black, design: .rounded))
                                .tracking(2)
                                .foregroundStyle(.white)
                                .shadow(color: neonMagenta, radius: 10)
                                .shadow(color: neonMagenta, radius: 20)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                    }
                    .frame(width: min(w * 0.56, 224), height: 108)
                    .shadow(color: neonMagenta.opacity(0.65), radius: 14)

                    Text("WIN STREAK: \(winStreak)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(neonMagenta.opacity(0.75))
                        .padding(.leading, 6)
                }
                .position(x: w * 0.31, y: h * 0.12)
                .offset(x: animateIn ? 0 : -60)

                // 7. 右下：REO (YOU) ネームプレート枠
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { _ in
                            Capsule()
                                .fill(Color.cyberCyan.opacity(0.75))
                                .frame(width: 8, height: 3)
                        }
                    }
                    .padding(.trailing, 8)

                    ZStack {
                        CyberShape(cutSize: 14)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.02, green: 0.18, blue: 0.25).opacity(0.92),
                                        Color(red: 0.01, green: 0.10, blue: 0.16).opacity(0.88)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        CyberShape(cutSize: 14)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.cyberCyan, Color.cyberEmerald, Color.cyberCyan.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.2
                            )

                        VStack(spacing: 0) {
                            Text("REO")
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .tracking(2)
                                .foregroundStyle(.white)
                                .shadow(color: Color.cyberCyan, radius: 10)
                                .shadow(color: Color.cyberCyan, radius: 18)

                            Text("(YOU)")
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .tracking(1.5)
                                .foregroundStyle(.white)
                                .shadow(color: Color.cyberCyan, radius: 8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .frame(width: min(w * 0.50, 200), height: 118)
                    .shadow(color: Color.cyberCyan.opacity(0.65), radius: 14)
                }
                .position(x: w * 0.72, y: h * 0.86)
                .offset(x: animateIn ? 0 : 60)

                // 8. 中央「VS」ネオンエンブレム
                VsCenterEmblemView()
                    .scaleEffect(animateIn ? 1.0 : 1.45)
                    .opacity(animateIn ? 1.0 : 0.0)
                    .position(x: w * 0.50, y: h * 0.49)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.76)) {
                animateIn = true
            }
        }
    }
}

/// 右上（敵側）の斜めクリップ形状
private struct UpperRightVsClipShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.45))
        path.addLine(to: CGPoint(x: 0, y: rect.height * 0.57))
        path.closeSubpath()
        return path
    }
}

/// 左下（プレイヤー側）の斜めクリップ形状
private struct LowerLeftVsClipShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.44))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.36))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

/// 中央のネオン「VS」ロゴ描画（V＝マゼンタ発光、S＝シアン発光）
private struct VsCenterEmblemView: View {
    private let neonMagenta = Color(red: 0.96, green: 0.22, blue: 0.86)

    var body: some View {
        ZStack {
            // 中心の閃光フレア
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            neonMagenta.opacity(0.55),
                            Color.cyberCyan.opacity(0.45),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 95
                    )
                )
                .frame(width: 190, height: 190)

            HStack(spacing: -14) {
                // V（マゼンタ・パープルネオン）
                ZStack {
                    Text("V")
                        .font(.system(size: 96, weight: .black, design: .rounded))
                        .italic()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, neonMagenta, Color(red: 0.55, green: 0.12, blue: 0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: neonMagenta, radius: 12)
                        .shadow(color: neonMagenta, radius: 24)
                }
                .offset(y: -8)

                // S（シアン・ブルーネオン）
                ZStack {
                    Text("S")
                        .font(.system(size: 96, weight: .black, design: .rounded))
                        .italic()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.cyberCyan, Color(red: 0.12, green: 0.38, blue: 0.92)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.cyberCyan, radius: 12)
                        .shadow(color: Color.cyberCyan, radius: 24)
                }
                .offset(y: 8)
            }
        }
    }
}

/// 斜めに走るマゼンタ＆シアンの稲妻エフェクト
private struct VsDiagonalLightningEffectView: View {
    private let neonMagenta = Color(red: 0.96, green: 0.22, blue: 0.86)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            let tick = Int(timeline.date.timeIntervalSinceReferenceDate * 24.0)

            Canvas { context, size in
                let w = size.width
                let h = size.height
                guard w > 20, h > 20 else { return }

                // 1. 右上(67%, 0%) → 中央(50%, 49%) → 左下(33%, 100%) のメイン稲妻
                drawLightningBolt(
                    context: &context,
                    from: CGPoint(x: w * 0.67, y: 0),
                    to: CGPoint(x: w * 0.50, y: h * 0.49),
                    seed: tick &* 17,
                    glowColor: neonMagenta,
                    jitter: 14
                )

                drawLightningBolt(
                    context: &context,
                    from: CGPoint(x: w * 0.50, y: h * 0.49),
                    to: CGPoint(x: w * 0.33, y: h),
                    seed: tick &* 29 + 7,
                    glowColor: Color.cyberCyan,
                    jitter: 14
                )

                // 2. 左中(0%, 56%) → 中央 → 右中(100%, 42%) のクロス稲妻
                drawLightningBolt(
                    context: &context,
                    from: CGPoint(x: 0, y: h * 0.56),
                    to: CGPoint(x: w * 0.50, y: h * 0.49),
                    seed: tick &* 43 + 19,
                    glowColor: Color.cyberCyan,
                    jitter: 10
                )

                drawLightningBolt(
                    context: &context,
                    from: CGPoint(x: w * 0.50, y: h * 0.49),
                    to: CGPoint(x: w, y: h * 0.42),
                    seed: tick &* 61 + 31,
                    glowColor: neonMagenta,
                    jitter: 10
                )
            }
        }
    }

    private func drawLightningBolt(
        context: inout GraphicsContext,
        from start: CGPoint,
        to end: CGPoint,
        seed: Int,
        glowColor: Color,
        jitter: CGFloat
    ) {
        var path = Path()
        path.move(to: start)
        let steps = 10
        for i in 1..<steps {
            let t = CGFloat(i) / CGFloat(steps)
            let bx = start.x + (end.x - start.x) * t
            let by = start.y + (end.y - start.y) * t
            let h = abs((seed &* (i + 5) &* 1103515245 + 12345) % 100)
            let offset = (CGFloat(h) / 100.0 - 0.5) * 2.0 * jitter
            path.addLine(to: CGPoint(x: bx + offset, y: by - offset * 0.4))
        }
        path.addLine(to: end)

        context.stroke(path, with: .color(glowColor.opacity(0.65)), lineWidth: 7.0)
        context.stroke(path, with: .color(glowColor), lineWidth: 3.2)
        context.stroke(path, with: .color(.white), lineWidth: 1.4)
    }
}

/// バトル画面・事前VS画面共通の3Dパースペクティブ・サイバーグリッド背景
struct BattlePerspectiveGridView: View {
    var gridColor: Color = Color.cyberCyan.opacity(0.24)

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let horizonY = h * 0.36
            let bottomY = h * 0.72
            let centerX = w * 0.5

            // 水平パースライン（奥ほど密、手前ほど広く）
            let hRows = 9
            for r in 0...hRows {
                let norm = CGFloat(r) / CGFloat(hRows)
                let y = horizonY + pow(norm, 1.45) * (bottomY - horizonY)
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                line.addLine(to: CGPoint(x: w, y: y))
                context.stroke(
                    line,
                    with: .color(gridColor.opacity(0.25 + Double(norm) * 0.55)),
                    lineWidth: 0.9
                )
            }

            // 放射パースライン（消失点から手前へ広がるグリッド線）
            let vCols = 10
            for c in -vCols...vCols {
                let topX = centerX + CGFloat(c) * (w * 0.065)
                let botX = centerX + CGFloat(c) * (w * 0.22)
                var line = Path()
                line.move(to: CGPoint(x: topX, y: horizonY))
                line.addLine(to: CGPoint(x: botX, y: bottomY))
                context.stroke(line, with: .color(gridColor.opacity(0.45)), lineWidth: 0.85)
            }
        }
    }
}
