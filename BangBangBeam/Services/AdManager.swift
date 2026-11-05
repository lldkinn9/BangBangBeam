import SwiftUI
import AppTrackingTransparency
import Observation

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

/// Google AdMob 広告管理マネージャー（バナー広告 & リトライ時インタースティシャル広告）
/// - 本番用広告IDはソースコードにハードコードせず Info.plist 設定値から動的に取得する。
/// - DEBUGビルド時は AdMob 規約遵守のため Google 公式テスト広告ユニットIDを使用する。
@Observable
@MainActor
final class AdManager: NSObject {
    static let shared = AdManager()

    /// リトライ何回につき1回インタースティシャル広告を表示するか（仕様: 2〜3回に1回）
    let retryAdFrequency: Int = 3

    private(set) var retryCounter: Int = 0
    var isPresentingFallbackInterstitial: Bool = false
    private var pendingInterstitialCompletion: (() -> Void)? = nil

    /// バナー広告ユニットIDの安全な解決
    var bannerAdUnitID: String {
        #if DEBUG
        // Google公式 iOS テスト用バナー広告ユニットID
        return "ca-app-pub-3940256099942544/2435281174"
        #else
        if let prodID = Bundle.main.object(forInfoDictionaryKey: "ADMOB_BANNER_UNIT_ID") as? String,
           !prodID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return prodID
        }
        return "ca-app-pub-3940256099942544/2435281174"
        #endif
    }

    /// インタースティシャル広告ユニットIDの安全な解決
    var interstitialAdUnitID: String {
        #if DEBUG
        // Google公式 iOS テスト用インタースティシャル広告ユニットID
        return "ca-app-pub-3940256099942544/4411468910"
        #else
        if let prodID = Bundle.main.object(forInfoDictionaryKey: "ADMOB_INTERSTITIAL_UNIT_ID") as? String,
           !prodID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return prodID
        }
        return "ca-app-pub-3940256099942544/4411468910"
        #endif
    }

    #if canImport(GoogleMobileAds)
    private var interstitialAd: InterstitialAd? = nil
    #endif

    private override init() {
        super.init()
    }

    /// アプリ起動時の AdMob SDK 初期化 & ATT トラッキング許可リクエスト
    func startSDKAndRequestATT() {
        #if canImport(GoogleMobileAds)
        MobileAds.shared.start(completionHandler: nil)
        loadInterstitial()
        #endif

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.0))
            if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                _ = await ATTrackingManager.requestTrackingAuthorization()
                #if canImport(GoogleMobileAds)
                loadInterstitial()
                #endif
            }
        }
    }

    #if canImport(GoogleMobileAds)
    func loadInterstitial() {
        InterstitialAd.load(with: interstitialAdUnitID, request: Request()) { [weak self] ad, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.interstitialAd = ad
                self.interstitialAd?.fullScreenContentDelegate = self
            }
        }
    }
    #endif

    /// リトライ実行時に呼び出し、所定回数に達していればスキップ可能な全画面広告を表示後に completion を実行する
    func handleRetryWithAdIfNeeded(completion: @escaping () -> Void) {
        retryCounter += 1
        guard retryCounter % retryAdFrequency == 0 else {
            completion()
            return
        }

        #if canImport(GoogleMobileAds)
        if let ad = interstitialAd, let topVC = Self.topViewController() {
            pendingInterstitialCompletion = completion
            SoundManager.shared.setDucked(true)
            ad.present(from: topVC)
            return
        } else {
            loadInterstitial()
            completion()
            return
        }
        #else
        // GoogleMobileAds Swift Package 未リンク時の開発レイアウト確認シート（偽装せず未リンク状態を明示）
        pendingInterstitialCompletion = completion
        SoundManager.shared.setDucked(true)
        isPresentingFallbackInterstitial = true
        #endif
    }

    func dismissFallbackInterstitial() {
        isPresentingFallbackInterstitial = false
        SoundManager.shared.setDucked(false)
        let action = pendingInterstitialCompletion
        pendingInterstitialCompletion = nil
        action?()
    }

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
            SoundManager.shared.setDucked(false)
            self.interstitialAd = nil
            self.loadInterstitial()
            let action = self.pendingInterstitialCompletion
            self.pendingInterstitialCompletion = nil
            action?()
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            SoundManager.shared.setDucked(false)
            self.interstitialAd = nil
            self.loadInterstitial()
            let action = self.pendingInterstitialCompletion
            self.pendingInterstitialCompletion = nil
            action?()
        }
    }
}
#endif
