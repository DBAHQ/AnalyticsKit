//
//  AnalyticsManager.swift
//  AnalyticsKit
//
//  Единая точка входа: раздаёт события провайдерам и владеет жизненным
//  циклом сессии. Приложение зовёт его методы напрямую — сигнатуры те же,
//  что были у AnalyticsManager внутри приложений.
//

import Foundation

public final class AnalyticsManager: AnalyticsProvider {

    // MARK: - Static Properties

    public static let shared = AnalyticsManager()

    // MARK: - Properties

    /// Порядок сохранён с доперенесённой версии: Adjust, Firebase, AppMetrica.
    private var providers: [AnalyticsProvider] = [AdjustAnalyticsProvider(),
                                                  FirebaseAnalyticsProvider(),
                                                  AppMetricaAnalyticsProvider()]

    public var userID: String { AnalyticsKit.configuration.userID() }

    private static var isInitialized = false

    // MARK: - Session State

    private var isSessionActive = false
    private var sessionStartTime: TimeInterval = 0

    private enum SessionKeys {
        static let pendingTrigger    = "AnalyticsPendingSessionTrigger"
        static let pendingTextNumber = "AnalyticsPendingSessionTextNumber"
        static let pendingCode       = "AnalyticsPendingSessionCode"
    }

    private init() {}

    // MARK: - Lifecycle

    public func start() {
        guard !AnalyticsManager.isInitialized else { return }
        AnalyticsManager.isInitialized = true

        providers.forEach { $0.start() }

        AdRevenueBackendProvider.shared.start()

        checkAndTrackInstall()
    }

    /// Adjust v5: первая сессия придержана до ответа по ATT. Зовётся из
    /// рекламной инициализации, после того как уехали DMA-согласия.
    public func endAdjustFirstSessionDelay() {
        AdjustAnalyticsProvider.endFirstSessionDelay()
    }

    // MARK: - Session Lifecycle

    public func applicationDidBecomeActive() {
        let info = getPendingSessionTrigger()
        clearPendingSessionTrigger()
        guard !isSessionActive else { return }
        isSessionActive = true
        sessionStartTime = Date().timeIntervalSince1970
        AppLovinEventTracker.shared.trackAppOpen()
        providers.forEach {
            $0.trackSessionStart(trigger: info.trigger, textNumber: info.textNumber, code: info.code)
        }
    }

    public func applicationDidEnterBackground() {
        guard isSessionActive else { return }
        let duration = Date().timeIntervalSince1970 - sessionStartTime
        isSessionActive = false
        sessionStartTime = 0
        providers.forEach { $0.trackSessionFinish(duration: duration) }
    }

    public func setPendingSessionTrigger(userInfo: [AnyHashable: Any]?) {
        guard let userInfo = userInfo,
              let noticeSubtype = userInfo["type"] as? String,
              let textNumber = userInfo["textNumber"] as? String else { return }

        var code: String? = nil
        if let payloadString = userInfo["payload"] as? String,
           let payloadData = payloadString.data(using: .utf8),
           let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] {
            code = payload["symbol"] as? String
        } else if let payload = userInfo["payload"] as? [String: Any] {
            code = payload["symbol"] as? String
        }

        UserDefaults.standard.set(noticeSubtype, forKey: SessionKeys.pendingTrigger)
        UserDefaults.standard.set(textNumber, forKey: SessionKeys.pendingTextNumber)
        if let code { UserDefaults.standard.set(code, forKey: SessionKeys.pendingCode) }
    }

    private func getPendingSessionTrigger() -> (trigger: String, textNumber: String, code: String) {
        return (
            UserDefaults.standard.string(forKey: SessionKeys.pendingTrigger) ?? "simple",
            UserDefaults.standard.string(forKey: SessionKeys.pendingTextNumber) ?? "nil",
            UserDefaults.standard.string(forKey: SessionKeys.pendingCode) ?? "nil"
        )
    }

    private func clearPendingSessionTrigger() {
        UserDefaults.standard.removeObject(forKey: SessionKeys.pendingTrigger)
        UserDefaults.standard.removeObject(forKey: SessionKeys.pendingTextNumber)
        UserDefaults.standard.removeObject(forKey: SessionKeys.pendingCode)
    }

    private func checkAndTrackInstall() {
        guard AnalyticsKit.configuration.isFirstLaunch() else { return }
        providers.forEach { $0.trackInstall() }
    }

    /// Рекламный SDK поднялся: отпускаем накопленные события AppLovin.
    public func adSDKDidInitialize() {
        AppLovinEventTracker.shared.sdkDidInitialize()
    }

    // MARK: - Session Protocol Stubs

    // Менеджер сам инициирует эти события, поэтому наружу они не раздаются.
    public func trackSessionStart(trigger: String, textNumber: String, code: String) {}
    public func trackSessionFinish(duration: Double) {}
    public func trackInstall() {}

    // MARK: - Fan-out

    public func onboardingBegin() {
        providers.forEach { $0.onboardingBegin() }
    }

    public func onboardingStepPresent(step: String) {
        providers.forEach { $0.onboardingStepPresent(step: step) }
    }

    public func onboardingStepContinue(step: String) {
        providers.forEach { $0.onboardingStepContinue(step: step) }
    }

    public func onboardingComplete() {
        providers.forEach { $0.onboardingComplete() }
    }

    public func featureTutorialBegin(flow: String) {
        providers.forEach { $0.featureTutorialBegin(flow: flow) }
    }

    public func featureTutorialStepPresent(flow: String, step: String) {
        providers.forEach { $0.featureTutorialStepPresent(flow: flow, step: step) }
    }

    public func featureTutorialStepContinue(flow: String, step: String) {
        providers.forEach { $0.featureTutorialStepContinue(flow: flow, step: step) }
    }

    public func featureTutorialSkip(flow: String, step: String) {
        providers.forEach { $0.featureTutorialSkip(flow: flow, step: step) }
    }

    public func featureTutorialComplete(flow: String) {
        providers.forEach { $0.featureTutorialComplete(flow: flow) }
    }

    public func trackAuthDidPresent() {
        providers.forEach { $0.trackAuthDidPresent() }
    }

    public func trackAuthDidDismiss(timespent: Double) {
        providers.forEach { $0.trackAuthDidDismiss(timespent: timespent) }
    }

    public func trackAuthSignIn() {
        providers.forEach { $0.trackAuthSignIn() }
    }

    public func trackAuthSignUpBegin() {
        providers.forEach { $0.trackAuthSignUpBegin() }
    }

    public func trackAuthSignUpComplete() {
        providers.forEach { $0.trackAuthSignUpComplete() }
    }

    public func trackAuthOAuthBegin(_ type: String) {
        providers.forEach { $0.trackAuthOAuthBegin(type) }
    }

    public func trackAuthOAuthComplete(_ type: String) {
        providers.forEach { $0.trackAuthOAuthComplete(type) }
    }

    public func trackDashboardDidPresent() {
        providers.forEach { $0.trackDashboardDidPresent() }
    }

    public func trackDashboardDidDismiss(timespent: Double) {
        providers.forEach { $0.trackDashboardDidDismiss(timespent: timespent) }
    }

    public func trackDashboardDidTapSettings() {
        providers.forEach { $0.trackDashboardDidTapSettings() }
    }

    public func trackDashboardDidTapSignUp() {
        providers.forEach { $0.trackDashboardDidTapSignUp() }
    }

    public func trackDashboardDidTapProfile() {
        providers.forEach { $0.trackDashboardDidTapProfile() }
    }

    public func trackDashboardDidTapNotifications() {
        providers.forEach { $0.trackDashboardDidTapNotifications() }
    }

    public func trackDashboardDidTapBalance() {
        providers.forEach { $0.trackDashboardDidTapBalance() }
    }

    public func trackDashboardDidTapBonusAd() {
        providers.forEach { $0.trackDashboardDidTapBonusAd() }
    }

    public func trackDashboardDidTapDailyRewards() {
        providers.forEach { $0.trackDashboardDidTapDailyRewards() }
    }

    public func trackDashboardDidTapLuckySpin() {
        providers.forEach { $0.trackDashboardDidTapLuckySpin() }
    }

    public func trackDashboardDidTapChallenges() {
        providers.forEach { $0.trackDashboardDidTapChallenges() }
    }

    public func trackDashboardDidTapDemoAccount() {
        providers.forEach { $0.trackDashboardDidTapDemoAccount() }
    }

    public func trackDashboardDidTapShop() {
        providers.forEach { $0.trackDashboardDidTapShop() }
    }

    public func trackDashboardDidTapPremium() {
        providers.forEach { $0.trackDashboardDidTapPremium() }
    }

    public func trackDashboardDidTapAuction() {
        providers.forEach { $0.trackDashboardDidTapAuction() }
    }

    public func trackDashboardDidTapAppearance() {
        providers.forEach { $0.trackDashboardDidTapAppearance() }
    }

    public func trackDashboardDidTapStaking() {
        providers.forEach { $0.trackDashboardDidTapStaking() }
    }

    public func trackDashboardDidTapSlots() {
        providers.forEach { $0.trackDashboardDidTapSlots() }
    }

    public func trackTradingPortfolioDidPresent(isTournament: Bool) {
        providers.forEach { $0.trackTradingPortfolioDidPresent(isTournament: isTournament) }
    }

    public func trackTradingPortfolioDidDismiss(isTournament: Bool, timespent: Double) {
        providers.forEach { $0.trackTradingPortfolioDidDismiss(isTournament: isTournament, timespent: timespent) }
    }

    public func trackTradingPortfolioDidTap(isTournament: Bool, symbol: String) {
        providers.forEach { $0.trackTradingPortfolioDidTap(isTournament: isTournament, symbol: symbol) }
    }

    public func trackTradingMarketDidPresent(isTournament: Bool) {
        providers.forEach { $0.trackTradingMarketDidPresent(isTournament: isTournament) }
    }

    public func trackTradingMarketDidDismiss(isTournament: Bool, timespent: Double) {
        providers.forEach { $0.trackTradingMarketDidDismiss(isTournament: isTournament, timespent: timespent) }
    }

    public func trackTradingMarketDidTap(isTournament: Bool, symbol: String) {
        providers.forEach { $0.trackTradingMarketDidTap(isTournament: isTournament, symbol: symbol) }
    }

    public func trackTradingTradesDidPresent(isTournament: Bool) {
        providers.forEach { $0.trackTradingTradesDidPresent(isTournament: isTournament) }
    }

    public func trackTradingTradesDidDismiss(isTournament: Bool, timespent: Double) {
        providers.forEach { $0.trackTradingTradesDidDismiss(isTournament: isTournament, timespent: timespent) }
    }

    public func trackTradingTradesDidTap(isTournament: Bool, symbol: String) {
        providers.forEach { $0.trackTradingTradesDidTap(isTournament: isTournament, symbol: symbol) }
    }

    public func trackTradingOrdersDidPresent(isTournament: Bool) {
        providers.forEach { $0.trackTradingOrdersDidPresent(isTournament: isTournament) }
    }

    public func trackTradingOrdersDidDismiss(isTournament: Bool, timespent: Double) {
        providers.forEach { $0.trackTradingOrdersDidDismiss(isTournament: isTournament, timespent: timespent) }
    }

    public func trackTradingOrdersDidTap(isTournament: Bool, symbol: String, type: String) {
        providers.forEach { $0.trackTradingOrdersDidTap(isTournament: isTournament, symbol: symbol, type: type) }
    }

    public func trackAssetTradingDidPresent(isTournament: Bool, symbol: String) {
        providers.forEach { $0.trackAssetTradingDidPresent(isTournament: isTournament, symbol: symbol) }
    }

    public func trackAssetTradingDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        providers.forEach { $0.trackAssetTradingDidDismiss(isTournament: isTournament, symbol: symbol, timespent: timespent) }
    }

    public func trackAssetTradingDidTapProChart(isTournament: Bool, symbol: String) {
        providers.forEach { $0.trackAssetTradingDidTapProChart(isTournament: isTournament, symbol: symbol) }
    }

    public func trackAssetTradingDidTapBonusAd(isTournament: Bool, symbol: String) {
        providers.forEach { $0.trackAssetTradingDidTapBonusAd(isTournament: isTournament, symbol: symbol) }
    }

    public func trackAssetTradingDidTapBuy(isTournament: Bool, symbol: String) {
        providers.forEach { $0.trackAssetTradingDidTapBuy(isTournament: isTournament, symbol: symbol) }
    }

    public func trackAssetTradingDidTapSell(isTournament: Bool, symbol: String) {
        providers.forEach { $0.trackAssetTradingDidTapSell(isTournament: isTournament, symbol: symbol) }
    }

    public func trackAssetTradesDidPresent(isTournament: Bool, symbol: String) {
        providers.forEach { $0.trackAssetTradesDidPresent(isTournament: isTournament, symbol: symbol) }
    }

    public func trackAssetTradesDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        providers.forEach { $0.trackAssetTradesDidDismiss(isTournament: isTournament, symbol: symbol, timespent: timespent) }
    }

    public func trackAssetTradesDidTap(isTournament: Bool, symbol: String) {
        providers.forEach { $0.trackAssetTradesDidTap(isTournament: isTournament, symbol: symbol) }
    }

    public func trackAssetOrdersDidPresent(isTournament: Bool, symbol: String) {
        providers.forEach { $0.trackAssetOrdersDidPresent(isTournament: isTournament, symbol: symbol) }
    }

    public func trackAssetOrdersDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        providers.forEach { $0.trackAssetOrdersDidDismiss(isTournament: isTournament, symbol: symbol, timespent: timespent) }
    }

    public func trackAssetOrdersDidTap(isTournament: Bool, symbol: String, type: String) {
        providers.forEach { $0.trackAssetOrdersDidTap(isTournament: isTournament, symbol: symbol, type: type) }
    }

    public func trackAssetTradeDetailDidPresent(isTournament: Bool, symbol: String) {
        providers.forEach { $0.trackAssetTradeDetailDidPresent(isTournament: isTournament, symbol: symbol) }
    }

    public func trackAssetTradeDetailDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        providers.forEach { $0.trackAssetTradeDetailDidDismiss(isTournament: isTournament, symbol: symbol, timespent: timespent) }
    }

    public func trackAssetOrderDetailDidPresent(isTournament: Bool, symbol: String) {
        providers.forEach { $0.trackAssetOrderDetailDidPresent(isTournament: isTournament, symbol: symbol) }
    }

    public func trackAssetOrderDetailDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        providers.forEach { $0.trackAssetOrderDetailDidDismiss(isTournament: isTournament, symbol: symbol, timespent: timespent) }
    }

    public func trackNewOrderDidPresent(isTournament: Bool, symbol: String) {
        providers.forEach { $0.trackNewOrderDidPresent(isTournament: isTournament, symbol: symbol) }
    }

    public func trackNewOrderDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        providers.forEach { $0.trackNewOrderDidDismiss(isTournament: isTournament, symbol: symbol, timespent: timespent) }
    }

    public func trackNewOrderDidSelectBuy(isTournament: Bool, symbol: String) {
        providers.forEach { $0.trackNewOrderDidSelectBuy(isTournament: isTournament, symbol: symbol) }
    }

    public func trackNewOrderDidSelectSell(isTournament: Bool, symbol: String) {
        providers.forEach { $0.trackNewOrderDidSelectSell(isTournament: isTournament, symbol: symbol) }
    }

    public func trackNewOrderDidSend(isTournament: Bool, symbol: String, amount: Decimal, takeProfit: Decimal, stopLoss: Decimal) {
        providers.forEach { $0.trackNewOrderDidSend(isTournament: isTournament, symbol: symbol, amount: amount, takeProfit: takeProfit, stopLoss: stopLoss) }
    }

    public func trackAuctionDidPresent() {
        providers.forEach { $0.trackAuctionDidPresent() }
    }

    public func trackAuctionDidDismiss(timespent: Double) {
        providers.forEach { $0.trackAuctionDidDismiss(timespent: timespent) }
    }

    public func trackAuctionDidPlaceBid(amount: Decimal) {
        providers.forEach { $0.trackAuctionDidPlaceBid(amount: amount) }
    }

    public func trackDailyRewardsDidPresent() {
        providers.forEach { $0.trackDailyRewardsDidPresent() }
    }

    public func trackDailyRewardsDidDismiss(timespent: Double) {
        providers.forEach { $0.trackDailyRewardsDidDismiss(timespent: timespent) }
    }

    public func trackDailyRewardsDidReceiveReward(day: Int) {
        providers.forEach { $0.trackDailyRewardsDidReceiveReward(day: day) }
    }

    public func trackDailyRewardsDidMultiplyReward(day: Int) {
        providers.forEach { $0.trackDailyRewardsDidMultiplyReward(day: day) }
    }

    public func trackLuckySpinDidPresent() {
        providers.forEach { $0.trackLuckySpinDidPresent() }
    }

    public func trackLuckySpinDidDismiss(timespent: Double) {
        providers.forEach { $0.trackLuckySpinDidDismiss(timespent: timespent) }
    }

    public func trackLuckySpinDidSpin() {
        providers.forEach { $0.trackLuckySpinDidSpin() }
    }

    public func trackProfileDidPresent() {
        providers.forEach { $0.trackProfileDidPresent() }
    }

    public func trackProfileDidTapAvatar() {
        providers.forEach { $0.trackProfileDidTapAvatar() }
    }

    public func trackProfileDidTapAvatarEdit() {
        providers.forEach { $0.trackProfileDidTapAvatarEdit() }
    }

    public func trackAvatarDidPresent() {
        providers.forEach { $0.trackAvatarDidPresent() }
    }

    public func trackAvatarDidDismiss(timespent: Double) {
        providers.forEach { $0.trackAvatarDidDismiss(timespent: timespent) }
    }

    public func trackAvatarDidTapChange() {
        providers.forEach { $0.trackAvatarDidTapChange() }
    }

    public func trackUserProfileOtherDidPresent() {
        providers.forEach { $0.trackUserProfileOtherDidPresent() }
    }

    public func trackSlotsDidPresent() {
        providers.forEach { $0.trackSlotsDidPresent() }
    }

    public func trackSlotsDidDismiss(timespent: Double) {
        providers.forEach { $0.trackSlotsDidDismiss(timespent: timespent) }
    }

    public func trackSlotsDidSpin(slotsCount: Int, totalSlotsCount: Int) {
        providers.forEach { $0.trackSlotsDidSpin(slotsCount: slotsCount, totalSlotsCount: totalSlotsCount) }
    }

    public func trackSlotsDidLoad(loadingTime: Double) {
        providers.forEach { $0.trackSlotsDidLoad(loadingTime: loadingTime) }
    }

    public func trackShopDidPresent() {
        providers.forEach { $0.trackShopDidPresent() }
    }

    public func trackShopDidDismiss(timespent: Double) {
        providers.forEach { $0.trackShopDidDismiss(timespent: timespent) }
    }

    public func trackShopItemDidPresent(id: String, price: Decimal) {
        providers.forEach { $0.trackShopItemDidPresent(id: id, price: price) }
    }

    public func trackShopItemDidDismiss(id: String, price: Decimal, timespent: Double) {
        providers.forEach { $0.trackShopItemDidDismiss(id: id, price: price, timespent: timespent) }
    }

    public func trackShopItemDidPurchase(id: String, price: Decimal) {
        providers.forEach { $0.trackShopItemDidPurchase(id: id, price: price) }
    }

    public func trackRatingDidPresent(isTournament: Bool) {
        providers.forEach { $0.trackRatingDidPresent(isTournament: isTournament) }
    }

    public func trackRatingDidDismiss(isTournament: Bool, timespent: Double) {
        providers.forEach { $0.trackRatingDidDismiss(isTournament: isTournament, timespent: timespent) }
    }

    public func trackTournamentWelcomeDidPresent() {
        providers.forEach { $0.trackTournamentWelcomeDidPresent() }
    }

    public func trackTournamentWelcomeDidDismiss(timespent: Double) {
        providers.forEach { $0.trackTournamentWelcomeDidDismiss(timespent: timespent) }
    }

    public func trackTournamentWelcomeSignUp() {
        providers.forEach { $0.trackTournamentWelcomeSignUp() }
    }

    public func trackTournamentDidPresent() {
        providers.forEach { $0.trackTournamentDidPresent() }
    }

    public func trackTournamentDidDismiss(timespent: Double) {
        providers.forEach { $0.trackTournamentDidDismiss(timespent: timespent) }
    }

    public func trackChallengesDidPresent() {
        providers.forEach { $0.trackChallengesDidPresent() }
    }

    public func trackChallengesDidDismiss(timespent: Double) {
        providers.forEach { $0.trackChallengesDidDismiss(timespent: timespent) }
    }

    public func trackChallengesAwardDidReceive(id: String, level: Int) {
        providers.forEach { $0.trackChallengesAwardDidReceive(id: id, level: level) }
    }

    public func trackFeedbackBegin() {
        providers.forEach { $0.trackFeedbackBegin() }
    }

    public func trackFeedbackRate() {
        providers.forEach { $0.trackFeedbackRate() }
    }

    public func trackFeedbackComplete() {
        providers.forEach { $0.trackFeedbackComplete() }
    }

    public func trackFullAdDidRequest(in placement: String, type: String, displayCount: Int, fullScreenDisplayCount: Int,totalAdsDisplayCount: Int) {
        providers.forEach { $0.trackFullAdDidRequest(in: placement, type: type, displayCount: displayCount, fullScreenDisplayCount: fullScreenDisplayCount, totalAdsDisplayCount: totalAdsDisplayCount) }
    }

    public func trackFullAdDidLoad(in placement: String, type: String, displayCount: Int, fullScreenDisplayCount: Int,totalAdsDisplayCount: Int, loadingTime: Double?) {
        providers.forEach { $0.trackFullAdDidLoad(in: placement, type: type, displayCount: displayCount, fullScreenDisplayCount: fullScreenDisplayCount, totalAdsDisplayCount: totalAdsDisplayCount, loadingTime: loadingTime) }
    }

    public func trackFullAdDidDisplay(in placement: String, type: String, failedRequests: Int, displayCount: Int, fullScreenDisplayCount: Int,totalAdsDisplayCount: Int, cpmLevel: Double?) {
        providers.forEach { $0.trackFullAdDidDisplay(in: placement, type: type, failedRequests: failedRequests, displayCount: displayCount, fullScreenDisplayCount: fullScreenDisplayCount, totalAdsDisplayCount: totalAdsDisplayCount, cpmLevel: cpmLevel) }
    }

    public func trackBannerAdDidRequest(in placement: String, type: String, bannersDisplayCount: Int, displayCount: Int,totalAdsDisplayCount: Int) {
        providers.forEach { $0.trackBannerAdDidRequest(in: placement, type: type, bannersDisplayCount: bannersDisplayCount, displayCount: displayCount, totalAdsDisplayCount: totalAdsDisplayCount) }
    }

    public func trackBannerAdDidLoad(in placement: String, type: String, bannersDisplayCount: Int, displayCount: Int,totalAdsDisplayCount: Int, loadingTime: Double?) {
        providers.forEach { $0.trackBannerAdDidLoad(in: placement, type: type, bannersDisplayCount: bannersDisplayCount, displayCount: displayCount, totalAdsDisplayCount: totalAdsDisplayCount, loadingTime: loadingTime) }
    }

    public func trackBannerAdDidDisplay(in placement: String, type: String, failedRequests: Int, bannersDisplayCount: Int, displayCount: Int,totalAdsDisplayCount: Int, cpmLevel: Double?) {
        providers.forEach { $0.trackBannerAdDidDisplay(in: placement, type: type, failedRequests: failedRequests, bannersDisplayCount: bannersDisplayCount, displayCount: displayCount, totalAdsDisplayCount: totalAdsDisplayCount, cpmLevel: cpmLevel) }
    }

    public func trackAdDidSkipPresent(in placement: String, type: String, failedRequests: Int, cpmLevel: Double) {
        providers.forEach { $0.trackAdDidSkipPresent(in: placement, type: type, failedRequests: failedRequests, cpmLevel: cpmLevel) }
    }

    public func trackAdDidFailToLoad(in placement: String, type: String, failedRequests: Int, error: String?) {
        providers.forEach { $0.trackAdDidFailToLoad(in: placement, type: type, failedRequests: failedRequests, error: error) }
    }

    public func trackAdDidFailToDisplay(in placement: String, type: String) {
        providers.forEach { $0.trackAdDidFailToDisplay(in: placement, type: type) }
    }

    public func trackAdDidHide(in placement: String, type: String) {
        providers.forEach { $0.trackAdDidHide(in: placement, type: type) }
    }

    public func trackAdDidClick(in placement: String, type: String) {
        providers.forEach { $0.trackAdDidClick(in: placement, type: type) }
    }

    public func trackAdDidReward(in placement: String, type: String) {
        providers.forEach { $0.trackAdDidReward(in: placement, type: type) }
    }

    /// `adNetwork` и `unitId` со значениями по умолчанию: часть вызовов
    /// (Yandex) знает только сеть медиации.
    public func trackAdRevenue(in placement: String, type: String, value: Decimal, currency: String,
                               network: String, adNetwork: String = "", unitId: String = "") {
        providers.forEach {
            $0.trackAdRevenue(in: placement, type: type, value: value, currency: currency,
                              network: network, adNetwork: adNetwork, unitId: unitId)
        }
        // Батч-репортер на свой бекенд: внутри гейт, пропуск Yandex и очередь.
        AdRevenueBackendProvider.shared.track(placement: placement, type: type, value: value,
                                              currency: currency, network: network,
                                              adNetwork: adNetwork, unitId: unitId)
    }

    public func trackPrivacyPolicy() {
        providers.forEach { $0.trackPrivacyPolicy() }
    }

    public func trackTermsOfUse() {
        providers.forEach { $0.trackTermsOfUse() }
    }

    public func trackArticleListDidPresent() {
        providers.forEach { $0.trackArticleListDidPresent() }
    }

    public func trackArticleListDidDismiss(timespent: Double) {
        providers.forEach { $0.trackArticleListDidDismiss(timespent: timespent) }
    }

    public func trackArticleDetailDidPresent(id: String) {
        providers.forEach { $0.trackArticleDetailDidPresent(id: id) }
    }

    public func trackArticleDetailDidDismiss(id: String, timespent: Double) {
        providers.forEach { $0.trackArticleDetailDidDismiss(id: id, timespent: timespent) }
    }

    public func trackNotificationDidOpen(_ userInfo: [String : Any]) {
        providers.forEach { $0.trackNotificationDidOpen(userInfo) }
    }

    public func trackError(name: String?, error: String?) {
        providers.forEach { $0.trackError(name: name, error: error) }
    }

    public func trackStakingPoolsDidPresent() {
        providers.forEach { $0.trackStakingPoolsDidPresent() }
    }

    public func trackStakingPoolsDidDismiss(timespent: Double) {
        providers.forEach { $0.trackStakingPoolsDidDismiss(timespent: timespent) }
    }

    public func trackStakingPoolsDidTapInvest(coin: String, invested: Decimal, size: Decimal, roi: Decimal, duration: Int) {
        providers.forEach { $0.trackStakingPoolsDidTapInvest(coin: coin, invested: invested, size: size, roi: roi, duration: duration) }
    }

    public func trackStakingPortfolioDidPresent() {
        providers.forEach { $0.trackStakingPortfolioDidPresent() }
    }

    public func trackStakingPortfolioDidDismiss(timespent: Double) {
        providers.forEach { $0.trackStakingPortfolioDidDismiss(timespent: timespent) }
    }

    public func trackStakingPortfolioDidTapCollect(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        providers.forEach { $0.trackStakingPortfolioDidTapCollect(coin: coin, roi: roi, amount: amount, duration: duration) }
    }

    public func trackStakingPortfolioDidTapRepair(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        providers.forEach { $0.trackStakingPortfolioDidTapRepair(coin: coin, roi: roi, amount: amount, duration: duration) }
    }

    public func trackStakingRatingDidPresent() {
        providers.forEach { $0.trackStakingRatingDidPresent() }
    }

    public func trackStakingRatingDidDismiss(timespent: Double) {
        providers.forEach { $0.trackStakingRatingDidDismiss(timespent: timespent) }
    }

    public func trackStakingRatingDidTapUser(position: Int) {
        providers.forEach { $0.trackStakingRatingDidTapUser(position: position) }
    }

    public func trackStakingInvestAmountDidPresent() {
        providers.forEach { $0.trackStakingInvestAmountDidPresent() }
    }

    public func trackStakingInvestAmountDidDismiss(timespent: Double) {
        providers.forEach { $0.trackStakingInvestAmountDidDismiss(timespent: timespent) }
    }

    public func trackStakingInvestAmountDidTapInvest(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        providers.forEach { $0.trackStakingInvestAmountDidTapInvest(coin: coin, roi: roi, amount: amount, duration: duration) }
    }

    public func trackStakingInvestAmountDidTapInvestWithProtection(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        providers.forEach { $0.trackStakingInvestAmountDidTapInvestWithProtection(coin: coin, roi: roi, amount: amount, duration: duration) }
    }

    public func trackStakingPoolHackedDidPresent() {
        providers.forEach { $0.trackStakingPoolHackedDidPresent() }
    }

    public func trackStakingPoolHackedDidDismiss(timespent: Double) {
        providers.forEach { $0.trackStakingPoolHackedDidDismiss(timespent: timespent) }
    }

    public func trackStakingPoolHackedDidTapProtection(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        providers.forEach { $0.trackStakingPoolHackedDidTapProtection(coin: coin, roi: roi, amount: amount, duration: duration) }
    }

    public func trackStakingPoolHackedDidTapLossMoney(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        providers.forEach { $0.trackStakingPoolHackedDidTapLossMoney(coin: coin, roi: roi, amount: amount, duration: duration) }
    }

    public func trackStakingProfitMultiplyDidPresent() {
        providers.forEach { $0.trackStakingProfitMultiplyDidPresent() }
    }

    public func trackStakingProfitMultiplyDidDismiss(timespent: Double) {
        providers.forEach { $0.trackStakingProfitMultiplyDidDismiss(timespent: timespent) }
    }

    public func trackStakingProfitMultiplyDidTapMultiply(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        providers.forEach { $0.trackStakingProfitMultiplyDidTapMultiply(coin: coin, roi: roi, amount: amount, duration: duration) }
    }

    public func trackStakingProfitMultiplyDidTapNotNow(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        providers.forEach { $0.trackStakingProfitMultiplyDidTapNotNow(coin: coin, roi: roi, amount: amount, duration: duration) }
    }

    public func trackMinerCollectMultiplyDidDismiss(timespent: Double) {
        providers.forEach { $0.trackMinerCollectMultiplyDidDismiss(timespent: timespent) }
    }

    public func trackMinerCollectMultiplyDidPresent() {
        providers.forEach { $0.trackMinerCollectMultiplyDidPresent() }
    }

    public func trackMinerCollectMultiplyDidTapCollect() {
        providers.forEach { $0.trackMinerCollectMultiplyDidTapCollect() }
    }

    public func trackMinerCollectMultiplyDidTapMultiply() {
        providers.forEach { $0.trackMinerCollectMultiplyDidTapMultiply() }
    }

    public func trackMinerDidCollect() {
        providers.forEach { $0.trackMinerDidCollect() }
    }

    public func trackMinerDidCreate() {
        providers.forEach { $0.trackMinerDidCreate() }
    }

    public func trackMinerDidCreateForAd() {
        providers.forEach { $0.trackMinerDidCreateForAd() }
    }

    public func trackMinerDidDismiss(timespent: Double) {
        providers.forEach { $0.trackMinerDidDismiss(timespent: timespent) }
    }

    public func trackMinerDidFailUpdate() {
        providers.forEach { $0.trackMinerDidFailUpdate() }
    }

    public func trackMinerDidFix() {
        providers.forEach { $0.trackMinerDidFix() }
    }

    public func trackMinerDidPresent() {
        providers.forEach { $0.trackMinerDidPresent() }
    }

    public func trackMinerDidStartUpdate() {
        providers.forEach { $0.trackMinerDidStartUpdate() }
    }

    public func trackMinerDidUpdate() {
        providers.forEach { $0.trackMinerDidUpdate() }
    }

    public func trackMinerFixDidDismiss(timespent: Double) {
        providers.forEach { $0.trackMinerFixDidDismiss(timespent: timespent) }
    }

    public func trackMinerFixDidPresent() {
        providers.forEach { $0.trackMinerFixDidPresent() }
    }

    public func trackMinersListBannerDidPresent(type: String) {
        providers.forEach { $0.trackMinersListBannerDidPresent(type: type) }
    }

    public func trackMinersListBannerDidTap(type: String) {
        providers.forEach { $0.trackMinersListBannerDidTap(type: type) }
    }

    public func trackMinersListDidDismiss(timespent: Double) {
        providers.forEach { $0.trackMinersListDidDismiss(timespent: timespent) }
    }

    public func trackMinersListDidPresent() {
        providers.forEach { $0.trackMinersListDidPresent() }
    }

    public func trackOtherUserDidLike() {
        providers.forEach { $0.trackOtherUserDidLike() }
    }

    public func trackOtherUserDidUnlike() {
        providers.forEach { $0.trackOtherUserDidUnlike() }
    }

    public func trackOtherUserLikesDidDismiss(timespent: Double) {
        providers.forEach { $0.trackOtherUserLikesDidDismiss(timespent: timespent) }
    }

    public func trackOtherUserLikesDidPresent() {
        providers.forEach { $0.trackOtherUserLikesDidPresent() }
    }

    public func trackOtherUserLikesDidTap() {
        providers.forEach { $0.trackOtherUserLikesDidTap() }
    }

    public func trackProfileDidDismiss(timespent: Double) {
        providers.forEach { $0.trackProfileDidDismiss(timespent: timespent) }
    }

    public func trackUserLikesDidDismiss(timespent: Double) {
        providers.forEach { $0.trackUserLikesDidDismiss(timespent: timespent) }
    }

    public func trackUserLikesDidPresent() {
        providers.forEach { $0.trackUserLikesDidPresent() }
    }

    public func trackUserLikesDidTap() {
        providers.forEach { $0.trackUserLikesDidTap() }
    }

    public func trackUserProfileOtherDidDismiss(timespent: Double) {
        providers.forEach { $0.trackUserProfileOtherDidDismiss(timespent: timespent) }
    }

    public func trackDashboardDidTapStartup() {
        providers.forEach { $0.trackDashboardDidTapStartup() }
    }

    public func trackStartupDidChangeAmount(amount: Double, previousAmount: Double) {
        providers.forEach { $0.trackStartupDidChangeAmount(amount: amount, previousAmount: previousAmount) }
    }

    public func trackStartupDidCrash(amount: Double, multiplier: Double, investmentCount: Int) {
        providers.forEach { $0.trackStartupDidCrash(amount: amount, multiplier: multiplier, investmentCount: investmentCount) }
    }

    public func trackStartupDidDismiss(timespent: Double, timespentSec: Int) {
        providers.forEach { $0.trackStartupDidDismiss(timespent: timespent, timespentSec: timespentSec) }
    }

    public func trackStartupDidPresent() {
        providers.forEach { $0.trackStartupDidPresent() }
    }

    public func trackStartupDidTapCollectReward(profit: Double) {
        providers.forEach { $0.trackStartupDidTapCollectReward(profit: profit) }
    }

    public func trackStartupDidTapDoubleReward(profit: Double) {
        providers.forEach { $0.trackStartupDidTapDoubleReward(profit: profit) }
    }

    public func trackStartupDidTapGetProfit(amount: Double, multiplier: Double, investmentCount: Int) {
        providers.forEach { $0.trackStartupDidTapGetProfit(amount: amount, multiplier: multiplier, investmentCount: investmentCount) }
    }

    public func trackStartupDidTapInvest(amount: Double, investmentCount: Int) {
        providers.forEach { $0.trackStartupDidTapInvest(amount: amount, investmentCount: investmentCount) }
    }

    public func trackStartupDidTapTryAgain() {
        providers.forEach { $0.trackStartupDidTapTryAgain() }
    }

    public func trackStartupLoseScreenDidPresent() {
        providers.forEach { $0.trackStartupLoseScreenDidPresent() }
    }

    public func trackStartupWinScreenDidPresent() {
        providers.forEach { $0.trackStartupWinScreenDidPresent() }
    }

    public func trackTradingDidTrade(isTournament: Bool, symbol: String, direction: String, stake: Decimal) {
        providers.forEach { $0.trackTradingDidTrade(isTournament: isTournament, symbol: symbol, direction: direction, stake: stake) }
    }
}
