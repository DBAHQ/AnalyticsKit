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

    /// `adNetwork` и `unitId` со значениями по умолчанию: часть вызовов
    /// (Yandex) знает только сеть медиации.
    public func trackAdRevenue(in placement: String, type: String, value: Decimal, currency: String,
                               network: String, adNetwork: String = "", unitId: String = "") {
        AnalyticsKitLog.event("trackAdRevenue", ["placement": placement, "type": type, "value": value,
                                                 "currency": currency, "network": network,
                                                 "adNetwork": adNetwork, "unitId": unitId])
        providers.forEach {
            $0.trackAdRevenue(in: placement, type: type, value: value, currency: currency,
                              network: network, adNetwork: adNetwork, unitId: unitId)
        }
        // Батч-репортер на свой бекенд: внутри гейт, пропуск Yandex и очередь.
        AdRevenueBackendProvider.shared.track(placement: placement, type: type, value: value,
                                              currency: currency, network: network,
                                              adNetwork: adNetwork, unitId: unitId)
    }

    public func onboardingBegin() {
        AnalyticsKitLog.event("onboardingBegin")
        providers.forEach { $0.onboardingBegin() }
    }

    public func onboardingStepPresent(step: String) {
        AnalyticsKitLog.event("onboardingStepPresent", ["step": step])
        providers.forEach { $0.onboardingStepPresent(step: step) }
    }

    public func onboardingStepContinue(step: String) {
        AnalyticsKitLog.event("onboardingStepContinue", ["step": step])
        providers.forEach { $0.onboardingStepContinue(step: step) }
    }

    public func onboardingComplete() {
        AnalyticsKitLog.event("onboardingComplete")
        providers.forEach { $0.onboardingComplete() }
    }

    public func featureTutorialBegin(flow: String) {
        AnalyticsKitLog.event("featureTutorialBegin", ["flow": flow])
        providers.forEach { $0.featureTutorialBegin(flow: flow) }
    }

    public func featureTutorialStepPresent(flow: String, step: String) {
        AnalyticsKitLog.event("featureTutorialStepPresent", ["flow": flow, "step": step])
        providers.forEach { $0.featureTutorialStepPresent(flow: flow, step: step) }
    }

    public func featureTutorialStepContinue(flow: String, step: String) {
        AnalyticsKitLog.event("featureTutorialStepContinue", ["flow": flow, "step": step])
        providers.forEach { $0.featureTutorialStepContinue(flow: flow, step: step) }
    }

    public func featureTutorialSkip(flow: String, step: String) {
        AnalyticsKitLog.event("featureTutorialSkip", ["flow": flow, "step": step])
        providers.forEach { $0.featureTutorialSkip(flow: flow, step: step) }
    }

    public func featureTutorialComplete(flow: String) {
        AnalyticsKitLog.event("featureTutorialComplete", ["flow": flow])
        providers.forEach { $0.featureTutorialComplete(flow: flow) }
    }

    public func trackAuthDidPresent() {
        AnalyticsKitLog.event("trackAuthDidPresent")
        providers.forEach { $0.trackAuthDidPresent() }
    }

    public func trackAuthDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackAuthDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackAuthDidDismiss(timespent: timespent) }
    }

    public func trackAuthSignIn() {
        AnalyticsKitLog.event("trackAuthSignIn")
        providers.forEach { $0.trackAuthSignIn() }
    }

    public func trackAuthSignUpBegin() {
        AnalyticsKitLog.event("trackAuthSignUpBegin")
        providers.forEach { $0.trackAuthSignUpBegin() }
    }

    public func trackAuthSignUpComplete() {
        AnalyticsKitLog.event("trackAuthSignUpComplete")
        providers.forEach { $0.trackAuthSignUpComplete() }
    }

    public func trackAuthOAuthBegin(_ type: String) {
        AnalyticsKitLog.event("trackAuthOAuthBegin", ["type": type])
        providers.forEach { $0.trackAuthOAuthBegin(type) }
    }

    public func trackAuthOAuthComplete(_ type: String) {
        AnalyticsKitLog.event("trackAuthOAuthComplete", ["type": type])
        providers.forEach { $0.trackAuthOAuthComplete(type) }
    }

    public func trackDashboardDidPresent() {
        AnalyticsKitLog.event("trackDashboardDidPresent")
        providers.forEach { $0.trackDashboardDidPresent() }
    }

    public func trackDashboardDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackDashboardDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackDashboardDidDismiss(timespent: timespent) }
    }

    public func trackDashboardDidTapSettings() {
        AnalyticsKitLog.event("trackDashboardDidTapSettings")
        providers.forEach { $0.trackDashboardDidTapSettings() }
    }

    public func trackDashboardDidTapSignUp() {
        AnalyticsKitLog.event("trackDashboardDidTapSignUp")
        providers.forEach { $0.trackDashboardDidTapSignUp() }
    }

    public func trackDashboardDidTapProfile() {
        AnalyticsKitLog.event("trackDashboardDidTapProfile")
        providers.forEach { $0.trackDashboardDidTapProfile() }
    }

    public func trackDashboardDidTapNotifications() {
        AnalyticsKitLog.event("trackDashboardDidTapNotifications")
        providers.forEach { $0.trackDashboardDidTapNotifications() }
    }

    public func trackDashboardDidTapBalance() {
        AnalyticsKitLog.event("trackDashboardDidTapBalance")
        providers.forEach { $0.trackDashboardDidTapBalance() }
    }

    public func trackDashboardDidTapBonusAd() {
        AnalyticsKitLog.event("trackDashboardDidTapBonusAd")
        providers.forEach { $0.trackDashboardDidTapBonusAd() }
    }

    public func trackDashboardDidTapDailyRewards() {
        AnalyticsKitLog.event("trackDashboardDidTapDailyRewards")
        providers.forEach { $0.trackDashboardDidTapDailyRewards() }
    }

    public func trackDashboardDidTapLuckySpin() {
        AnalyticsKitLog.event("trackDashboardDidTapLuckySpin")
        providers.forEach { $0.trackDashboardDidTapLuckySpin() }
    }

    public func trackDashboardDidTapChallenges() {
        AnalyticsKitLog.event("trackDashboardDidTapChallenges")
        providers.forEach { $0.trackDashboardDidTapChallenges() }
    }

    public func trackDashboardDidTapDemoAccount() {
        AnalyticsKitLog.event("trackDashboardDidTapDemoAccount")
        providers.forEach { $0.trackDashboardDidTapDemoAccount() }
    }

    public func trackDashboardDidTapShop() {
        AnalyticsKitLog.event("trackDashboardDidTapShop")
        providers.forEach { $0.trackDashboardDidTapShop() }
    }

    public func trackDashboardDidTapPremium() {
        AnalyticsKitLog.event("trackDashboardDidTapPremium")
        providers.forEach { $0.trackDashboardDidTapPremium() }
    }

    public func trackDashboardDidTapAuction() {
        AnalyticsKitLog.event("trackDashboardDidTapAuction")
        providers.forEach { $0.trackDashboardDidTapAuction() }
    }

    public func trackDashboardDidTapAppearance() {
        AnalyticsKitLog.event("trackDashboardDidTapAppearance")
        providers.forEach { $0.trackDashboardDidTapAppearance() }
    }

    public func trackDashboardDidTapStaking() {
        AnalyticsKitLog.event("trackDashboardDidTapStaking")
        providers.forEach { $0.trackDashboardDidTapStaking() }
    }

    public func trackDashboardDidTapSlots() {
        AnalyticsKitLog.event("trackDashboardDidTapSlots")
        providers.forEach { $0.trackDashboardDidTapSlots() }
    }

    public func trackTradingPortfolioDidPresent(isTournament: Bool) {
        AnalyticsKitLog.event("trackTradingPortfolioDidPresent", ["isTournament": isTournament])
        providers.forEach { $0.trackTradingPortfolioDidPresent(isTournament: isTournament) }
    }

    public func trackTradingPortfolioDidDismiss(isTournament: Bool, timespent: Double) {
        AnalyticsKitLog.event("trackTradingPortfolioDidDismiss", ["isTournament": isTournament, "timespent": timespent])
        providers.forEach { $0.trackTradingPortfolioDidDismiss(isTournament: isTournament, timespent: timespent) }
    }

    public func trackTradingPortfolioDidTap(isTournament: Bool, symbol: String) {
        AnalyticsKitLog.event("trackTradingPortfolioDidTap", ["isTournament": isTournament, "symbol": symbol])
        providers.forEach { $0.trackTradingPortfolioDidTap(isTournament: isTournament, symbol: symbol) }
    }

    public func trackTradingMarketDidPresent(isTournament: Bool) {
        AnalyticsKitLog.event("trackTradingMarketDidPresent", ["isTournament": isTournament])
        providers.forEach { $0.trackTradingMarketDidPresent(isTournament: isTournament) }
    }

    public func trackTradingMarketDidDismiss(isTournament: Bool, timespent: Double) {
        AnalyticsKitLog.event("trackTradingMarketDidDismiss", ["isTournament": isTournament, "timespent": timespent])
        providers.forEach { $0.trackTradingMarketDidDismiss(isTournament: isTournament, timespent: timespent) }
    }

    public func trackTradingMarketDidTap(isTournament: Bool, symbol: String) {
        AnalyticsKitLog.event("trackTradingMarketDidTap", ["isTournament": isTournament, "symbol": symbol])
        providers.forEach { $0.trackTradingMarketDidTap(isTournament: isTournament, symbol: symbol) }
    }

    public func trackTradingTradesDidPresent(isTournament: Bool) {
        AnalyticsKitLog.event("trackTradingTradesDidPresent", ["isTournament": isTournament])
        providers.forEach { $0.trackTradingTradesDidPresent(isTournament: isTournament) }
    }

    public func trackTradingTradesDidDismiss(isTournament: Bool, timespent: Double) {
        AnalyticsKitLog.event("trackTradingTradesDidDismiss", ["isTournament": isTournament, "timespent": timespent])
        providers.forEach { $0.trackTradingTradesDidDismiss(isTournament: isTournament, timespent: timespent) }
    }

    public func trackTradingTradesDidTap(isTournament: Bool, symbol: String) {
        AnalyticsKitLog.event("trackTradingTradesDidTap", ["isTournament": isTournament, "symbol": symbol])
        providers.forEach { $0.trackTradingTradesDidTap(isTournament: isTournament, symbol: symbol) }
    }

    public func trackTradingOrdersDidPresent(isTournament: Bool) {
        AnalyticsKitLog.event("trackTradingOrdersDidPresent", ["isTournament": isTournament])
        providers.forEach { $0.trackTradingOrdersDidPresent(isTournament: isTournament) }
    }

    public func trackTradingOrdersDidDismiss(isTournament: Bool, timespent: Double) {
        AnalyticsKitLog.event("trackTradingOrdersDidDismiss", ["isTournament": isTournament, "timespent": timespent])
        providers.forEach { $0.trackTradingOrdersDidDismiss(isTournament: isTournament, timespent: timespent) }
    }

    public func trackTradingOrdersDidTap(isTournament: Bool, symbol: String, type: String) {
        AnalyticsKitLog.event("trackTradingOrdersDidTap", ["isTournament": isTournament, "symbol": symbol, "type": type])
        providers.forEach { $0.trackTradingOrdersDidTap(isTournament: isTournament, symbol: symbol, type: type) }
    }

    public func trackAssetTradingDidPresent(isTournament: Bool, symbol: String) {
        AnalyticsKitLog.event("trackAssetTradingDidPresent", ["isTournament": isTournament, "symbol": symbol])
        providers.forEach { $0.trackAssetTradingDidPresent(isTournament: isTournament, symbol: symbol) }
    }

    public func trackAssetTradingDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        AnalyticsKitLog.event("trackAssetTradingDidDismiss", ["isTournament": isTournament, "symbol": symbol, "timespent": timespent])
        providers.forEach { $0.trackAssetTradingDidDismiss(isTournament: isTournament, symbol: symbol, timespent: timespent) }
    }

    public func trackAssetTradingDidTapProChart(isTournament: Bool, symbol: String) {
        AnalyticsKitLog.event("trackAssetTradingDidTapProChart", ["isTournament": isTournament, "symbol": symbol])
        providers.forEach { $0.trackAssetTradingDidTapProChart(isTournament: isTournament, symbol: symbol) }
    }

    public func trackAssetTradingDidTapBonusAd(isTournament: Bool, symbol: String) {
        AnalyticsKitLog.event("trackAssetTradingDidTapBonusAd", ["isTournament": isTournament, "symbol": symbol])
        providers.forEach { $0.trackAssetTradingDidTapBonusAd(isTournament: isTournament, symbol: symbol) }
    }

    public func trackAssetTradingDidTapBuy(isTournament: Bool, symbol: String) {
        AnalyticsKitLog.event("trackAssetTradingDidTapBuy", ["isTournament": isTournament, "symbol": symbol])
        providers.forEach { $0.trackAssetTradingDidTapBuy(isTournament: isTournament, symbol: symbol) }
    }

    public func trackAssetTradingDidTapSell(isTournament: Bool, symbol: String) {
        AnalyticsKitLog.event("trackAssetTradingDidTapSell", ["isTournament": isTournament, "symbol": symbol])
        providers.forEach { $0.trackAssetTradingDidTapSell(isTournament: isTournament, symbol: symbol) }
    }

    public func trackAssetTradesDidPresent(isTournament: Bool, symbol: String) {
        AnalyticsKitLog.event("trackAssetTradesDidPresent", ["isTournament": isTournament, "symbol": symbol])
        providers.forEach { $0.trackAssetTradesDidPresent(isTournament: isTournament, symbol: symbol) }
    }

    public func trackAssetTradesDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        AnalyticsKitLog.event("trackAssetTradesDidDismiss", ["isTournament": isTournament, "symbol": symbol, "timespent": timespent])
        providers.forEach { $0.trackAssetTradesDidDismiss(isTournament: isTournament, symbol: symbol, timespent: timespent) }
    }

    public func trackAssetTradesDidTap(isTournament: Bool, symbol: String) {
        AnalyticsKitLog.event("trackAssetTradesDidTap", ["isTournament": isTournament, "symbol": symbol])
        providers.forEach { $0.trackAssetTradesDidTap(isTournament: isTournament, symbol: symbol) }
    }

    public func trackAssetOrdersDidPresent(isTournament: Bool, symbol: String) {
        AnalyticsKitLog.event("trackAssetOrdersDidPresent", ["isTournament": isTournament, "symbol": symbol])
        providers.forEach { $0.trackAssetOrdersDidPresent(isTournament: isTournament, symbol: symbol) }
    }

    public func trackAssetOrdersDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        AnalyticsKitLog.event("trackAssetOrdersDidDismiss", ["isTournament": isTournament, "symbol": symbol, "timespent": timespent])
        providers.forEach { $0.trackAssetOrdersDidDismiss(isTournament: isTournament, symbol: symbol, timespent: timespent) }
    }

    public func trackAssetOrdersDidTap(isTournament: Bool, symbol: String, type: String) {
        AnalyticsKitLog.event("trackAssetOrdersDidTap", ["isTournament": isTournament, "symbol": symbol, "type": type])
        providers.forEach { $0.trackAssetOrdersDidTap(isTournament: isTournament, symbol: symbol, type: type) }
    }

    public func trackAssetTradeDetailDidPresent(isTournament: Bool, symbol: String) {
        AnalyticsKitLog.event("trackAssetTradeDetailDidPresent", ["isTournament": isTournament, "symbol": symbol])
        providers.forEach { $0.trackAssetTradeDetailDidPresent(isTournament: isTournament, symbol: symbol) }
    }

    public func trackAssetTradeDetailDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        AnalyticsKitLog.event("trackAssetTradeDetailDidDismiss", ["isTournament": isTournament, "symbol": symbol, "timespent": timespent])
        providers.forEach { $0.trackAssetTradeDetailDidDismiss(isTournament: isTournament, symbol: symbol, timespent: timespent) }
    }

    public func trackAssetOrderDetailDidPresent(isTournament: Bool, symbol: String) {
        AnalyticsKitLog.event("trackAssetOrderDetailDidPresent", ["isTournament": isTournament, "symbol": symbol])
        providers.forEach { $0.trackAssetOrderDetailDidPresent(isTournament: isTournament, symbol: symbol) }
    }

    public func trackAssetOrderDetailDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        AnalyticsKitLog.event("trackAssetOrderDetailDidDismiss", ["isTournament": isTournament, "symbol": symbol, "timespent": timespent])
        providers.forEach { $0.trackAssetOrderDetailDidDismiss(isTournament: isTournament, symbol: symbol, timespent: timespent) }
    }

    public func trackNewOrderDidPresent(isTournament: Bool, symbol: String) {
        AnalyticsKitLog.event("trackNewOrderDidPresent", ["isTournament": isTournament, "symbol": symbol])
        providers.forEach { $0.trackNewOrderDidPresent(isTournament: isTournament, symbol: symbol) }
    }

    public func trackNewOrderDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        AnalyticsKitLog.event("trackNewOrderDidDismiss", ["isTournament": isTournament, "symbol": symbol, "timespent": timespent])
        providers.forEach { $0.trackNewOrderDidDismiss(isTournament: isTournament, symbol: symbol, timespent: timespent) }
    }

    public func trackNewOrderDidSelectBuy(isTournament: Bool, symbol: String) {
        AnalyticsKitLog.event("trackNewOrderDidSelectBuy", ["isTournament": isTournament, "symbol": symbol])
        providers.forEach { $0.trackNewOrderDidSelectBuy(isTournament: isTournament, symbol: symbol) }
    }

    public func trackNewOrderDidSelectSell(isTournament: Bool, symbol: String) {
        AnalyticsKitLog.event("trackNewOrderDidSelectSell", ["isTournament": isTournament, "symbol": symbol])
        providers.forEach { $0.trackNewOrderDidSelectSell(isTournament: isTournament, symbol: symbol) }
    }

    public func trackNewOrderDidSend(isTournament: Bool, symbol: String, amount: Decimal, takeProfit: Decimal, stopLoss: Decimal) {
        AnalyticsKitLog.event("trackNewOrderDidSend", ["isTournament": isTournament, "symbol": symbol, "amount": amount, "takeProfit": takeProfit, "stopLoss": stopLoss])
        providers.forEach { $0.trackNewOrderDidSend(isTournament: isTournament, symbol: symbol, amount: amount, takeProfit: takeProfit, stopLoss: stopLoss) }
    }

    public func trackAuctionDidPresent() {
        AnalyticsKitLog.event("trackAuctionDidPresent")
        providers.forEach { $0.trackAuctionDidPresent() }
    }

    public func trackAuctionDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackAuctionDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackAuctionDidDismiss(timespent: timespent) }
    }

    public func trackAuctionDidPlaceBid(amount: Decimal) {
        AnalyticsKitLog.event("trackAuctionDidPlaceBid", ["amount": amount])
        providers.forEach { $0.trackAuctionDidPlaceBid(amount: amount) }
    }

    public func trackDailyRewardsDidPresent() {
        AnalyticsKitLog.event("trackDailyRewardsDidPresent")
        providers.forEach { $0.trackDailyRewardsDidPresent() }
    }

    public func trackDailyRewardsDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackDailyRewardsDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackDailyRewardsDidDismiss(timespent: timespent) }
    }

    public func trackDailyRewardsDidReceiveReward(day: Int) {
        AnalyticsKitLog.event("trackDailyRewardsDidReceiveReward", ["day": day])
        providers.forEach { $0.trackDailyRewardsDidReceiveReward(day: day) }
    }

    public func trackDailyRewardsDidMultiplyReward(day: Int) {
        AnalyticsKitLog.event("trackDailyRewardsDidMultiplyReward", ["day": day])
        providers.forEach { $0.trackDailyRewardsDidMultiplyReward(day: day) }
    }

    public func trackLuckySpinDidPresent() {
        AnalyticsKitLog.event("trackLuckySpinDidPresent")
        providers.forEach { $0.trackLuckySpinDidPresent() }
    }

    public func trackLuckySpinDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackLuckySpinDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackLuckySpinDidDismiss(timespent: timespent) }
    }

    public func trackLuckySpinDidSpin() {
        AnalyticsKitLog.event("trackLuckySpinDidSpin")
        providers.forEach { $0.trackLuckySpinDidSpin() }
    }

    public func trackProfileDidPresent() {
        AnalyticsKitLog.event("trackProfileDidPresent")
        providers.forEach { $0.trackProfileDidPresent() }
    }

    public func trackProfileDidTapAvatar() {
        AnalyticsKitLog.event("trackProfileDidTapAvatar")
        providers.forEach { $0.trackProfileDidTapAvatar() }
    }

    public func trackProfileDidTapAvatarEdit() {
        AnalyticsKitLog.event("trackProfileDidTapAvatarEdit")
        providers.forEach { $0.trackProfileDidTapAvatarEdit() }
    }

    public func trackAvatarDidPresent() {
        AnalyticsKitLog.event("trackAvatarDidPresent")
        providers.forEach { $0.trackAvatarDidPresent() }
    }

    public func trackAvatarDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackAvatarDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackAvatarDidDismiss(timespent: timespent) }
    }

    public func trackAvatarDidTapChange() {
        AnalyticsKitLog.event("trackAvatarDidTapChange")
        providers.forEach { $0.trackAvatarDidTapChange() }
    }

    public func trackUserProfileOtherDidPresent() {
        AnalyticsKitLog.event("trackUserProfileOtherDidPresent")
        providers.forEach { $0.trackUserProfileOtherDidPresent() }
    }

    public func trackSlotsDidPresent() {
        AnalyticsKitLog.event("trackSlotsDidPresent")
        providers.forEach { $0.trackSlotsDidPresent() }
    }

    public func trackSlotsDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackSlotsDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackSlotsDidDismiss(timespent: timespent) }
    }

    public func trackSlotsDidSpin(slotsCount: Int, totalSlotsCount: Int) {
        AnalyticsKitLog.event("trackSlotsDidSpin", ["slotsCount": slotsCount, "totalSlotsCount": totalSlotsCount])
        providers.forEach { $0.trackSlotsDidSpin(slotsCount: slotsCount, totalSlotsCount: totalSlotsCount) }
    }

    public func trackSlotsDidLoad(loadingTime: Double) {
        AnalyticsKitLog.event("trackSlotsDidLoad", ["loadingTime": loadingTime])
        providers.forEach { $0.trackSlotsDidLoad(loadingTime: loadingTime) }
    }

    public func trackShopDidPresent() {
        AnalyticsKitLog.event("trackShopDidPresent")
        providers.forEach { $0.trackShopDidPresent() }
    }

    public func trackShopDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackShopDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackShopDidDismiss(timespent: timespent) }
    }

    public func trackShopItemDidPresent(id: String, price: Decimal) {
        AnalyticsKitLog.event("trackShopItemDidPresent", ["id": id, "price": price])
        providers.forEach { $0.trackShopItemDidPresent(id: id, price: price) }
    }

    public func trackShopItemDidDismiss(id: String, price: Decimal, timespent: Double) {
        AnalyticsKitLog.event("trackShopItemDidDismiss", ["id": id, "price": price, "timespent": timespent])
        providers.forEach { $0.trackShopItemDidDismiss(id: id, price: price, timespent: timespent) }
    }

    public func trackShopItemDidPurchase(id: String, price: Decimal) {
        AnalyticsKitLog.event("trackShopItemDidPurchase", ["id": id, "price": price])
        providers.forEach { $0.trackShopItemDidPurchase(id: id, price: price) }
    }

    public func trackRatingDidPresent(isTournament: Bool) {
        AnalyticsKitLog.event("trackRatingDidPresent", ["isTournament": isTournament])
        providers.forEach { $0.trackRatingDidPresent(isTournament: isTournament) }
    }

    public func trackRatingDidDismiss(isTournament: Bool, timespent: Double) {
        AnalyticsKitLog.event("trackRatingDidDismiss", ["isTournament": isTournament, "timespent": timespent])
        providers.forEach { $0.trackRatingDidDismiss(isTournament: isTournament, timespent: timespent) }
    }

    public func trackTournamentWelcomeDidPresent() {
        AnalyticsKitLog.event("trackTournamentWelcomeDidPresent")
        providers.forEach { $0.trackTournamentWelcomeDidPresent() }
    }

    public func trackTournamentWelcomeDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackTournamentWelcomeDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackTournamentWelcomeDidDismiss(timespent: timespent) }
    }

    public func trackTournamentWelcomeSignUp() {
        AnalyticsKitLog.event("trackTournamentWelcomeSignUp")
        providers.forEach { $0.trackTournamentWelcomeSignUp() }
    }

    public func trackTournamentDidPresent() {
        AnalyticsKitLog.event("trackTournamentDidPresent")
        providers.forEach { $0.trackTournamentDidPresent() }
    }

    public func trackTournamentDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackTournamentDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackTournamentDidDismiss(timespent: timespent) }
    }

    public func trackChallengesDidPresent() {
        AnalyticsKitLog.event("trackChallengesDidPresent")
        providers.forEach { $0.trackChallengesDidPresent() }
    }

    public func trackChallengesDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackChallengesDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackChallengesDidDismiss(timespent: timespent) }
    }

    public func trackChallengesAwardDidReceive(id: String, level: Int) {
        AnalyticsKitLog.event("trackChallengesAwardDidReceive", ["id": id, "level": level])
        providers.forEach { $0.trackChallengesAwardDidReceive(id: id, level: level) }
    }

    public func trackFeedbackBegin() {
        AnalyticsKitLog.event("trackFeedbackBegin")
        providers.forEach { $0.trackFeedbackBegin() }
    }

    public func trackFeedbackRate() {
        AnalyticsKitLog.event("trackFeedbackRate")
        providers.forEach { $0.trackFeedbackRate() }
    }

    public func trackFeedbackComplete() {
        AnalyticsKitLog.event("trackFeedbackComplete")
        providers.forEach { $0.trackFeedbackComplete() }
    }

    public func trackFullAdDidRequest(in placement: String, type: String, displayCount: Int, fullScreenDisplayCount: Int,totalAdsDisplayCount: Int) {
        AnalyticsKitLog.event("trackFullAdDidRequest", ["placement": placement, "type": type, "displayCount": displayCount, "fullScreenDisplayCount": fullScreenDisplayCount, "totalAdsDisplayCount": totalAdsDisplayCount])
        providers.forEach { $0.trackFullAdDidRequest(in: placement, type: type, displayCount: displayCount, fullScreenDisplayCount: fullScreenDisplayCount, totalAdsDisplayCount: totalAdsDisplayCount) }
    }

    public func trackFullAdDidLoad(in placement: String, type: String, displayCount: Int, fullScreenDisplayCount: Int,totalAdsDisplayCount: Int, loadingTime: Double?) {
        AnalyticsKitLog.event("trackFullAdDidLoad", ["placement": placement, "type": type, "displayCount": displayCount, "fullScreenDisplayCount": fullScreenDisplayCount, "totalAdsDisplayCount": totalAdsDisplayCount, "loadingTime": loadingTime])
        providers.forEach { $0.trackFullAdDidLoad(in: placement, type: type, displayCount: displayCount, fullScreenDisplayCount: fullScreenDisplayCount, totalAdsDisplayCount: totalAdsDisplayCount, loadingTime: loadingTime) }
    }

    public func trackFullAdDidDisplay(in placement: String, type: String, failedRequests: Int, displayCount: Int, fullScreenDisplayCount: Int,totalAdsDisplayCount: Int, cpmLevel: Double?) {
        AnalyticsKitLog.event("trackFullAdDidDisplay", ["placement": placement, "type": type, "failedRequests": failedRequests, "displayCount": displayCount, "fullScreenDisplayCount": fullScreenDisplayCount, "totalAdsDisplayCount": totalAdsDisplayCount, "cpmLevel": cpmLevel])
        providers.forEach { $0.trackFullAdDidDisplay(in: placement, type: type, failedRequests: failedRequests, displayCount: displayCount, fullScreenDisplayCount: fullScreenDisplayCount, totalAdsDisplayCount: totalAdsDisplayCount, cpmLevel: cpmLevel) }
    }

    public func trackBannerAdDidRequest(in placement: String, type: String, bannersDisplayCount: Int, displayCount: Int,totalAdsDisplayCount: Int) {
        AnalyticsKitLog.event("trackBannerAdDidRequest", ["placement": placement, "type": type, "bannersDisplayCount": bannersDisplayCount, "displayCount": displayCount, "totalAdsDisplayCount": totalAdsDisplayCount])
        providers.forEach { $0.trackBannerAdDidRequest(in: placement, type: type, bannersDisplayCount: bannersDisplayCount, displayCount: displayCount, totalAdsDisplayCount: totalAdsDisplayCount) }
    }

    public func trackBannerAdDidLoad(in placement: String, type: String, bannersDisplayCount: Int, displayCount: Int,totalAdsDisplayCount: Int, loadingTime: Double?) {
        AnalyticsKitLog.event("trackBannerAdDidLoad", ["placement": placement, "type": type, "bannersDisplayCount": bannersDisplayCount, "displayCount": displayCount, "totalAdsDisplayCount": totalAdsDisplayCount, "loadingTime": loadingTime])
        providers.forEach { $0.trackBannerAdDidLoad(in: placement, type: type, bannersDisplayCount: bannersDisplayCount, displayCount: displayCount, totalAdsDisplayCount: totalAdsDisplayCount, loadingTime: loadingTime) }
    }

    public func trackBannerAdDidDisplay(in placement: String, type: String, failedRequests: Int, bannersDisplayCount: Int, displayCount: Int,totalAdsDisplayCount: Int, cpmLevel: Double?) {
        AnalyticsKitLog.event("trackBannerAdDidDisplay", ["placement": placement, "type": type, "failedRequests": failedRequests, "bannersDisplayCount": bannersDisplayCount, "displayCount": displayCount, "totalAdsDisplayCount": totalAdsDisplayCount, "cpmLevel": cpmLevel])
        providers.forEach { $0.trackBannerAdDidDisplay(in: placement, type: type, failedRequests: failedRequests, bannersDisplayCount: bannersDisplayCount, displayCount: displayCount, totalAdsDisplayCount: totalAdsDisplayCount, cpmLevel: cpmLevel) }
    }

    public func trackAdDidSkipPresent(in placement: String, type: String, failedRequests: Int, cpmLevel: Double) {
        AnalyticsKitLog.event("trackAdDidSkipPresent", ["placement": placement, "type": type, "failedRequests": failedRequests, "cpmLevel": cpmLevel])
        providers.forEach { $0.trackAdDidSkipPresent(in: placement, type: type, failedRequests: failedRequests, cpmLevel: cpmLevel) }
    }

    public func trackAdDidFailToLoad(in placement: String, type: String, failedRequests: Int, error: String?) {
        AnalyticsKitLog.event("trackAdDidFailToLoad", ["placement": placement, "type": type, "failedRequests": failedRequests, "error": error])
        providers.forEach { $0.trackAdDidFailToLoad(in: placement, type: type, failedRequests: failedRequests, error: error) }
    }

    public func trackAdDidFailToDisplay(in placement: String, type: String) {
        AnalyticsKitLog.event("trackAdDidFailToDisplay", ["placement": placement, "type": type])
        providers.forEach { $0.trackAdDidFailToDisplay(in: placement, type: type) }
    }

    public func trackAdDidHide(in placement: String, type: String) {
        AnalyticsKitLog.event("trackAdDidHide", ["placement": placement, "type": type])
        providers.forEach { $0.trackAdDidHide(in: placement, type: type) }
    }

    public func trackAdDidClick(in placement: String, type: String) {
        AnalyticsKitLog.event("trackAdDidClick", ["placement": placement, "type": type])
        providers.forEach { $0.trackAdDidClick(in: placement, type: type) }
    }

    public func trackAdDidReward(in placement: String, type: String) {
        AnalyticsKitLog.event("trackAdDidReward", ["placement": placement, "type": type])
        providers.forEach { $0.trackAdDidReward(in: placement, type: type) }
    }

    public func trackPrivacyPolicy() {
        AnalyticsKitLog.event("trackPrivacyPolicy")
        providers.forEach { $0.trackPrivacyPolicy() }
    }

    public func trackTermsOfUse() {
        AnalyticsKitLog.event("trackTermsOfUse")
        providers.forEach { $0.trackTermsOfUse() }
    }

    public func trackArticleListDidPresent() {
        AnalyticsKitLog.event("trackArticleListDidPresent")
        providers.forEach { $0.trackArticleListDidPresent() }
    }

    public func trackArticleListDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackArticleListDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackArticleListDidDismiss(timespent: timespent) }
    }

    public func trackArticleDetailDidPresent(id: String) {
        AnalyticsKitLog.event("trackArticleDetailDidPresent", ["id": id])
        providers.forEach { $0.trackArticleDetailDidPresent(id: id) }
    }

    public func trackArticleDetailDidDismiss(id: String, timespent: Double) {
        AnalyticsKitLog.event("trackArticleDetailDidDismiss", ["id": id, "timespent": timespent])
        providers.forEach { $0.trackArticleDetailDidDismiss(id: id, timespent: timespent) }
    }

    public func trackNotificationDidOpen(_ userInfo: [String : Any]) {
        AnalyticsKitLog.event("trackNotificationDidOpen", ["userInfo": userInfo])
        providers.forEach { $0.trackNotificationDidOpen(userInfo) }
    }

    public func trackError(name: String?, error: String?) {
        AnalyticsKitLog.event("trackError", ["name": name, "error": error])
        providers.forEach { $0.trackError(name: name, error: error) }
    }

    public func trackStakingPoolsDidPresent() {
        AnalyticsKitLog.event("trackStakingPoolsDidPresent")
        providers.forEach { $0.trackStakingPoolsDidPresent() }
    }

    public func trackStakingPoolsDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackStakingPoolsDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackStakingPoolsDidDismiss(timespent: timespent) }
    }

    public func trackStakingPoolsDidTapInvest(coin: String, invested: Decimal, size: Decimal, roi: Decimal, duration: Int) {
        AnalyticsKitLog.event("trackStakingPoolsDidTapInvest", ["coin": coin, "invested": invested, "size": size, "roi": roi, "duration": duration])
        providers.forEach { $0.trackStakingPoolsDidTapInvest(coin: coin, invested: invested, size: size, roi: roi, duration: duration) }
    }

    public func trackStakingPortfolioDidPresent() {
        AnalyticsKitLog.event("trackStakingPortfolioDidPresent")
        providers.forEach { $0.trackStakingPortfolioDidPresent() }
    }

    public func trackStakingPortfolioDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackStakingPortfolioDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackStakingPortfolioDidDismiss(timespent: timespent) }
    }

    public func trackStakingPortfolioDidTapCollect(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        AnalyticsKitLog.event("trackStakingPortfolioDidTapCollect", ["coin": coin, "roi": roi, "amount": amount, "duration": duration])
        providers.forEach { $0.trackStakingPortfolioDidTapCollect(coin: coin, roi: roi, amount: amount, duration: duration) }
    }

    public func trackStakingPortfolioDidTapRepair(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        AnalyticsKitLog.event("trackStakingPortfolioDidTapRepair", ["coin": coin, "roi": roi, "amount": amount, "duration": duration])
        providers.forEach { $0.trackStakingPortfolioDidTapRepair(coin: coin, roi: roi, amount: amount, duration: duration) }
    }

    public func trackStakingRatingDidPresent() {
        AnalyticsKitLog.event("trackStakingRatingDidPresent")
        providers.forEach { $0.trackStakingRatingDidPresent() }
    }

    public func trackStakingRatingDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackStakingRatingDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackStakingRatingDidDismiss(timespent: timespent) }
    }

    public func trackStakingRatingDidTapUser(position: Int) {
        AnalyticsKitLog.event("trackStakingRatingDidTapUser", ["position": position])
        providers.forEach { $0.trackStakingRatingDidTapUser(position: position) }
    }

    public func trackStakingInvestAmountDidPresent() {
        AnalyticsKitLog.event("trackStakingInvestAmountDidPresent")
        providers.forEach { $0.trackStakingInvestAmountDidPresent() }
    }

    public func trackStakingInvestAmountDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackStakingInvestAmountDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackStakingInvestAmountDidDismiss(timespent: timespent) }
    }

    public func trackStakingInvestAmountDidTapInvest(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        AnalyticsKitLog.event("trackStakingInvestAmountDidTapInvest", ["coin": coin, "roi": roi, "amount": amount, "duration": duration])
        providers.forEach { $0.trackStakingInvestAmountDidTapInvest(coin: coin, roi: roi, amount: amount, duration: duration) }
    }

    public func trackStakingInvestAmountDidTapInvestWithProtection(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        AnalyticsKitLog.event("trackStakingInvestAmountDidTapInvestWithProtection", ["coin": coin, "roi": roi, "amount": amount, "duration": duration])
        providers.forEach { $0.trackStakingInvestAmountDidTapInvestWithProtection(coin: coin, roi: roi, amount: amount, duration: duration) }
    }

    public func trackStakingPoolHackedDidPresent() {
        AnalyticsKitLog.event("trackStakingPoolHackedDidPresent")
        providers.forEach { $0.trackStakingPoolHackedDidPresent() }
    }

    public func trackStakingPoolHackedDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackStakingPoolHackedDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackStakingPoolHackedDidDismiss(timespent: timespent) }
    }

    public func trackStakingPoolHackedDidTapProtection(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        AnalyticsKitLog.event("trackStakingPoolHackedDidTapProtection", ["coin": coin, "roi": roi, "amount": amount, "duration": duration])
        providers.forEach { $0.trackStakingPoolHackedDidTapProtection(coin: coin, roi: roi, amount: amount, duration: duration) }
    }

    public func trackStakingPoolHackedDidTapLossMoney(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        AnalyticsKitLog.event("trackStakingPoolHackedDidTapLossMoney", ["coin": coin, "roi": roi, "amount": amount, "duration": duration])
        providers.forEach { $0.trackStakingPoolHackedDidTapLossMoney(coin: coin, roi: roi, amount: amount, duration: duration) }
    }

    public func trackStakingProfitMultiplyDidPresent() {
        AnalyticsKitLog.event("trackStakingProfitMultiplyDidPresent")
        providers.forEach { $0.trackStakingProfitMultiplyDidPresent() }
    }

    public func trackStakingProfitMultiplyDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackStakingProfitMultiplyDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackStakingProfitMultiplyDidDismiss(timespent: timespent) }
    }

    public func trackStakingProfitMultiplyDidTapMultiply(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        AnalyticsKitLog.event("trackStakingProfitMultiplyDidTapMultiply", ["coin": coin, "roi": roi, "amount": amount, "duration": duration])
        providers.forEach { $0.trackStakingProfitMultiplyDidTapMultiply(coin: coin, roi: roi, amount: amount, duration: duration) }
    }

    public func trackStakingProfitMultiplyDidTapNotNow(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        AnalyticsKitLog.event("trackStakingProfitMultiplyDidTapNotNow", ["coin": coin, "roi": roi, "amount": amount, "duration": duration])
        providers.forEach { $0.trackStakingProfitMultiplyDidTapNotNow(coin: coin, roi: roi, amount: amount, duration: duration) }
    }

    public func trackMinerCollectMultiplyDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackMinerCollectMultiplyDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackMinerCollectMultiplyDidDismiss(timespent: timespent) }
    }

    public func trackMinerCollectMultiplyDidPresent() {
        AnalyticsKitLog.event("trackMinerCollectMultiplyDidPresent")
        providers.forEach { $0.trackMinerCollectMultiplyDidPresent() }
    }

    public func trackMinerCollectMultiplyDidTapCollect() {
        AnalyticsKitLog.event("trackMinerCollectMultiplyDidTapCollect")
        providers.forEach { $0.trackMinerCollectMultiplyDidTapCollect() }
    }

    public func trackMinerCollectMultiplyDidTapMultiply() {
        AnalyticsKitLog.event("trackMinerCollectMultiplyDidTapMultiply")
        providers.forEach { $0.trackMinerCollectMultiplyDidTapMultiply() }
    }

    public func trackMinerDidCollect() {
        AnalyticsKitLog.event("trackMinerDidCollect")
        providers.forEach { $0.trackMinerDidCollect() }
    }

    public func trackMinerDidCreate() {
        AnalyticsKitLog.event("trackMinerDidCreate")
        providers.forEach { $0.trackMinerDidCreate() }
    }

    public func trackMinerDidCreateForAd() {
        AnalyticsKitLog.event("trackMinerDidCreateForAd")
        providers.forEach { $0.trackMinerDidCreateForAd() }
    }

    public func trackMinerDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackMinerDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackMinerDidDismiss(timespent: timespent) }
    }

    public func trackMinerDidFailUpdate() {
        AnalyticsKitLog.event("trackMinerDidFailUpdate")
        providers.forEach { $0.trackMinerDidFailUpdate() }
    }

    public func trackMinerDidFix() {
        AnalyticsKitLog.event("trackMinerDidFix")
        providers.forEach { $0.trackMinerDidFix() }
    }

    public func trackMinerDidPresent() {
        AnalyticsKitLog.event("trackMinerDidPresent")
        providers.forEach { $0.trackMinerDidPresent() }
    }

    public func trackMinerDidStartUpdate() {
        AnalyticsKitLog.event("trackMinerDidStartUpdate")
        providers.forEach { $0.trackMinerDidStartUpdate() }
    }

    public func trackMinerDidUpdate() {
        AnalyticsKitLog.event("trackMinerDidUpdate")
        providers.forEach { $0.trackMinerDidUpdate() }
    }

    public func trackMinerFixDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackMinerFixDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackMinerFixDidDismiss(timespent: timespent) }
    }

    public func trackMinerFixDidPresent() {
        AnalyticsKitLog.event("trackMinerFixDidPresent")
        providers.forEach { $0.trackMinerFixDidPresent() }
    }

    public func trackMinersListBannerDidPresent(type: String) {
        AnalyticsKitLog.event("trackMinersListBannerDidPresent", ["type": type])
        providers.forEach { $0.trackMinersListBannerDidPresent(type: type) }
    }

    public func trackMinersListBannerDidTap(type: String) {
        AnalyticsKitLog.event("trackMinersListBannerDidTap", ["type": type])
        providers.forEach { $0.trackMinersListBannerDidTap(type: type) }
    }

    public func trackMinersListDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackMinersListDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackMinersListDidDismiss(timespent: timespent) }
    }

    public func trackMinersListDidPresent() {
        AnalyticsKitLog.event("trackMinersListDidPresent")
        providers.forEach { $0.trackMinersListDidPresent() }
    }

    public func trackOtherUserDidLike() {
        AnalyticsKitLog.event("trackOtherUserDidLike")
        providers.forEach { $0.trackOtherUserDidLike() }
    }

    public func trackOtherUserDidUnlike() {
        AnalyticsKitLog.event("trackOtherUserDidUnlike")
        providers.forEach { $0.trackOtherUserDidUnlike() }
    }

    public func trackOtherUserLikesDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackOtherUserLikesDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackOtherUserLikesDidDismiss(timespent: timespent) }
    }

    public func trackOtherUserLikesDidPresent() {
        AnalyticsKitLog.event("trackOtherUserLikesDidPresent")
        providers.forEach { $0.trackOtherUserLikesDidPresent() }
    }

    public func trackOtherUserLikesDidTap() {
        AnalyticsKitLog.event("trackOtherUserLikesDidTap")
        providers.forEach { $0.trackOtherUserLikesDidTap() }
    }

    public func trackProfileDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackProfileDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackProfileDidDismiss(timespent: timespent) }
    }

    public func trackUserLikesDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackUserLikesDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackUserLikesDidDismiss(timespent: timespent) }
    }

    public func trackUserLikesDidPresent() {
        AnalyticsKitLog.event("trackUserLikesDidPresent")
        providers.forEach { $0.trackUserLikesDidPresent() }
    }

    public func trackUserLikesDidTap() {
        AnalyticsKitLog.event("trackUserLikesDidTap")
        providers.forEach { $0.trackUserLikesDidTap() }
    }

    public func trackUserProfileOtherDidDismiss(timespent: Double) {
        AnalyticsKitLog.event("trackUserProfileOtherDidDismiss", ["timespent": timespent])
        providers.forEach { $0.trackUserProfileOtherDidDismiss(timespent: timespent) }
    }

    public func trackDashboardDidTapStartup() {
        AnalyticsKitLog.event("trackDashboardDidTapStartup")
        providers.forEach { $0.trackDashboardDidTapStartup() }
    }

    public func trackStartupDidChangeAmount(amount: Double, previousAmount: Double) {
        AnalyticsKitLog.event("trackStartupDidChangeAmount", ["amount": amount, "previousAmount": previousAmount])
        providers.forEach { $0.trackStartupDidChangeAmount(amount: amount, previousAmount: previousAmount) }
    }

    public func trackStartupDidCrash(amount: Double, multiplier: Double, investmentCount: Int) {
        AnalyticsKitLog.event("trackStartupDidCrash", ["amount": amount, "multiplier": multiplier, "investmentCount": investmentCount])
        providers.forEach { $0.trackStartupDidCrash(amount: amount, multiplier: multiplier, investmentCount: investmentCount) }
    }

    public func trackStartupDidDismiss(timespent: Double, timespentSec: Int) {
        AnalyticsKitLog.event("trackStartupDidDismiss", ["timespent": timespent, "timespentSec": timespentSec])
        providers.forEach { $0.trackStartupDidDismiss(timespent: timespent, timespentSec: timespentSec) }
    }

    public func trackStartupDidPresent() {
        AnalyticsKitLog.event("trackStartupDidPresent")
        providers.forEach { $0.trackStartupDidPresent() }
    }

    public func trackStartupDidTapCollectReward(profit: Double) {
        AnalyticsKitLog.event("trackStartupDidTapCollectReward", ["profit": profit])
        providers.forEach { $0.trackStartupDidTapCollectReward(profit: profit) }
    }

    public func trackStartupDidTapDoubleReward(profit: Double) {
        AnalyticsKitLog.event("trackStartupDidTapDoubleReward", ["profit": profit])
        providers.forEach { $0.trackStartupDidTapDoubleReward(profit: profit) }
    }

    public func trackStartupDidTapGetProfit(amount: Double, multiplier: Double, investmentCount: Int) {
        AnalyticsKitLog.event("trackStartupDidTapGetProfit", ["amount": amount, "multiplier": multiplier, "investmentCount": investmentCount])
        providers.forEach { $0.trackStartupDidTapGetProfit(amount: amount, multiplier: multiplier, investmentCount: investmentCount) }
    }

    public func trackStartupDidTapInvest(amount: Double, investmentCount: Int) {
        AnalyticsKitLog.event("trackStartupDidTapInvest", ["amount": amount, "investmentCount": investmentCount])
        providers.forEach { $0.trackStartupDidTapInvest(amount: amount, investmentCount: investmentCount) }
    }

    public func trackStartupDidTapTryAgain() {
        AnalyticsKitLog.event("trackStartupDidTapTryAgain")
        providers.forEach { $0.trackStartupDidTapTryAgain() }
    }

    public func trackStartupLoseScreenDidPresent() {
        AnalyticsKitLog.event("trackStartupLoseScreenDidPresent")
        providers.forEach { $0.trackStartupLoseScreenDidPresent() }
    }

    public func trackStartupWinScreenDidPresent() {
        AnalyticsKitLog.event("trackStartupWinScreenDidPresent")
        providers.forEach { $0.trackStartupWinScreenDidPresent() }
    }

    public func trackTradingDidTrade(isTournament: Bool, symbol: String, direction: String, stake: Decimal) {
        AnalyticsKitLog.event("trackTradingDidTrade", ["isTournament": isTournament, "symbol": symbol, "direction": direction, "stake": stake])
        providers.forEach { $0.trackTradingDidTrade(isTournament: isTournament, symbol: symbol, direction: direction, stake: stake) }
    }
}
