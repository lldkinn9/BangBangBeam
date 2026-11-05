import SwiftUI

/// BGM ON/OFF・BPM速度・製品版ルールを確認できる設定シート（最下部にバナー広告常設）
struct SettingSheetView: View {
    @Bindable var engine: GameEngine
    @Bindable private var soundManager = SoundManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // MARK: 1. サウンド & 触覚設定
                    settingCard(title: "AUDIO & HAPTICS", icon: "speaker.wave.2.fill") {
                        VStack(spacing: 14) {
                            Toggle(isOn: $soundManager.isBGMEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("BGM サウンド再生")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text("タイトル (Neon Overdrive) / バトルランダムBGM")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.white.opacity(0.6))
                                }
                            }
                            .tint(Color.cyberCyan)

                            Divider().background(Color.white.opacity(0.15))

                            Toggle(isOn: $engine.isHapticsEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("触覚フィードバック (Haptics)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text("拍のリズムや激突時の振動演出")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.white.opacity(0.6))
                                }
                            }
                            .tint(Color.cyberEmerald)
                        }
                    }

                    // MARK: 2. BPM テンポ設定
                    settingCard(title: "TEMPO / BPM", icon: "metronome.fill") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("リズム速度")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(Int(engine.bpm)) BPM (約\(String(format: "%.2f", engine.beatInterval))秒/拍)")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color.cyberCyan)
                            }

                            Slider(value: $engine.bpm, in: 60...140, step: 2)
                                .tint(Color.cyberCyan)

                            HStack {
                                Text("SLOW (60)")
                                Spacer()
                                Button("標準 (88 BPM) に戻す") {
                                    engine.bpm = 88.0
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.cyberEmerald)
                                Spacer()
                                Text("FAST (140)")
                            }
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.5))
                        }
                    }

                    // MARK: 3. 製品版コマンド＆ルールガイド
                    settingCard(title: "BATTLE RULES", icon: "bolt.horizontal.circle.fill") {
                        VStack(alignment: .leading, spacing: 10) {
                            ruleRow(
                                title: "❤️ 3ライフ体力制 ＆ チャージ削り",
                                desc: "通常ビームを3回食らうと敗退！ビームを被弾すると溜めたチャージも -1 削られます。"
                            )
                            ruleRow(
                                title: "⚡️ チャージ (消費0 / +1)",
                                desc: "気力を1溜める。攻撃に対しては無防備。"
                            )
                            ruleRow(
                                title: "💥 ビーム (消費1)",
                                desc: "無防備な相手に HP -1 ＆ チャージ -1 ダメージ！バリアには防がれ、ビーム同士は相殺。"
                            )
                            ruleRow(
                                title: "🛡️ バリア (消費0)",
                                desc: "相手の通常ビームをノーダメージで完全防御。"
                            )
                            ruleRow(
                                title: "🌟 必殺ビーム (4チャージ / 一撃必殺)",
                                desc: "4回チャージで解放！カットイン＆必殺アニメと共にバリアも残りHPも貫通して一撃必殺！"
                            )
                            Divider().background(Color.white.opacity(0.15))
                            ruleRow(
                                title: "💦 お手つき（気力不足ミス）",
                                desc: "気力が足りない状態でビーム／必殺ビームを選んで3拍目を迎えると、不発となり【無防備状態】になります（相手がビームなら被弾ダメージ）。",
                                titleColor: .cyberDanger
                            )
                        }
                    }
                }
                .padding(18)
            }
            .background(Color.cyberBlack.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                AdBannerFooterView()
            }
            .navigationTitle("SETTING")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(AppVersion.displayText)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.cyberCyan.opacity(0.8))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(Color.cyberCyan)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func settingCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundStyle(Color.cyberCyan)

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            CyberShape(cutSize: 12)
                .fill(Color.cyberPanel)
                .overlay(
                    CyberShape(cutSize: 12)
                        .strokeBorder(Color.cyberCyan.opacity(0.35), lineWidth: 1)
                )
        )
    }

    private func ruleRow(title: String, desc: String, titleColor: Color = .cyberEmerald) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(titleColor)
            Text(desc)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.75))
        }
    }
}
