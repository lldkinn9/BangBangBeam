import SwiftUI

/// BPM速度やルールを確認・変更できる設定シート
struct SettingSheetView: View {
    @Bindable var engine: GameEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: 1. BPM テンポ設定
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

                    // MARK: 2. マッチルール & 触覚設定
                    settingCard(title: "BATTLE RULES", icon: "shield.lefthalf.filled") {
                        VStack(spacing: 16) {
                            HStack {
                                Text("勝利条件（先取本数）")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Picker("先取本数", selection: $engine.targetWins) {
                                    Text("1本勝負").tag(1)
                                    Text("2本先取").tag(2)
                                    Text("3本先取").tag(3)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 210)
                            }

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

                    // MARK: 3. コマンド＆ルールガイド
                    settingCard(title: "COMMAND GUIDE", icon: "bolt.horizontal.circle.fill") {
                        VStack(alignment: .leading, spacing: 10) {
                            ruleRow(title: "⚡️ チャージ (消費0 / +1)", desc: "気力を1溜める。攻撃に対しては無防備。")
                            ruleRow(title: "💥 ビーム (消費1)", desc: "チャージ中の相手を撃破！バリアには防がれ、ビーム同士は相殺。")
                            ruleRow(title: "🛡️ バリア (消費0)", desc: "通常ビームをノーダメージで完全防御。")
                            ruleRow(title: "🌟 メガビーム (消費2)", desc: "通常バリアや通常ビームを貫通して撃破する超必殺技！")
                            Divider().background(Color.white.opacity(0.15))
                            ruleRow(
                                title: "⚠️ お手つき自滅ルール",
                                desc: "気力不足の状態でビーム／メガビームを選択して3拍目を迎えると即敗北！",
                                titleColor: .cyberDanger
                            )
                        }
                    }
                }
                .padding(18)
            }
            .background(Color.cyberBlack.ignoresSafeArea())
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
