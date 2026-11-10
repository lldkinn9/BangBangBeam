import SwiftUI

/// アイコン設定・言語選択（日本語/英語）・サウンドON/OFF・BGM/SE音量設定・TEMPO(標準/速め)・ルールを確認できる設定シート（最下部にバナー広告常設）
struct SettingSheetView: View {
    @Bindable var engine: GameEngine
    @Bindable private var soundManager = SoundManager.shared
    @Bindable private var iconManager = PlayerIconManager.shared
    @Bindable private var languageManager = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let _ = languageManager.language

        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // MARK: 1. アイコン設定
                    settingCard(
                        title: L10n("アイコン設定", "PLAYER ICON"),
                        icon: "person.crop.circle.badge.checkmark"
                    ) {
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

                                    Text(L10n("ランキングに表示されるアイコンを選択", "Choose your icon for World Ranking"))
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.white.opacity(0.65))

                                    Text(
                                        L10n(
                                            "解放済み \(iconManager.unlockedIconIDs.count) / \(iconManager.allIcons.count)",
                                            "Unlocked \(iconManager.unlockedIconIDs.count) / \(iconManager.allIcons.count)"
                                        )
                                    )
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color.cyberEmerald)
                                }

                                Spacer()

                                HStack(spacing: 4) {
                                    Text(L10n("変更", "EDIT"))
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

                    // MARK: 2. 言語設定（日本語 / English）
                    settingCard(title: L10n("言語設定 / LANGUAGE", "LANGUAGE"), icon: "globe") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(L10n("表示言語", "Display Language"))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(languageManager.language.displayName)
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundStyle(Color.cyberCyan)
                            }

                            HStack(spacing: 12) {
                                ForEach(AppLanguage.allCases) { option in
                                    let isSelected = (languageManager.language == option)
                                    Button {
                                        languageManager.language = option
                                        languageManager.hasSelectedInitialLanguage = true
                                        SoundManager.shared.playButtonSE()
                                        HapticManager.playMedium(enabled: engine.isHapticsEnabled)
                                    } label: {
                                        Text(option.displayName)
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

                    // MARK: 3. サウンド & 触覚設定
                    settingCard(title: "AUDIO & HAPTICS", icon: "speaker.wave.2.fill") {
                        VStack(spacing: 14) {
                            Toggle(isOn: $soundManager.isBGMEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(L10n("サウンド再生 (BGM / SE)", "Sound (BGM / SE)"))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text(
                                        soundManager.isBGMEnabled
                                            ? L10n("BGMと効果音（SE）を再生中", "BGM and Sound Effects are ON")
                                            : L10n("現在OFFのため音量設定にかかわらず消音中", "Muted (All game audio is OFF)")
                                    )
                                    .font(.system(size: 11))
                                    .foregroundStyle(
                                        soundManager.isBGMEnabled
                                            ? Color.white.opacity(0.6)
                                            : Color.cyberAmber
                                    )
                                }
                            }
                            .tint(Color.cyberCyan)

                            VStack(spacing: 6) {
                                HStack {
                                    Label(L10n("BGM 音量", "BGM Volume"), systemImage: "music.note")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("\(Int((soundManager.bgmVolume * 100).rounded()))%")
                                        .font(.system(size: 12, weight: .black, design: .monospaced))
                                        .foregroundStyle(Color.cyberCyan)
                                }

                                Slider(value: $soundManager.bgmVolume, in: 0.0...1.0, step: 0.05)
                                    .tint(Color.cyberCyan)
                            }
                            .opacity(soundManager.isBGMEnabled ? 1.0 : 0.52)

                            VStack(spacing: 6) {
                                HStack {
                                    Label(L10n("SE（効果音）音量", "SE Volume"), systemImage: "waveform")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("\(Int((soundManager.seVolume * 100).rounded()))%")
                                        .font(.system(size: 12, weight: .black, design: .monospaced))
                                        .foregroundStyle(Color.cyberEmerald)
                                }

                                Slider(
                                    value: $soundManager.seVolume,
                                    in: 0.0...1.0,
                                    step: 0.05
                                ) {
                                    Text(L10n("SE音量", "SE Volume"))
                                } onEditingChanged: { isEditing in
                                    if !isEditing && soundManager.isBGMEnabled {
                                        SoundManager.shared.playButtonSE()
                                    }
                                }
                                .tint(Color.cyberEmerald)
                            }
                            .opacity(soundManager.isBGMEnabled ? 1.0 : 0.52)

                            Divider().background(Color.white.opacity(0.15))

                            Toggle(isOn: $engine.isHapticsEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(L10n("触覚フィードバック (Haptics)", "Haptics (Vibration)"))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text(L10n("拍のリズムや激突時の振動演出", "Vibration feedback on beats and clashes"))
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.white.opacity(0.6))
                                }
                            }
                            .tint(Color.cyberEmerald)
                        }
                    }

                    // MARK: 4. TEMPO / BPM 設定（標準 / 速め）
                    settingCard(title: "TEMPO / BPM", icon: "metronome.fill") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(L10n("リズム速度", "Rhythm Speed"))
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

                    // MARK: 5. ルールガイド
                    settingCard(title: "BATTLE RULES", icon: nil) {
                        VStack(alignment: .leading, spacing: 12) {
                            ruleRow(
                                title: L10n("〇3ライフ体力制", "• 3-Heart Life System"),
                                desc: L10n(
                                    "ビームを3回被弾すると敗退となります。\nまた、被弾するとチャージも１削られます。",
                                    "Getting hit by a Beam 3 times results in defeat.\nTaking a hit also reduces your stored Charge by 1."
                                )
                            )
                            ruleRow(
                                title: L10n("〇チャージ", "• CHARGE"),
                                desc: L10n(
                                    "ビームを放つために気力を溜めます。\nチャージ中は相手のビームに被弾します。被弾すると体力とチャージが１削られます。",
                                    "Stores +1 energy needed to fire Beams.\nYou are vulnerable while charging; getting hit costs 1 HP and 1 Charge."
                                )
                            )
                            ruleRow(
                                title: L10n("〇ビーム", "• BEAM"),
                                desc: L10n(
                                    "チャージを1消費してビームを放てます。\n相手の手がチャージであれば1ダメージを与えることができます。\nビーム同士の場合はお互い体力は消費しません。チャージは消費します。",
                                    "Consumes 1 Charge to fire a Beam.\nDeals 1 damage if your opponent is charging (or misfires).\nTwo Beams cancel each other out with no HP damage."
                                )
                            )
                            ruleRow(
                                title: L10n("〇バリア", "• BARRIER"),
                                desc: L10n(
                                    "相手のビームを防ぎます。\n必殺技は防げません。",
                                    "Blocks normal enemy Beams at 0 Charge cost.\nCannot block an Ultimate attack."
                                )
                            )
                            ruleRow(
                                title: L10n("〇必殺技", "• ULTIMATE"),
                                desc: L10n(
                                    "チャージを4つ溜めると一撃必殺の必殺技を繰り出せます。\n相手の体力やバリアにかかわらず勝利となります。",
                                    "Store 4 Charges to unleash a one-hit KO Ultimate!\nPierces Barriers and remaining HP for an instant victory."
                                )
                            )
                            Divider().background(Color.white.opacity(0.15))
                            ruleRow(
                                title: L10n("〇お手付き", "• Misfire (No Guard)"),
                                desc: L10n(
                                    "チャージ０の状態でビームを選択すると不発となります。\n無防備な状態となり相手がビームの場合、体力とチャージが1削られます。",
                                    "Selecting BEAM with 0 Charge causes a misfire (NO GUARD).\nYou are left completely defenseless against enemy Beams."
                                ),
                                titleColor: .cyberDanger
                            )

                            Divider()
                                .background(Color.white.opacity(0.15))
                                .padding(.vertical, 4)

                            Button {
                                HapticManager.playMedium(enabled: engine.isHapticsEnabled)
                                dismiss()
                                Task { @MainActor in
                                    engine.startPracticeMode()
                                }
                            } label: {
                                Text(L10n("実践画面でルールを学ぶ (PRACTICE)", "Learn Rules on Battle Screen (PRACTICE)"))
                                    .font(.system(size: 14.5, weight: .black, design: .rounded))
                                    .tracking(0.8)
                                    .minimumScaleFactor(0.8)
                                    .lineLimit(1)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                            .buttonStyle(
                                CyberButtonStyle(
                                    primaryColor: .cyberEmerald,
                                    secondaryColor: .cyberCyan,
                                    cutSize: 12,
                                    fillOpacity: 0.34
                                )
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
                    Button(L10n("完了", "Done")) {
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
