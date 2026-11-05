import SwiftUI

/// Game Center 未サインイン時（シミュレータ等）にも自己ベスト連勝記録と敵11人一覧を確認できる世界ランキングシート
struct RankingInfoSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
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

                        Text("\(GameCenterManager.shared.bestWinStreak) 連勝")
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

                    // KUMITE 11人勝ち抜きオーダー表
                    VStack(alignment: .leading, spacing: 10) {
                        Text("KUMITE TARGET ORDER (11 FIGHTERS LOOP)")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.cyberCyan)

                        ForEach(CharacterProfile.kumiteRoster) { enemy in
                            let cleared = GameCenterManager.shared.bestWinStreak >= enemy.stageOrder
                            HStack(spacing: 12) {
                                Image(enemy.standingAsset(for: .normal))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 38, height: 46)
                                    .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(enemy.stageOrder). \(enemy.codeName)")
                                        .font(.system(size: 14, weight: .black))
                                        .foregroundStyle(.white)
                                    Text(enemy.titleLabel)
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.white.opacity(0.65))
                                }

                                Spacer()

                                if cleared {
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
}
