import SwiftUI

/// 戦闘開始前の「事前画面（VS画面）」オーバーレイ
/// - 1枚目（背景のみ `vs_screen_bg`）→ 0.42秒後にSE（`vs_appear.mp3`）＆画面シェイクとともに2枚目（キャラ立ち絵＆名称挿入）へ切替
/// - キャラ表示から1.0秒後に中央「VS」の下へサイバー「START」ボタンを表示し、タップされるまでサイバー演出・揺れを伴う待機状態を維持
struct PreBattleVsOverlayView: View {
    let enemy: CharacterProfile
    let stageLabel: String
    let winStreak: Int
    var isHapticsEnabled: Bool = true
    var onStartTapped: () -> Void = {}

    /// false = 添付1枚目の状態（ベース背景のみ）、true = 添付2枚目の状態（キャラ立ち絵＆名称が挿入された状態）
    @State private var isCharacterInserted: Bool = false
    /// キャラ表示から1秒後に表示される「START」ボタンの可視状態
    @State private var isStartButtonVisible: Bool = false
    /// キャラ挿入瞬間のネオンフラッシュ不透明度
    @State private var flashOpacity: Double = 0.0
    /// キャラ挿入瞬間（着地インパクト）のタイムスタンプ（画面シェイク減衰計算用）
    @State private var impactDate: Date? = nil
    /// STARTボタン連打防止フラグ
    @State private var hasTriggeredStart: Bool = false

    private let neonMagenta = Color(red: 0.98, green: 0.22, blue: 0.88)
    private let neonCyan = Color(red: 0.20, green: 0.95, blue: 1.00)

    var body: some View {
        ZStack {
            // iPhone最上部のステータスバー領域（時計・電波・バッテリー残量）の背面のみ黒で塗りつぶし、UI本体はその下に配置
            Color.black
                .ignoresSafeArea()

            GeometryReader { geo in
                let screenW = max(geo.size.width, 1)
                let screenH = max(geo.size.height, 1)

            // どの機種（9:19.5の最新iPhone〜iPad）でも左右のネーム枠が1pxも見切れないよう画面幅・画面高に100%フィット
            let canvasW = screenW
            let canvasH = screenH

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let shake = computeScreenOffset(now: timeline.date, rawTime: now)
                let enemyFloatY = isCharacterInserted ? CGFloat(sin(now * 2.7)) * 4.5 : 0
                let playerFloatY = isCharacterInserted ? CGFloat(-sin(now * 2.7)) * 4.5 : 0
                let breathScale = isCharacterInserted ? (1.0 + CGFloat(sin(now * 2.7)) * 0.012) : 1.0
                // 周期的なサイバーグリッチ微振動
                let glitchTick = Int(now * 16.0)
                let isGlitchFrame = isCharacterInserted && (glitchTick % 23 == 0 || glitchTick % 37 == 0)
                let glitchShiftX: CGFloat = isGlitchFrame ? ((glitchTick % 2 == 0) ? 3.5 : -3.5) : 0

                ZStack {
                    Color.black
                        .ignoresSafeArea()

                    // MARK: 画面全体を揺らす・動かすメインVSステージ
                    ZStack {
                        // 1. ベース背景（添付1枚目：空の左上マゼンタ枠・右下シアン枠・稲妻・中央VSロゴ）
                        Image("vs_screen_bg")
                            .resizable()
                            .interpolation(.high)
                            .frame(width: canvasW, height: canvasH)

                        // 2. 右上：対戦相手キャラクター立ち絵（スライドイン＋待機中フローティング＆呼吸アニメーション）
                        ZStack {
                            Image(enemy.standingAsset(for: .normal))
                                .resizable()
                                .interpolation(.high)
                                .scaledToFit()
                                .frame(height: canvasH * 0.70)
                                .shadow(color: neonMagenta.opacity(0.75), radius: 14)
                                .scaleEffect(isCharacterInserted ? breathScale : 1.08)
                                .position(
                                    x: canvasW * 0.81 + glitchShiftX * 0.5,
                                    y: canvasH * 0.388 + enemyFloatY
                                )
                                .offset(
                                    x: isCharacterInserted ? 0 : canvasW * 0.25,
                                    y: isCharacterInserted ? 0 : -canvasH * 0.04
                                )
                                .opacity(isCharacterInserted ? 1.0 : 0.0)
                        }
                        .frame(width: canvasW, height: canvasH)
                        .clipShape(UpperRightVsEnemyClipShape())

                        // 3. 左下：主人公 REO 立ち絵（スライドイン＋待機中フローティング＆呼吸アニメーション）
                        ZStack {
                            Image(CharacterProfile.reo.standingAsset(for: .normal))
                                .resizable()
                                .interpolation(.high)
                                .scaledToFit()
                                .frame(height: canvasH * 0.81)
                                .shadow(color: neonCyan.opacity(0.75), radius: 14)
                                .scaleEffect(isCharacterInserted ? breathScale : 1.08)
                                .position(
                                    x: canvasW * 0.23 - glitchShiftX * 0.5,
                                    y: canvasH * 0.942 + playerFloatY
                                )
                                .offset(
                                    x: isCharacterInserted ? 0 : -canvasW * 0.25,
                                    y: isCharacterInserted ? 0 : canvasH * 0.04
                                )
                                .opacity(isCharacterInserted ? 1.0 : 0.0)
                        }
                        .frame(width: canvasW, height: canvasH)
                        .clipShape(LowerLeftVsPlayerClipShape())

                        // 4. 前景オーバーレイ（中央「VS」ロゴと斜め稲妻がキャラ境界の手前に重なるレイヤー）
                        Image("vs_screen_fg")
                            .resizable()
                            .interpolation(.high)
                            .frame(width: canvasW, height: canvasH)
                            .allowsHitTesting(false)

                        // 5. 待機画面が静止画にならないライブ・サイバーエフェクト層（走る稲妻・スパーク粒子・スキャンライン・グリッチバー）
                        VsLiveCyberStandbyOverlay(
                            time: now,
                            isCharacterInserted: isCharacterInserted
                        )
                        .frame(width: canvasW, height: canvasH)
                        .allowsHitTesting(false)

                        // 6. 左上マゼンタ枠内：対戦キャラクター名称（全機種で枠内に完全収まるよう中央揃え＋自動縮小）
                        Text(enemy.codeName)
                            .font(.system(size: min(canvasW * 0.135, canvasH * 0.066), weight: .black, design: .default))
                            .tracking(2)
                            .foregroundStyle(.white)
                            .shadow(color: neonMagenta, radius: 6)
                            .shadow(color: neonMagenta, radius: 14)
                            .shadow(color: neonMagenta.opacity(0.85), radius: 22)
                            .lineLimit(1)
                            .minimumScaleFactor(0.30)
                            .padding(.horizontal, 6)
                            .frame(width: canvasW * 0.43, height: canvasH * 0.095, alignment: .center)
                            .position(
                                x: canvasW * 0.285 + glitchShiftX,
                                y: canvasH * 0.132
                            )
                            .scaleEffect(isCharacterInserted ? 1.0 : 0.78)
                            .offset(x: isCharacterInserted ? 0 : -canvasW * 0.10)
                            .opacity(isCharacterInserted ? 1.0 : 0.0)

                        // 7. 右下シアン枠内：REO / (YOU) 名称（枠内中央に余裕を持って収め、右端切れを完全防止）
                        VStack(alignment: .center, spacing: -canvasH * 0.004) {
                            Text("REO")
                                .font(.system(size: min(canvasW * 0.125, canvasH * 0.060), weight: .black, design: .default))
                                .tracking(2)
                                .foregroundStyle(.white)
                                .shadow(color: neonCyan, radius: 6)
                                .shadow(color: neonCyan, radius: 14)
                                .shadow(color: neonCyan.opacity(0.85), radius: 20)
                                .lineLimit(1)
                                .minimumScaleFactor(0.45)

                            Text("(YOU)")
                                .font(.system(size: min(canvasW * 0.068, canvasH * 0.030), weight: .black, design: .default))
                                .tracking(1.5)
                                .foregroundStyle(.white)
                                .shadow(color: neonCyan, radius: 5)
                                .shadow(color: neonCyan, radius: 12)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .padding(.horizontal, 6)
                        .frame(width: canvasW * 0.41, height: canvasH * 0.135, alignment: .center)
                        .position(
                            x: canvasW * 0.715 - glitchShiftX,
                            y: canvasH * 0.868
                        )
                        .scaleEffect(isCharacterInserted ? 1.0 : 0.78)
                        .offset(x: isCharacterInserted ? 0 : canvasW * 0.10)
                        .opacity(isCharacterInserted ? 1.0 : 0.0)

                        // 8. キャラ挿入瞬間のサイバー閃光フラッシュ
                        LinearGradient(
                            colors: [
                                neonMagenta.opacity(0.55),
                                Color.white.opacity(0.85),
                                neonCyan.opacity(0.55)
                            ],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        )
                        .frame(width: canvasW, height: canvasH)
                        .blendMode(.screen)
                        .opacity(flashOpacity)
                        .allowsHitTesting(false)
                    }
                    .frame(width: canvasW, height: canvasH)
                    .offset(x: shake.width, y: shake.height)

                    // MARK: 9. キャラ表示から1秒後に「VS」の直下に出現するサイバー「START」ボタン
                    if isStartButtonVisible {
                        VsStartCyberButton(
                            time: now,
                            action: {
                                guard !hasTriggeredStart else { return }
                                hasTriggeredStart = true
                                onStartTapped()
                            }
                        )
                        .position(x: canvasW * 0.50, y: canvasH * 0.635)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.72).combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                        .zIndex(5)
                    }
                }
                .frame(width: screenW, height: screenH)
                .clipped()
            }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .task {
            isCharacterInserted = false
            isStartButtonVisible = false
            hasTriggeredStart = false
            flashOpacity = 0.0
            impactDate = nil

            // Step 1: まず添付1枚目（キャラ・文字なしのVS背景）を約0.42秒表示
            try? await Task.sleep(for: .milliseconds(420))
            guard !Task.isCancelled else { return }

            // Step 2: SE（vs_appear.mp3）＋強ハプティクス＋画面シェイクとともにキャラ＆名称を挿入
            SoundManager.shared.playVsAppearSE()
            HapticManager.playHeavy(enabled: isHapticsEnabled)
            impactDate = Date()

            withAnimation(.spring(response: 0.36, dampingFraction: 0.76)) {
                isCharacterInserted = true
            }
            withAnimation(.easeOut(duration: 0.10)) {
                flashOpacity = 0.72
            }
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.28)) {
                flashOpacity = 0.0
            }

            // Step 3: キャラクター表示から1秒（残り880ms）後に中央「VS」の下へ「START」ボタンを表示
            try? await Task.sleep(for: .milliseconds(880))
            guard !Task.isCancelled else { return }

            HapticManager.playLight(enabled: isHapticsEnabled)
            withAnimation(.spring(response: 0.38, dampingFraction: 0.74)) {
                isStartButtonVisible = true
            }
        }
    }

    /// キャラ挿入時の着地インパクトシェイク ＋ 待機中の常時サイバーカメラ揺れを合成
    private func computeScreenOffset(now: Date, rawTime: TimeInterval) -> CGSize {
        // 1. 待機中の常時サイバーカメラ揺れ（ゆっくりとした浮遊揺れ＋稲妻放電時の微振動）
        var dx = CGFloat(sin(rawTime * 2.3)) * 2.2 + CGFloat(cos(rawTime * 5.7)) * 0.6
        var dy = CGFloat(cos(rawTime * 1.8)) * 2.0 + CGFloat(sin(rawTime * 6.3)) * 0.6

        // 周期的な電磁パルス微振動
        let pulsePhase = rawTime.truncatingRemainder(dividingBy: 1.8)
        if isCharacterInserted && pulsePhase < 0.14 {
            dx += CGFloat(sin(rawTime * 65.0)) * 2.4
            dy += CGFloat(cos(rawTime * 58.0)) * 1.8
        }

        // 2. キャラ＆名称が挿入された瞬間のインパクト・カメラシェイク（約0.32秒間で減衰）
        if let impact = impactDate {
            let elapsed = now.timeIntervalSince(impact)
            if elapsed >= 0 && elapsed < 0.32 {
                let decay = CGFloat(max(0.0, 1.0 - elapsed / 0.32))
                let amp = decay * decay * 11.0
                dx += CGFloat(sin(elapsed * 95.0)) * amp
                dy += CGFloat(cos(elapsed * 112.0)) * amp * 0.85
            }
        }

        return CGSize(width: dx, height: dy)
    }
}

/// 中央「VS」の下に表示されるサイバーパンク「START」ボタン
private struct VsStartCyberButton: View {
    let time: TimeInterval
    let action: () -> Void

    private let neonMagenta = Color(red: 0.98, green: 0.22, blue: 0.88)
    private let neonCyan = Color(red: 0.20, green: 0.95, blue: 1.00)

    var body: some View {
        let pulse = 1.0 + CGFloat(sin(time * 4.2)) * 0.035
        let glowRadius = 12.0 + CGFloat(sin(time * 4.2)) * 5.0
        let sheenPhase = CGFloat((time * 0.65).truncatingRemainder(dividingBy: 1.0))

        Button(action: action) {
            ZStack {
                // 外側発光オーラ
                CyberShape(cutSize: 14)
                    .fill(
                        LinearGradient(
                            colors: [neonMagenta.opacity(0.38), neonCyan.opacity(0.38)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 10)

                // ボタン本体ベース
                CyberShape(cutSize: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.16, green: 0.04, blue: 0.26).opacity(0.95),
                                Color(red: 0.04, green: 0.14, blue: 0.26).opacity(0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // 斜めに走るホログラム光沢スウィープ
                GeometryReader { geo in
                    let w = geo.size.width
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.32),
                                    neonCyan.opacity(0.28),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: w * 0.42)
                        .rotationEffect(.degrees(20))
                        .offset(x: (sheenPhase * 1.6 - 0.3) * w)
                }
                .clipShape(CyberShape(cutSize: 14))

                // ネオン2重ボーダー（マゼンタ⇄シアン）
                CyberShape(cutSize: 14)
                    .strokeBorder(
                        LinearGradient(
                            colors: [neonMagenta, .white, neonCyan, neonMagenta],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.8
                    )

                // START テキスト＆サイバー装飾アイコン
                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(neonMagenta)
                        .shadow(color: neonMagenta, radius: 6)

                    Text("START")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .italic()
                        .tracking(4)
                        .foregroundStyle(.white)
                        .shadow(color: neonCyan, radius: 8)
                        .shadow(color: neonMagenta, radius: 14)

                    Image(systemName: "chevron.right.2")
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(neonCyan)
                        .shadow(color: neonCyan, radius: 6)
                        .offset(x: CGFloat(sin(time * 6.0)) * 2.5)
                }
                .padding(.horizontal, 26)
            }
            .frame(width: 236, height: 60)
            .scaleEffect(pulse)
            .shadow(color: neonMagenta.opacity(0.75), radius: glowRadius, x: -4, y: 0)
            .shadow(color: neonCyan.opacity(0.75), radius: glowRadius, x: 4, y: 0)
        }
        .buttonStyle(.plain)
    }
}

/// 待機中のVS画面をサイバーチックに躍動させるライブエフェクトレイヤー
/// （斜め稲妻のリアルタイム放電・中央VSから飛び散るネオンスパーク粒子・ホログラム走査線・グリッチバー）
private struct VsLiveCyberStandbyOverlay: View {
    let time: TimeInterval
    let isCharacterInserted: Bool

    private let neonMagenta = Color(red: 0.98, green: 0.22, blue: 0.88)
    private let neonCyan = Color(red: 0.20, green: 0.95, blue: 1.00)

    var body: some View {
        let tick = Int(time * 24.0)

        Canvas { context, size in
            let w = size.width
            let h = size.height
            guard w > 20, h > 20 else { return }

            // 1. 斜め境界線に沿ってリアルタイムにバチバチ放電するマゼンタ＆シアン稲妻
            drawLiveArc(
                context: &context,
                from: CGPoint(x: w * 0.68, y: 0),
                to: CGPoint(x: w * 0.48, y: h * 0.49),
                seed: tick &* 19 + 3,
                color: neonMagenta,
                jitter: 10
            )
            drawLiveArc(
                context: &context,
                from: CGPoint(x: w * 0.48, y: h * 0.49),
                to: CGPoint(x: w * 0.33, y: h),
                seed: tick &* 31 + 11,
                color: neonCyan,
                jitter: 10
            )
            drawLiveArc(
                context: &context,
                from: CGPoint(x: 0, y: h * 0.565),
                to: CGPoint(x: w * 0.48, y: h * 0.49),
                seed: tick &* 43 + 17,
                color: neonCyan,
                jitter: 8
            )
            drawLiveArc(
                context: &context,
                from: CGPoint(x: w * 0.48, y: h * 0.49),
                to: CGPoint(x: w, y: h * 0.42),
                seed: tick &* 59 + 23,
                color: neonMagenta,
                jitter: 8
            )

            // 2. 中央「VS」周辺から四方へ飛び散るサイバースパーク粒子（28個）
            let center = CGPoint(x: w * 0.50, y: h * 0.49)
            let sparkCount = 28
            for i in 0..<sparkCount {
                let speed = 0.55 + Double(i % 5) * 0.18
                let phase = (time * speed + Double(i) * 0.137).truncatingRemainder(dividingBy: 1.0)
                let angle = Double(i) * (2.0 * .pi / Double(sparkCount)) + sin(Double(i) * 1.7) * 0.25
                let maxDist = min(w, h) * (0.18 + CGFloat(i % 4) * 0.07)
                let dist = maxDist * CGFloat(phase)

                let px = center.x + CGFloat(cos(angle)) * dist
                let py = center.y + CGFloat(sin(angle)) * dist
                let alpha = (1.0 - phase) * 0.85
                let sparkColor = (i % 2 == 0) ? neonMagenta : neonCyan

                var sparkLine = Path()
                sparkLine.move(to: CGPoint(x: px, y: py))
                sparkLine.addLine(
                    to: CGPoint(
                        x: px - CGFloat(cos(angle)) * 10.0 * CGFloat(1.0 - phase * 0.5),
                        y: py - CGFloat(sin(angle)) * 10.0 * CGFloat(1.0 - phase * 0.5)
                    )
                )
                context.stroke(sparkLine, with: .color(sparkColor.opacity(alpha)), lineWidth: 2.2)
                context.stroke(sparkLine, with: .color(.white.opacity(alpha * 0.9)), lineWidth: 1.0)
            }

            // 3. 上から下へ流れるサイバーホログラム走査線（スキャンライン）
            let scanY = CGFloat((time * 0.28).truncatingRemainder(dividingBy: 1.0)) * h
            let scanRect = CGRect(x: 0, y: scanY, width: w, height: 3.0)
            context.fill(
                Path(scanRect),
                with: .color(neonCyan.opacity(0.18))
            )

            // 4. 周期的なサイバーグリッチ・ノイズスライス（待機中のサイバー感演出）
            if isCharacterInserted && (tick % 19 == 0 || tick % 29 == 0) {
                for g in 0..<3 {
                    let gy = CGFloat(((tick &* (g + 3) &* 97) % 100)) / 100.0 * h
                    let gw = w * CGFloat(0.25 + Double((tick + g) % 4) * 0.15)
                    let gx = CGFloat(((tick &* (g + 7) &* 53) % 70)) / 100.0 * w
                    let gColor = (g % 2 == 0) ? neonMagenta.opacity(0.28) : neonCyan.opacity(0.28)
                    context.fill(
                        Path(CGRect(x: gx, y: gy, width: gw, height: 2.5)),
                        with: .color(gColor)
                    )
                }
            }
        }
    }

    private func drawLiveArc(
        context: inout GraphicsContext,
        from start: CGPoint,
        to end: CGPoint,
        seed: Int,
        color: Color,
        jitter: CGFloat
    ) {
        var path = Path()
        path.move(to: start)
        let steps = 9
        for i in 1..<steps {
            let t = CGFloat(i) / CGFloat(steps)
            let bx = start.x + (end.x - start.x) * t
            let by = start.y + (end.y - start.y) * t
            let h = abs((seed &* (i + 7) &* 1103515245 + 12345) % 100)
            let offset = (CGFloat(h) / 100.0 - 0.5) * 2.0 * jitter
            path.addLine(to: CGPoint(x: bx + offset, y: by - offset * 0.45))
        }
        path.addLine(to: end)

        context.stroke(path, with: .color(color.opacity(0.55)), lineWidth: 4.5)
        context.stroke(path, with: .color(.white.opacity(0.85)), lineWidth: 1.3)
    }
}

/// 右上（敵キャラクター）の斜め稲妻ラインに沿ったクリップ形状
private struct UpperRightVsEnemyClipShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w * 0.50, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: h * 0.418))
        path.addLine(to: CGPoint(x: w * 0.43, y: h * 0.512))
        path.closeSubpath()
        return path
    }
}

/// 左下（REO）の斜め稲妻ラインに沿ったクリップ形状
private struct LowerLeftVsPlayerClipShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: 0, y: h * 0.48))
        path.addLine(to: CGPoint(x: w * 0.505, y: h * 0.49))
        path.addLine(to: CGPoint(x: w * 0.332, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

/// バトル画面共通の3Dパースペクティブ・サイバーグリッド背景
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
