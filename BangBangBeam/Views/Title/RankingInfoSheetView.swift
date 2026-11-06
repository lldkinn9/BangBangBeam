import SwiftUI

/// 世界ランキング画面（自分の順位・選択アイコン ＆ 世界1位〜100位を表示）
struct RankingInfoSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var gcManager = GameCenterManager.shared
    @Bindable private var iconManager = PlayerIconManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: 1. スクロール固定：自分の順位＆選択アイコン枠
                myRankCard
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
                    .background(Color.cyberBlack)

                Divider()
                    .background(Color.cyberCyan.opacity(0.25))

                // MARK: 2. スクロール領域：世界 1位〜100位 リスト (TOP 1 - 100)
                ScrollView {
                    top100ListCard
                        .padding(16)
                }
                .refreshable {
                    await gcManager.fetchTop100Ranking()
                }
            }
            .background(Color.cyberBlack.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                AdBannerFooterView()
            }
            .navigationTitle("WORLD RANKING")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task {
                            await gcManager.fetchTop100Ranking()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.cyberCyan)
                    }
                    .disabled(gcManager.isLoadingRanking)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(Color.cyberCyan)
                }
            }
            .task {
                await gcManager.fetchTop100Ranking()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - 1. 自分の順位カード（設定画面で選択したアイコンを反映）
    private var myRankCard: some View {
        let displayedStreak = max(gcManager.bestWinStreak, gcManager.myGlobalScore ?? 0)
        let myIconAsset = iconManager.selectedIcon.unlockedAssetName

        return VStack(spacing: 12) {
            HStack {
                Label("YOUR RANKING", systemImage: "person.crop.square.filled.and.at.rectangle")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.cyberAmber)

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(gcManager.isAuthenticated ? Color.cyberEmerald : Color.cyberAmber)
                        .frame(width: 7, height: 7)
                    Text(
                        gcManager.isAuthenticated
                            ? gcManager.playerDisplayName
                            : (GameCenterManager.useMockRankingForPreview ? "モックプレビュー表示中" : "Game Center 未接続")
                    )
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .lineLimit(1)
                }
            }

            HStack(spacing: 12) {
                // 設定画面で選択したプレイヤーアイコン
                Image(myIconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 58)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color.cyberAmber, lineWidth: 2)
                    )
                    .shadow(color: Color.cyberAmber.opacity(0.45), radius: 5)

                HStack(spacing: 0) {
                    // 左：自分の世界順位
                    VStack(spacing: 4) {
                        Text("自分の順位")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.65))

                        if let rank = gcManager.myGlobalRank {
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("\(rank)")
                                    .font(.system(size: 30, weight: .black, design: .rounded))
                                    .foregroundStyle(Color.cyberAmber)
                                Text("位")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.cyberAmber)
                            }
                        } else {
                            Text(gcManager.isAuthenticated ? "未ランクイン" : "—")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.55))
                                .frame(height: 34)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Color.white.opacity(0.14))
                        .frame(width: 1, height: 44)

                    // 右：自己ベスト連勝数
                    VStack(spacing: 4) {
                        Text("自己ベスト記録")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.65))

                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("\(displayedStreak)")
                                .font(.system(size: 30, weight: .black, design: .rounded))
                                .foregroundStyle(Color.cyberCyan)
                            Text("連勝")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.cyberCyan)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            CyberShape(cutSize: 14)
                .fill(Color.cyberPanel)
                .overlay(
                    CyberShape(cutSize: 14)
                        .strokeBorder(Color.cyberAmber.opacity(0.55), lineWidth: 1.4)
                )
        )
    }

    // MARK: - 2. 1位〜100位 ランキング一覧カード
    private var top100ListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("TOP 1 - 100", systemImage: "trophy.fill")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.cyberCyan)

                Spacer()

                if gcManager.totalRankedPlayers > 0 {
                    Text("全 \(gcManager.totalRankedPlayers) 人")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
            }

            if gcManager.isLoadingRanking {
                VStack(spacing: 10) {
                    ProgressView()
                        .tint(Color.cyberCyan)
                    Text("世界ランキングを取得中...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
            } else if !gcManager.top100Entries.isEmpty {
                LazyVStack(spacing: 8) {
                    ForEach(gcManager.top100Entries) { entry in
                        rankingRow(entry: entry)
                    }
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: gcManager.isAuthenticated ? "list.number" : "gamecontroller.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.cyberCyan.opacity(0.7))

                    Text(
                        gcManager.rankingStatusNote
                            ?? "ランキングデータがありません。"
                    )
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, 8)
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

    private func rankingRow(entry: LeaderboardRowEntry) -> some View {
        let rankAccent = rankColor(for: entry.rank)
        let displayedIcon = entry.isLocalPlayer
            ? iconManager.selectedIcon.unlockedAssetName
            : entry.iconAssetName

        return HStack(spacing: 10) {
            // 順位バッジ (1〜100)
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(entry.rank <= 3 ? rankAccent.opacity(0.22) : Color.white.opacity(0.06))
                Text("\(entry.rank)")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(rankAccent)
            }
            .frame(width: 38, height: 32)

            // プレイヤーアイコン
            Image(displayedIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 38, height: 38)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(
                            entry.isLocalPlayer
                                ? Color.cyberEmerald
                                : (entry.rank <= 3 ? rankAccent.opacity(0.8) : Color.white.opacity(0.18)),
                            lineWidth: entry.isLocalPlayer || entry.rank <= 3 ? 1.6 : 0.8
                        )
                )

            // プレイヤー名
            HStack(spacing: 6) {
                Text(entry.displayName)
                    .font(.system(size: 13, weight: entry.isLocalPlayer ? .black : .semibold))
                    .foregroundStyle(entry.isLocalPlayer ? Color.cyberEmerald : .white)
                    .lineLimit(1)

                if entry.isLocalPlayer {
                    Text("YOU")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cyberEmerald, in: Capsule())
                }
            }

            Spacer(minLength: 4)

            // 連勝スコア
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(entry.score)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(entry.rank <= 3 ? rankAccent : Color.cyberCyan)
                Text("連勝")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(entry.isLocalPlayer ? Color.cyberEmerald.opacity(0.14) : Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(
                            entry.isLocalPlayer ? Color.cyberEmerald.opacity(0.65) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
    }

    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1:
            return Color.cyberAmber
        case 2:
            return Color(red: 0.82, green: 0.88, blue: 0.95)
        case 3:
            return Color(red: 0.90, green: 0.58, blue: 0.34)
        default:
            return Color.white.opacity(0.85)
        }
    }
}
