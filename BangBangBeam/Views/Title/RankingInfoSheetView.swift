import SwiftUI

/// Game Center 未サインイン時（シミュレータ等）にも自己ベスト連勝記録と敵一覧を確認できる世界ランキングシート
struct RankingInfoSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let bestStreak = GameCenterManager.shared.bestWinStreak

        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // 自己ベスト連勝カード
                    VStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.cyberAmber)
                            .shadow(color: Color.cyberAmber.opacity(0.8), radius: 10)

                        Text("YOUR BEST WIN STREAK")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.7))

                        Text("\(bestStreak) 連勝")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundStyle(Color.cyberCyan)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(GameCenterManager.shared.isAuthenticated ? Color.cyberEmerald : Color.cyberAmber)
                                .frame(width: 8, height: 8)
                            Text(
                                GameCenterManager.shared.isAuthenticated
                                    ? "Game Center 接続済み (\(GameCenterManager.shared.playerDisplayName))"
                                    : "端末の「設定 > Game Center」にサインインすると世界ランキングに参加できます"
                            )
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                        }
                        .padding(.top, 4)

                        if GameCenterManager.shared.isAuthenticated {
                            Button {
                                GameCenterManager.shared.presentWorldRanking()
                            } label: {
                                Text("Game Center 世界ランキングを開く")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .background(Color.cyberAmber, in: Capsule())
                            }
                            .padding(.top, 6)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(
                        CyberShape(cutSize: 14)
                            .fill(Color.cyberPanel)
                            .overlay(
                                CyberShape(cutSize: 14)
                                    .strokeBorder(Color.cyberAmber.opacity(0.5), lineWidth: 1.4)
                            )
                    )

                    // 1周目 基本11人オーダー表
                    VStack(alignment: .leading, spacing: 10) {
                        Text("KUMITE TARGETS // LOOP 1 (1〜11戦目)")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.cyberCyan)

                        ForEach(CharacterProfile.baseKumiteRoster) { enemy in
                            let cleared = bestStreak >= enemy.stageOrder
                            fighterRow(
                                numberLabel: "\(enemy.stageOrder).",
                                enemy: enemy,
                                isRevealed: true,
                                isCleared: cleared
                            )
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        CyberShape(cutSize: 14)
                            .fill(Color.cyberPanel)
                            .overlay(
                                CyberShape(cutSize: 14)
                                    .strokeBorder(Color.cyberCyan.opacity(0.35), lineWidth: 1)
                            )
                    )

                    // 2周目（23人目以降）追加9人オーダー表
                    VStack(alignment: .leading, spacing: 10) {
                        Text("EXTRA TARGETS // LOOP 2+ (23戦目以降に出現)")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.cyberAmber)

                        ForEach(Array(CharacterProfile.extraLoopRoster.enumerated()), id: \.element.id) { idx, enemy in
                            let encounterMatchNumber = 23 + idx // 23人目〜31人目
                            let encountered = bestStreak >= (encounterMatchNumber - 1)
                            let cleared = bestStreak >= encounterMatchNumber
                            fighterRow(
                                numberLabel: "\(encounterMatchNumber)戦目.",
                                enemy: enemy,
                                isRevealed: encountered,
                                isCleared: cleared
                            )
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        CyberShape(cutSize: 14)
                            .fill(Color.cyberPanel)
                            .overlay(
                                CyberShape(cutSize: 14)
                                    .strokeBorder(Color.cyberAmber.opacity(0.35), lineWidth: 1)
                            )
                    )
                }
                .padding(16)
            }
            .background(Color.cyberBlack.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                AdBannerFooterView()
            }
            .navigationTitle("WORLD RANKING")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(Color.cyberCyan)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func fighterRow(
        numberLabel: String,
        enemy: CharacterProfile,
        isRevealed: Bool,
        isCleared: Bool
    ) -> some View {
        HStack(spacing: 12) {
            if isRevealed {
                Image(enemy.standingAsset(for: .normal))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 46)
                    .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.55))
                    Text("?")
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.35))
                }
                .frame(width: 38, height: 46)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(isRevealed ? "\(numberLabel) \(enemy.codeName)" : "\(numberLabel) ???")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(isRevealed ? .white : Color.white.opacity(0.55))
                Text(isRevealed ? enemy.titleLabel : "2周目の22人突破後に出現")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.65))
            }

            Spacer()

            if isCleared {
                Text("CLEARED")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.cyberEmerald, in: Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}
