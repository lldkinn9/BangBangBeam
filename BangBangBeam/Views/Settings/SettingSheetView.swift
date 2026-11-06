import SwiftUI

/// アイコン設定・BGM ON/OFF・TEMPO(標準/速め)・製品版ルールを確認できる設定シート（最下部にバナー広告常設）
struct SettingSheetView: View {
    @Bindable var engine: GameEngine
    @Bindable private var soundManager = SoundManager.shared
    @Bindable private var iconManager = PlayerIconManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // MARK: 1. アイコン設定（最上部）
                    settingCard(title: "アイコン設定", icon: "person.crop.circle.badge.checkmark") {
                        NavigationLink {
                            IconSettingView(engine: engine)
                        } label: {
                            HStack(spacing: 14) {
                                Image(iconManager.selectedIcon.unlockedAssetName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 56, height: 56)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.cyberCyan, lineWidth: 2)
                                    )
                                    .shadow(color: Color.cyberCyan.opacity(0.4), radius: 5)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(iconManager.selectedIcon.characterCodeName) — \(iconManager.selectedIcon.variantLabel)")
                                        .font(.system(size: 14, weight: .black, design: .monospaced))
                                        .foregroundStyle(.white)

                                    Text("ランキングに表示されるアイコンを選択")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.white.opacity(0.65))

                                    Text("解放済み \(iconManager.unlockedIconIDs.count) / \(iconManager.allIcons.count)")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color.cyberEmerald)
                                }

                                Spacer()

                                HStack(spacing: 4) {
                                    Text("変更")
                                        .font(.system(size: 12, weight: .bold))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundStyle(Color.cyberCyan)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(Color.cyberCyan.opacity(0.14))
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(Color.cyberCyan.opacity(0.5), lineWidth: 1)
                                        )
                                )
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    // MARK: 2. サウンド & 触覚設定
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

                    // MARK: 3. TEMPO / BPM 設定（標準 / 速め の選択形式）
                    settingCard(title: "TEMPO / BPM", icon: "metronome.fill") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("リズム速度")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(engine.tempoPreset.title)
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundStyle(Color.cyberCyan)
                            }

                            HStack(spacing: 12) {
                                ForEach(TempoPreset.allCases) { preset in
                                    let isSelected = (engine.tempoPreset == preset)
                                    Button {
                                        engine.tempoPreset = preset
                                        HapticManager.playMedium(enabled: engine.isHapticsEnabled)
                                    } label: {
                                        Text(preset.title)
                                            .font(.system(size: 15, weight: .black))
                                            .foregroundStyle(isSelected ? .black : .white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(isSelected ? Color.cyberCyan : Color.black.opacity(0.45))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .strokeBorder(
                                                                isSelected ? Color.cyberCyan : Color.white.opacity(0.22),
                                                                lineWidth: isSelected ? 2 : 1
                                                            )
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // MARK: 4. 製品版コマンド＆ルールガイド（アイコン無し）
                    settingCard(title: "BATTLE RULES", icon: nil) {
                        VStack(alignment: .leading, spacing: 12) {
                            ruleRow(
                                title: "〇3ライフ体力制",
                                desc: "ビームを3回被弾すると敗退となります。\nまた、被弾するとチャージも１削られます。"
                            )
                            ruleRow(
                                title: "〇チャージ",
                                desc: "ビームを放つために気力を溜めます。\nチャージ中は相手のビームに被弾します。被弾すると体力とチャージが１削られます。"
                            )
                            ruleRow(
                                title: "〇ビーム",
                                desc: "チャージを1消費してビームを放てます。\n相手の手がチャージであれば1ダメージを与えることができます。\nビーム同士の場合はお互い体力は消費しません。チャージは消費します。"
                            )
                            ruleRow(
                                title: "〇バリア",
                                desc: "相手のビームを防ぎます。\n必殺技は防げません。"
                            )
                            ruleRow(
                                title: "〇必殺技",
                                desc: "チャージを4つ溜めると一撃必殺の必殺技を繰り出せます。\n相手の体力やバリアにかかわらず勝利となります。"
                            )
                            Divider().background(Color.white.opacity(0.15))
                            ruleRow(
                                title: "〇お手付き",
                                desc: "チャージ０の状態でビームを選択すると不発となります。\n無防備な状態となり相手がビームの場合、体力とチャージが1削られます。",
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
        icon: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let icon {
                Label(title, systemImage: icon)
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.cyberCyan)
            } else {
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.cyberCyan)
            }

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
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(titleColor)
            Text(desc)
                .font(.system(size: 12))
                .lineSpacing(3)
                .foregroundStyle(Color.white.opacity(0.78))
                .padding(.leading, 12)
        }
    }
}
