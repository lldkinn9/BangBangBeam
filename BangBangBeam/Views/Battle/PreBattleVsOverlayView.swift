import SwiftUI

/// 戦闘開始前の「事前画面（VS画面）」オーバーレイ
/// 1枚目（キャラ・文字なしのVS背景テンプレート `vs_screen_bg`）が表示された状態から、
/// 2枚目（右上に対戦相手立ち絵・左上枠に対戦相手名称・左下にREO立ち絵・右下枠に `REO (YOU)` が挿入された状態）へ
/// アニメーションで切り替わる演出。
struct PreBattleVsOverlayView: View {
    let enemy: CharacterProfile
    let stageLabel: String
    let winStreak: Int

    /// false = 添付1枚目の状態（ベース背景のみ）、true = 添付2枚目の状態（キャラ立ち絵＆キャラ名称が挿入された状態）
    @State private var isCharacterInserted: Bool = false
    /// 挿入瞬間のネオンフラッシュ演出
    @State private var flashOpacity: Double = 0.0

    private let neonMagenta = Color(red: 0.98, green: 0.22, blue: 0.88)
    private let neonCyan = Color(red: 0.20, green: 0.95, blue: 1.00)

    /// `vs_screen_bg` / `vs_screen_fg` のネイティブ解像度比率（571 × 1024）
    private let templateAspect: CGFloat = 571.0 / 1024.0

    var body: some View {
        GeometryReader { geo in
            let screenW = max(geo.size.width, 1)
            let screenH = max(geo.size.height, 1)
            let screenAspect = screenW / screenH

            // 全iPhone画面比率で背景画像上の枠・稲妻とキャラ・テキスト座標が1pxもズレないAspect-Fillキャンバスサイズ
            let canvasW: CGFloat = screenAspect > templateAspect ? screenW : screenH * templateAspect
            let canvasH: CGFloat = screenAspect > templateAspect ? screenW / templateAspect : screenH

            ZStack {
                Color.black
                    .ignoresSafeArea()

                // MARK: 571×1024 正規化座標キャンバス
                ZStack {
                    // 1. ベース背景（添付1枚目：空の左上マゼンタ枠・右下シアン枠・稲妻・中央VSロゴ）
                    Image("vs_screen_bg")
                        .resizable()
                        .interpolation(.high)
                        .frame(width: canvasW, height: canvasH)

                    // 2. 右上：対戦相手キャラクター立ち絵（1枚目→2枚目で右上からスライドイン＆斜め稲妻ラインでクリップ）
                    ZStack {
                        Image(enemy.standingAsset(for: .normal))
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(height: canvasH * 0.717)
                            .shadow(color: neonMagenta.opacity(0.65), radius: 14)
                            .position(x: canvasW * 0.865, y: canvasH * 0.389)
                            .scaleEffect(isCharacterInserted ? 1.0 : 1.08)
                            .offset(
                                x: isCharacterInserted ? 0 : canvasW * 0.22,
                                y: isCharacterInserted ? 0 : -canvasH * 0.04
                            )
                            .opacity(isCharacterInserted ? 1.0 : 0.0)
                    }
                    .frame(width: canvasW, height: canvasH)
                    .clipShape(UpperRightVsEnemyClipShape())

                    // 3. 左下：主人公 REO 立ち絵（1枚目→2枚目で左下からスライドイン＆斜め稲妻ラインでクリップ）
                    ZStack {
                        Image(CharacterProfile.reo.standingAsset(for: .normal))
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(height: canvasH * 0.830)
                            .shadow(color: neonCyan.opacity(0.65), radius: 14)
                            .position(x: canvasW * 0.264, y: canvasH * 0.945)
                            .scaleEffect(isCharacterInserted ? 1.0 : 1.08)
                            .offset(
                                x: isCharacterInserted ? 0 : -canvasW * 0.22,
                                y: isCharacterInserted ? 0 : canvasH * 0.04
                            )
                            .opacity(isCharacterInserted ? 1.0 : 0.0)
                    }
                    .frame(width: canvasW, height: canvasH)
                    .clipShape(LowerLeftVsPlayerClipShape())

                    // 4. 前景オーバーレイ（添付2枚目と同様に、中央「VS」ロゴと斜め稲妻がキャラ境界の手前に重なるレイヤー）
                    Image("vs_screen_fg")
                        .resizable()
                        .interpolation(.high)
                        .frame(width: canvasW, height: canvasH)
                        .allowsHitTesting(false)

                    // 5. 左上マゼンタ枠内：対戦キャラクター名称（対戦相手に応じて動的に挿入）
                    Text(enemy.codeName)
                        .font(.system(size: canvasH * 0.074, weight: .black, design: .default))
                        .tracking(3)
                        .scaleEffect(x: 1.12, y: 1.0)
                        .foregroundStyle(.white)
                        .shadow(color: neonMagenta, radius: 6)
                        .shadow(color: neonMagenta, radius: 14)
                        .shadow(color: neonMagenta.opacity(0.85), radius: 24)
                        .lineLimit(1)
                        .minimumScaleFactor(0.38)
                        .frame(width: canvasW * 0.44, height: canvasH * 0.095, alignment: .center)
                        .position(x: canvasW * 0.280, y: canvasH * 0.132)
                        .scaleEffect(isCharacterInserted ? 1.0 : 0.82)
                        .offset(x: isCharacterInserted ? 0 : -canvasW * 0.08)
                        .opacity(isCharacterInserted ? 1.0 : 0.0)

                    // 6. 右下シアン枠内：REO / (YOU) 名称（添付2枚目と同じ2段右寄せネオン表記）
                    VStack(alignment: .trailing, spacing: -canvasH * 0.006) {
                        Text("REO")
                            .font(.system(size: canvasH * 0.066, weight: .black, design: .default))
                            .tracking(2.5)
                            .scaleEffect(x: 1.10, y: 1.0, anchor: .trailing)
                            .foregroundStyle(.white)
                            .shadow(color: neonCyan, radius: 6)
                            .shadow(color: neonCyan, radius: 14)
                            .shadow(color: neonCyan.opacity(0.85), radius: 22)

                        Text("(YOU)")
                            .font(.system(size: canvasH * 0.032, weight: .black, design: .default))
                            .tracking(1.5)
                            .scaleEffect(x: 1.08, y: 1.0, anchor: .trailing)
                            .foregroundStyle(.white)
                            .shadow(color: neonCyan, radius: 5)
                            .shadow(color: neonCyan, radius: 12)
                    }
                    .frame(width: canvasW * 0.40, height: canvasH * 0.145, alignment: .trailing)
                    .position(x: canvasW * 0.745, y: canvasH * 0.865)
                    .scaleEffect(isCharacterInserted ? 1.0 : 0.82)
                    .offset(x: isCharacterInserted ? 0 : canvasW * 0.08)
                    .opacity(isCharacterInserted ? 1.0 : 0.0)

                    // 7. キャラ挿入瞬間のサイバー閃光フラッシュ
                    LinearGradient(
                        colors: [
                            neonMagenta.opacity(0.45),
                            Color.white.opacity(0.75),
                            neonCyan.opacity(0.45)
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
                .position(x: screenW * 0.5, y: screenH * 0.5)
            }
            .frame(width: screenW, height: screenH)
            .clipped()
        }
        .ignoresSafeArea()
        .task {
            isCharacterInserted = false
            flashOpacity = 0.0

            // Step 1: まず添付1枚目（キャラ・文字なしのVS背景）を約0.42秒見せる
            try? await Task.sleep(for: .milliseconds(420))
            guard !Task.isCancelled else { return }

            // Step 2: 添付2枚目の状態（キャラ立ち絵＆キャラ名称挿入）へダイナミックにアニメーション切替
            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                isCharacterInserted = true
            }
            withAnimation(.easeOut(duration: 0.12)) {
                flashOpacity = 0.65
            }
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.28)) {
                flashOpacity = 0.0
            }
        }
    }
}

/// 右上（敵キャラクター）の斜め稲妻ラインに沿ったクリップ形状（571×1024正規化座標）
private struct UpperRightVsEnemyClipShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w * 0.54, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: h * 0.418))
        path.addLine(to: CGPoint(x: w * 0.44, y: h * 0.512))
        path.closeSubpath()
        return path
    }
}

/// 左下（REO）の斜め稲妻ラインに沿ったクリップ形状（571×1024正規化座標）
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
