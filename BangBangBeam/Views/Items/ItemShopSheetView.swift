import SwiftUI

/// メニュー画面「ITEM」から開くポイント交換＆KUMITE持ち込み設定シート（最下部にバナー広告常設・日英リアルタイム切替対応）
struct ItemShopSheetView: View {
    @Bindable var engine: GameEngine
    @Bindable private var itemManager = ItemManager.shared
    @Bindable private var lang = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var statusBannerText: String? = nil

    var body: some View {
        let _ = lang.language
        let isKumiteSessionLockedWithActiveItem = (
            engine.hasSavedKumiteSession &&
            !engine.isPendingKumiteRevive &&
            itemManager.activeRunCarryInItem != nil
        )

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // MARK: 1. 所持ポイント ＆ 次戦KUMITE持ち込み・救急キット適用サマリーカード
                    loadoutSummaryCard(isLockedActiveItem: isKumiteSessionLockedWithActiveItem)

                    if let statusBannerText {
                        Text(statusBannerText)
                            .font(.system(size: 12.5, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.cyberCyan, in: RoundedRectangle(cornerRadius: 10))
                            .shadow(color: Color.cyberCyan.opacity(0.65), radius: 8)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }

                    // MARK: 2. バトル開始前アイテム（複数交換＆ストック可能・毎バトル前のVS画面で使用を選択）
                    sectionCard(
                        title: L10n("VS BOOST ITEMS // バトル開始前アイテム", "VS BOOST ITEMS // PER-BATTLE BOOSTS"),
                        subtitle: L10n(
                            "複数交換してストック可能！毎バトル前のVS画面で使用するかを選択できます（1バトルにつき1種類・1個のみ有効）",
                            "Exchange & stock multiple! Choose 1 item to activate on the VS screen before each battle (1 battle per use)."
                        )
                    ) {
                        VStack(spacing: 12) {
                            ForEach(BattleItem.vsBattleBoostItems) { item in
                                vsBoostItemRow(item: item)
                                if item != BattleItem.vsBattleBoostItems.last {
                                    Divider()
                                        .background(Color.white.opacity(0.12))
                                }
                            }
                        }
                    }

                    // MARK: 3. バトル中使用アイテム（所持品から1つ選んで次のKUMITEへ持ち込み）
                    sectionCard(
                        title: L10n("CARRY-IN ITEMS // KUMITE持ち込みアイテム", "CARRY-IN ITEMS // IN-BATTLE CONSUMABLES"),
                        subtitle: L10n(
                            "所持しているものの中から1つだけ次のKUMITEに持ち込めます（バトル中にREOのハート上のアイコンをタップして使用）",
                            "Equip 1 owned item for your next KUMITE run (Tap the icon above REO's hearts during battle to activate)."
                        )
                    ) {
                        VStack(spacing: 12) {
                            ForEach(BattleItem.carryInItems) { item in
                                carryInItemRow(
                                    item: item,
                                    isLockedActiveItem: isKumiteSessionLockedWithActiveItem
                                )
                                if item != BattleItem.carryInItems.last {
                                    Divider()
                                        .background(Color.white.opacity(0.12))
                                }
                            }
                        }
                    }

                    // MARK: 4. 救急キット一覧（交換と同時に自動適用・他アイテムと併用可）
                    sectionCard(
                        title: L10n("EMERGENCY MEDKITS // 救急キット", "EMERGENCY MEDKITS // REVIVE BOOST"),
                        subtitle: L10n(
                            "交換と同時に自動適用！持ち込みアイテム等とも併用できます（1回のKUMITEにつき1つのみ適用可能）",
                            "Applied automatically upon exchange! Stacks with other items (Limit 1 Medkit per KUMITE run)."
                        )
                    ) {
                        VStack(spacing: 12) {
                            ForEach(BattleItem.medkitItems) { medkit in
                                medkitItemRow(medkit: medkit)
                                if medkit != BattleItem.medkitItems.last {
                                    Divider()
                                        .background(Color.white.opacity(0.12))
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.cyberBlack.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                AdBannerFooterView()
            }
            .navigationTitle("ITEM")
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
        .animation(.easeInOut(duration: 0.2), value: statusBannerText)
        .preferredColorScheme(.dark)
    }

    // MARK: - Top Summary Card
    private func loadoutSummaryCard(isLockedActiveItem: Bool) -> some View {
        let effectiveCarryIn = itemManager.activeRunCarryInItem ?? itemManager.selectedCarryInItem
        let effectiveMedkit = itemManager.appliedMedkit

        return VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(Color.cyberAmber)
                        .shadow(color: Color.cyberAmber, radius: 6)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(L10n("所持ポイント", "Available Points"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.70))
                        Text(L10n("KUMITE 1勝ごとに +1 PT 獲得", "Earn +1 PT per KUMITE win"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.cyberCyan.opacity(0.85))
                    }
                }

                Spacer()

                Text("\(itemManager.points) PT")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(Color.cyberAmber)
                    .shadow(color: Color.cyberAmber.opacity(0.8), radius: 8)
            }

            Divider()
                .background(Color.cyberCyan.opacity(0.28))

            HStack(spacing: 10) {
                // スロット1：KUMITE持ち込み枠
                VStack(alignment: .leading, spacing: 6) {
                    Text(
                        isLockedActiveItem
                            ? L10n("現在KUMITE適用中", "ACTIVE IN KUMITE")
                            : L10n("次のKUMITE持ち込み", "NEXT KUMITE EQUIP")
                    )
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.cyberEmerald)

                    HStack(spacing: 8) {
                        if let item = effectiveCarryIn {
                            BattleItemIconView(item: item, size: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.displayName)
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)

                                if !isLockedActiveItem {
                                    Button {
                                        HapticManager.playLight(enabled: engine.isHapticsEnabled)
                                        itemManager.clearCarryInSelection()
                                    } label: {
                                        Text(L10n("外す", "Remove"))
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(Color.cyberDanger)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Text(L10n("連勝データに保持中", "Active in saved run"))
                                        .font(.system(size: 9.5, weight: .bold))
                                        .foregroundStyle(Color.cyberCyan)
                                }
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 9)
                                .strokeBorder(Color.white.opacity(0.24), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Color.white.opacity(0.35))
                                )

                            Text(L10n("未設定", "None"))
                                .font(.system(size: 12.5, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.5))
                        }

                        Spacer(minLength: 0)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color.black.opacity(0.40))
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .strokeBorder(Color.cyberEmerald.opacity(0.40), lineWidth: 1)
                        )
                )

                // スロット2：救急キット自動適用枠
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n("救急キット自動適用", "MEDKIT APPLIED"))
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.cyberCyan)

                    HStack(spacing: 8) {
                        if let medkit = effectiveMedkit {
                            BattleItemIconView(item: medkit, size: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(medkit.displayName)
                                    .font(.system(size: 12.5, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)

                                Text(L10n("リセット +\(medkit.bonusRevives)回", "Resets +\(medkit.bonusRevives)"))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(medkit.themeColor)
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 9)
                                .strokeBorder(Color.white.opacity(0.24), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "cross.case")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Color.white.opacity(0.35))
                                )

                            Text(L10n("未適用", "None"))
                                .font(.system(size: 12.5, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.5))
                        }

                        Spacer(minLength: 0)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color.black.opacity(0.40))
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .strokeBorder(Color.cyberCyan.opacity(0.40), lineWidth: 1)
                        )
                )
            }
        }
        .padding(15)
        .background(
            CyberShape(cutSize: 14)
                .fill(Color.cyberPanel)
                .overlay(
                    CyberShape(cutSize: 14)
                        .strokeBorder(Color.cyberAmber.opacity(0.55), lineWidth: 1.4)
                )
        )
    }

    // MARK: - Section 2: VS Screen Per-Battle Boost Item Row
    private func vsBoostItemRow(item: BattleItem) -> some View {
        let owned = itemManager.ownedCount(for: item)
        let canAfford = itemManager.points >= item.pointCost

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                BattleItemIconView(item: item, size: 48)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(item.displayName)
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Text(item.usageBadgeText)
                            .font(.system(size: 9.5, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(item.themeColor, in: Capsule())

                        Spacer()

                        Text(L10n("ストック: \(owned)個", "Stock: \(owned)"))
                            .font(.system(size: 11.5, weight: .black, design: .monospaced))
                            .foregroundStyle(owned > 0 ? Color.cyberEmerald : Color.white.opacity(0.45))
                    }

                    Text(item.effectDescription)
                        .font(.system(size: 12, weight: .medium))
                        .lineSpacing(2)
                        .foregroundStyle(Color.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                Button {
                    if itemManager.exchangeStockableItem(item) {
                        SoundManager.shared.playButtonSE()
                        HapticManager.playMedium(enabled: engine.isHapticsEnabled)
                        let newStock = itemManager.ownedCount(for: item)
                        showBanner(
                            L10n(
                                "「\(item.displayName)」を交換しました！（ストック: \(newStock)個）",
                                "Exchanged \(item.displayName)! (Stock: \(newStock))"
                            )
                        )
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11, weight: .black))
                        Text(L10n("交換 (\(item.pointCost) PT)", "Exchange (\(item.pointCost) PT)"))
                            .font(.system(size: 12.5, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(canAfford ? .black : Color.white.opacity(0.40))
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(canAfford ? Color.cyberAmber : Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 9)
                                    .strokeBorder(
                                        canAfford ? Color.cyberAmber : Color.white.opacity(0.16),
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canAfford)

                HStack(spacing: 4) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(L10n("VS画面で使用選択", "Select on VS Screen"))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundStyle(owned > 0 ? Color.cyberCyan : Color.white.opacity(0.38))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .strokeBorder(
                                    owned > 0 ? Color.cyberCyan.opacity(0.55) : Color.white.opacity(0.12),
                                    lineWidth: 1
                                )
                        )
                )
            }
        }
    }

    // MARK: - Section 3: Carry-in Item Row
    private func carryInItemRow(item: BattleItem, isLockedActiveItem: Bool) -> some View {
        let owned = itemManager.ownedCount(for: item)
        let canAfford = itemManager.points >= item.pointCost
        let isSelectedForNext = (itemManager.selectedCarryInItem == item)
        let isCurrentlyActiveInRun = (itemManager.activeRunCarryInItem == item)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                BattleItemIconView(item: item, size: 48)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(item.displayName)
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Text(item.usageBadgeText)
                            .font(.system(size: 9.5, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(item.themeColor, in: Capsule())

                        Spacer()

                        Text(L10n("所持: \(owned)個", "Owned: \(owned)"))
                            .font(.system(size: 11.5, weight: .black, design: .monospaced))
                            .foregroundStyle(owned > 0 ? Color.cyberEmerald : Color.white.opacity(0.45))
                    }

                    Text(item.effectDescription)
                        .font(.system(size: 12, weight: .medium))
                        .lineSpacing(2)
                        .foregroundStyle(Color.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                Button {
                    if itemManager.exchangeStockableItem(item) {
                        SoundManager.shared.playButtonSE()
                        HapticManager.playMedium(enabled: engine.isHapticsEnabled)
                        showBanner(
                            L10n(
                                "「\(item.displayName)」を交換しました！（-\(item.pointCost) PT）",
                                "Exchanged \(item.displayName)! (-\(item.pointCost) PT)"
                            )
                        )
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11, weight: .black))
                        Text(L10n("交換 (\(item.pointCost) PT)", "Exchange (\(item.pointCost) PT)"))
                            .font(.system(size: 12.5, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(canAfford ? .black : Color.white.opacity(0.40))
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(canAfford ? Color.cyberAmber : Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 9)
                                    .strokeBorder(
                                        canAfford ? Color.cyberAmber : Color.white.opacity(0.16),
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canAfford)

                if isLockedActiveItem {
                    Text(
                        isCurrentlyActiveInRun
                            ? L10n("✓ 現在適用中", "✓ Equipped")
                            : L10n("別アイテム適用中", "Slot Locked")
                    )
                    .font(.system(size: 11.5, weight: .black, design: .rounded))
                    .foregroundStyle(isCurrentlyActiveInRun ? Color.cyberCyan : Color.white.opacity(0.38))
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 9)
                                    .strokeBorder(
                                        isCurrentlyActiveInRun ? Color.cyberCyan.opacity(0.6) : Color.white.opacity(0.14),
                                        lineWidth: 1
                                    )
                            )
                    )
                } else {
                    Button {
                        HapticManager.playLight(enabled: engine.isHapticsEnabled)
                        SoundManager.shared.playButtonSE()
                        itemManager.toggleCarryInSelection(item)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isSelectedForNext ? "checkmark.circle.fill" : "bag.badge.plus")
                                .font(.system(size: 12, weight: .black))
                            Text(isSelectedForNext ? L10n("持ち込み中", "Equipped") : L10n("持ち込む", "Equip"))
                                .font(.system(size: 12.5, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(
                            isSelectedForNext
                                ? .black
                                : (owned > 0 ? Color.cyberEmerald : Color.white.opacity(0.35))
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(
                                    isSelectedForNext
                                        ? Color.cyberEmerald
                                        : (owned > 0 ? Color.cyberEmerald.opacity(0.14) : Color.white.opacity(0.06))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 9)
                                        .strokeBorder(
                                            isSelectedForNext
                                                ? Color.cyberEmerald
                                                : (owned > 0 ? Color.cyberEmerald.opacity(0.75) : Color.white.opacity(0.14)),
                                            lineWidth: isSelectedForNext ? 2 : 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(owned <= 0 && !isSelectedForNext)
                }
            }
        }
    }

    // MARK: - Section 4: Emergency Medkit Row
    private func medkitItemRow(medkit: BattleItem) -> some View {
        let alreadyHasMedkit = itemManager.hasAppliedMedkit
        let isThisApplied = (itemManager.appliedMedkit == medkit)
        let canExchange = !alreadyHasMedkit && (itemManager.points >= medkit.pointCost)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                BattleItemIconView(item: medkit, size: 48)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(medkit.displayName)
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text(medkit.usageBadgeText)
                            .font(.system(size: 9.5, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(medkit.themeColor, in: Capsule())

                        Spacer()
                    }

                    Text(medkit.effectDescription)
                        .font(.system(size: 12, weight: .medium))
                        .lineSpacing(2)
                        .foregroundStyle(Color.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button {
                if engine.exchangeAndApplyMedkit(medkit) {
                    SoundManager.shared.playButtonSE()
                    HapticManager.playHeavy(enabled: engine.isHapticsEnabled)
                    showBanner(
                        L10n(
                            "「\(medkit.displayName)」を交換・適用しました！リセット回数が +\(medkit.bonusRevives)回 増加！",
                            "Applied \(medkit.displayName)! Video-ad resets increased by +\(medkit.bonusRevives)!"
                        )
                    )
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isThisApplied ? "checkmark.seal.fill" : "arrow.triangle.2.circlepath.circle.fill")
                        .font(.system(size: 12, weight: .black))
                    Text(
                        isThisApplied
                            ? L10n("適用中（リセット +\(medkit.bonusRevives)回）", "Applied (Resets +\(medkit.bonusRevives))")
                            : (alreadyHasMedkit
                                ? L10n("他の救急キットが適用中", "Another Medkit is Active")
                                : L10n("交換して即時適用 (\(medkit.pointCost) PT)", "Exchange & Apply (\(medkit.pointCost) PT)"))
                    )
                    .font(.system(size: 13, weight: .black, design: .rounded))
                }
                .foregroundStyle(
                    isThisApplied
                        ? .black
                        : (canExchange ? .black : Color.white.opacity(0.40))
                )
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(
                            isThisApplied
                                ? medkit.themeColor
                                : (canExchange ? Color.cyberCyan : Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .strokeBorder(
                                    isThisApplied
                                        ? medkit.themeColor
                                        : (canExchange ? Color.cyberCyan : Color.white.opacity(0.16)),
                                    lineWidth: 1.2
                                )
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(!canExchange)
        }
    }

    private func sectionCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.cyberCyan)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }

            content()
        }
        .padding(15)
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

    private func showBanner(_ text: String) {
        statusBannerText = text
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.4))
            if statusBannerText == text {
                statusBannerText = nil
            }
        }
    }
}
