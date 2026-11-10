import SwiftUI
import AppTrackingTransparency
import Observation

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

/// Google AdMob 広告管理マネージャー（バナー広告 ＆ KUMITE敗北時の復活リワード動画広告）
/// - 本番用広告IDはソースコードにハードコードせず Info.plist（Build Settings / xcconfig 経由）から動的に取得する。
/// - DEBUGビルド時は AdMob 規約遵守（自己クリック・無効トラフィック防止）のため Google 公式テスト広告ユニットIDを使用する。
@Observable
@MainActor
final class AdManager: NSObject {
    static let shared = AdManager()

    var isLoadingRewardedAd: Bool = false
    var rewardedAdStatusMessage: String? = nil

    private var pendingRewardHandler: (() -> Void)? = nil
    private var didEarnRewardInCurrentSession: Bool = false

    /// Google公式 iOS テスト用広告ユニットID（DEBUG時・未設定時のフォールバック用）
    private static let testBannerUnitID = "ca-app-pub-3940256099942544/2435281174"
    private static let testRewardedUnitID = "ca-app-pub-3940256099942544/1712485313"

    /// バナー広告ユニットIDの安全な動的解決（Info.plist -> ADMOB_BANNER_UNIT_ID）
    var bannerAdUnitID: String {
        #if DEBUG
        return Self.testBannerUnitID
        #else
        if let prodID = Bundle.main.object(forInfoDictionaryKey: "ADMOB_BANNER_UNIT_ID") as? String {
            let trimmed = prodID.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, !trimmed.hasPrefix("$(") {
                return trimmed
            }
        }
        return Self.testBannerUnitID
        #endif
    }

    /// リワード動画広告ユニットIDの安全な動的解決（Info.plist -> ADMOB_REWARDED_UNIT_ID）
    var rewardedAdUnitID: String {
        #if DEBUG
        return Self.testRewardedUnitID
        #else
        if let prodID = Bundle.main.object(forInfoDictionaryKey: "ADMOB_REWARDED_UNIT_ID") as? String {
            let trimmed = prodID.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, !trimmed.hasPrefix("$(") {
                return trimmed
            }
        }
        return Self.testRewardedUnitID
        #endif
    }

    #if canImport(GoogleMobileAds)
    private var rewardedAd: RewardedAd? = nil
    #endif

    private override init() {
        super.init()
    }

    /// アプリ起動時の AdMob SDK 初期化 & ATT トラッキング許可リクエスト
    func startSDKAndRequestATT() {
        #if canImport(GoogleMobileAds)
        // AdMob SDK が勝手に AVAudioSession カテゴリを書き換えて消音モードを貫通させないようアプリ側管理に固定
        MobileAds.shared.audioVideoManager.isAudioSessionApplicationManaged = true
        MobileAds.shared.start(completionHandler: nil)
        SoundManager.shared.ensureAudioSessionActive()
        loadRewardedAd()
        #endif

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.0))
            if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                _ = await ATTrackingManager.requestTrackingAuthorization()
                #if canImport(GoogleMobileAds)
                loadRewardedAd()
                #endif
            }
        }
    }

    #if canImport(GoogleMobileAds)
    func loadRewardedAd(onLoaded: (() -> Void)? = nil) {
        guard !isLoadingRewardedAd else { return }
        isLoadingRewardedAd = true
        RewardedAd.load(with: rewardedAdUnitID, request: Request()) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoadingRewardedAd = false
                if let ad {
                    self.rewardedAd = ad
                    self.rewardedAd?.fullScreenContentDelegate = self
                    self.rewardedAdStatusMessage = nil
                    onLoaded?()
                } else if let error {
                    self.rewardedAd = nil
                    self.rewardedAdStatusMessage = L10n(
                        "動画広告の読み込みに失敗しました（\(error.localizedDescription)）。通信状況を確認して再度お試しください。",
                        "Failed to load video ad (\(error.localizedDescription)). Check your connection and try again."
                    )
                }
            }
        }
    }
    #endif

    /// KUMITE敗北時の「動画広告を見て復活」ボタン押下時に呼び出す
    /// 最後まで視聴して報酬条件を満たした場合のみ `onRewardEarned` を実行し、連勝維持で再戦させる
    func presentRewardedAdForRevive(onRewardEarned: @escaping () -> Void) {
        rewardedAdStatusMessage = nil

        #if canImport(GoogleMobileAds)
        if let ad = rewardedAd, let topVC = Self.topViewController() {
            presentLoadedRewardedAd(ad, from: topVC, onRewardEarned: onRewardEarned)
            return
        }

        // 未ロードの場合は即座に再ロードを試みて表示
        loadRewardedAd { [weak self] in
            guard let self,
                  let ad = self.rewardedAd,
                  let topVC = Self.topViewController() else {
                return
            }
            self.presentLoadedRewardedAd(ad, from: topVC, onRewardEarned: onRewardEarned)
        }
        #else
        rewardedAdStatusMessage = L10n(
            "現在動画広告を利用できません。通信環境をご確認のうえ再度お試しください。",
            "Video ad is currently unavailable. Please check your connection and try again."
        )
        #endif
    }

    #if canImport(GoogleMobileAds)
    private func presentLoadedRewardedAd(
        _ ad: RewardedAd,
        from topVC: UIViewController,
        onRewardEarned: @escaping () -> Void
    ) {
        pendingRewardHandler = onRewardEarned
        didEarnRewardInCurrentSession = false
        SoundManager.shared.setDucked(true)
        ad.present(from: topVC) { [weak self] in
            Task { @MainActor [weak self] in
                self?.didEarnRewardInCurrentSession = true
            }
        }
    }
    #endif

    static func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let rootVC = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        var top = rootVC
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}

#if canImport(GoogleMobileAds)
extension AdManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            SoundManager.shared.ensureAudioSessionActive(forceSetActive: true)
            SoundManager.shared.setDucked(false)
            self.rewardedAd = nil
            let earned = self.didEarnRewardInCurrentSession
            let handler = self.pendingRewardHandler
            self.pendingRewardHandler = nil
            self.didEarnRewardInCurrentSession = false
            self.loadRewardedAd()
            if earned {
                handler?()
            }
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            SoundManager.shared.ensureAudioSessionActive(forceSetActive: true)
            SoundManager.shared.setDucked(false)
            self.rewardedAd = nil
            self.pendingRewardHandler = nil
            self.didEarnRewardInCurrentSession = false
            self.rewardedAdStatusMessage = L10n(
                "動画広告を表示できませんでした。通信環境をご確認のうえ再度お試しください。",
                "Unable to display video ad. Check your connection and try again."
            )
            self.loadRewardedAd()
        }
    }
}
#endif
