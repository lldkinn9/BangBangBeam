import SwiftUI

/// 全84個（通常83個 ＋ 100連勝記念 reo-icon100）からアイコンを選択する「アイコン設定」画面
struct IconSettingView: View {
    @Bindable var engine: GameEngine
    @Bindable private var iconManager = PlayerIconManager.shared
    @State private var lockedHintText: String? = nil

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: 現在選択中のアイコン ＆ 解放状況ヘッダー
                currentSelectionBanner

                // MARK: 未解放アイコンタップ時の解放条件ガイド表示
                if let lockedHintText {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.cyberAmber)
                        Text(lockedHintText)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.cyberAmber.opacity(0.14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.cyberAmber.opacity(0.55), lineWidth: 1)
                            )
                    )
                }

                // MARK: 全キャラクター別 4列アイコングリッド（全84個）
                ForEach(iconManager.characterGroups) { group in
                    characterGroupCard(group)
                }
            }
            .padding(16)
        }
        .background(Color.cyberBlack.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AdBannerFooterView()
        }
        .navigationTitle("アイコン設定")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Current Selected Icon Card
    private var currentSelectionBanner: some View {
        let current = iconManager.selectedIcon

        return HStack(spacing: 14) {
            Image(current.unlockedAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(Color.cyberCyan, lineWidth: 2)
                )
                .shadow(color: Color.cyberCyan.opacity(0.45), radius: 6)

            VStack(alignment: .leading, spacing: 4) {
                Text("ランキング表示アイコン")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.cyberCyan)

                Text("\(current.characterCodeName) — \(current.variantLabel)")
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)

                Text("解放済み: \(iconManager.unlockedIconIDs.count) / \(iconManager.allIcons.count)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.cyberEmerald)
            }

            Spacer()
        }
        .padding(14)
        .background(
            CyberShape(cutSize: 12)
                .fill(Color.cyberPanel)
                .overlay(
                    CyberShape(cutSize: 12)
                        .strokeBorder(Color.cyberCyan.opacity(0.5), lineWidth: 1.2)
                )
        )
    }

    // MARK: - Character Row Card (4 Icons)
    private func characterGroupCard(_ group: CharacterIconGroup) -> some View {
        let unlockedInGroup = group.icons.filter { iconManager.isUnlocked($0.id) }.count

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(group.codeName)
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(unlockedInGroup > 0 ? Color.cyberCyan : Color.white.opacity(0.55))

                Text("(\(unlockedInGroup)/\(group.icons.count))")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.45))

                Spacer()

                Text(group.subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .lineLimit(1)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(group.icons) { item in
                    iconCell(item)
                }
            }
        }
        .padding(14)
        .background(
            CyberShape(cutSize: 10)
                .fill(Color.cyberPanel)
                .overlay(
                    CyberShape(cutSize: 10)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - Single Icon Cell (Unlocked = Full Color / Locked = Gray Silhouette)
    private func iconCell(_ item: PlayerIconItem) -> some View {
        let unlocked = iconManager.isUnlocked(item.id)
        let isSelected = (iconManager.selectedIconID == item.id)

        return Button {
            if unlocked {
                iconManager.selectIcon(item.id)
                lockedHintText = nil
                HapticManager.playMedium(enabled: engine.isHapticsEnabled)
                // ランキング表示にも即座に選択アイコンを反映
                GameCenterManager.shared.refreshSelectedIconInRanking()
            } else {
                lockedHintText = "未解放：\(item.unlockConditionText)"
                HapticManager.playLight(enabled: engine.isHapticsEnabled)
            }
        } label: {
            VStack(spacing: 5) {
                ZStack(alignment: .bottomTrailing) {
                    Image(unlocked ? item.unlockedAssetName : item.lockedSilhouetteAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isSelected
                                        ? Color.cyberEmerald
                                        : (unlocked ? Color.white.opacity(0.22) : Color.white.opacity(0.08)),
                                    lineWidth: isSelected ? 2.8 : 1
                                )
                        )
                        .shadow(
                            color: isSelected ? Color.cyberEmerald.opacity(0.6) : .clear,
                            radius: 6
                        )

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color.cyberEmerald)
                            .background(Circle().fill(Color.black).padding(2))
                    } else if !unlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .padding(4)
                            .background(Circle().fill(Color.black.opacity(0.75)))
                    }
                }

                Text(item.variantLabel)
                    .font(.system(size: 10, weight: isSelected ? .black : .semibold, design: .monospaced))
                    .foregroundStyle(
                        isSelected
                            ? Color.cyberEmerald
                            : (unlocked ? Color.white.opacity(0.8) : Color.white.opacity(0.35))
                    )
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
