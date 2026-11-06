import SwiftUI

/// 全84個からアイコンを選択する「アイコン設定」画面（最上部の選択中アイコン枠＆メッセージ枠はスクロール固定）
struct IconSettingView: View {
    @Bindable var engine: GameEngine
    @Bindable private var iconManager = PlayerIconManager.shared
    @State private var statusMessageText: String = "未解放シルエットをタップすると解放条件を確認できます"
    @State private var isLockedWarning: Bool = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 1. スクロール固定ヘッダー（現在のアイコン枠 ＋ メッセージ枠）
            VStack(spacing: 10) {
                currentSelectionBanner
                pinnedMessageBanner
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(Color.cyberBlack)

            Divider()
                .background(Color.cyberCyan.opacity(0.25))

            // MARK: 2. スクロール可能な全キャラクター別 4列アイコングリッド
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(iconManager.characterGroups) { group in
                        characterGroupCard(group)
                    }
                }
                .padding(16)
            }
        }
        .background(Color.cyberBlack.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AdBannerFooterView()
        }
        .navigationTitle("アイコン設定")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Pinned Current Selected Icon Card
    private var currentSelectionBanner: some View {
        let current = iconManager.selectedIcon

        return HStack(spacing: 14) {
            Image(current.unlockedAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(Color.cyberCyan, lineWidth: 2)
                )
                .shadow(color: Color.cyberCyan.opacity(0.45), radius: 6)

            VStack(alignment: .leading, spacing: 3) {
                Text("現在の設定アイコン（ランキング反映）")
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
        .padding(12)
        .background(
            CyberShape(cutSize: 12)
                .fill(Color.cyberPanel)
                .overlay(
                    CyberShape(cutSize: 12)
                        .strokeBorder(Color.cyberCyan.opacity(0.5), lineWidth: 1.2)
                )
        )
    }

    // MARK: - Pinned Message Banner (未解放メッセージ等もスクロールせず常時表示)
    private var pinnedMessageBanner: some View {
        let accent: Color = isLockedWarning ? .cyberAmber : .cyberCyan

        return HStack(spacing: 8) {
            Image(systemName: isLockedWarning ? "lock.fill" : "info.circle.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(accent)

            Text(statusMessageText)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isLockedWarning ? Color.white : Color.white.opacity(0.82))
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(isLockedWarning ? Color.cyberAmber.opacity(0.16) : Color.cyberPanel)
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(
                            isLockedWarning ? Color.cyberAmber.opacity(0.6) : Color.white.opacity(0.14),
                            lineWidth: 1
                        )
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
                isLockedWarning = false
                statusMessageText = "\(item.characterCodeName)（\(item.variantLabel)）をアイコンに設定しました"
                HapticManager.playMedium(enabled: engine.isHapticsEnabled)
                GameCenterManager.shared.refreshSelectedIconInRanking()
            } else {
                isLockedWarning = true
                statusMessageText = "未解放：\(item.unlockConditionText)"
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
