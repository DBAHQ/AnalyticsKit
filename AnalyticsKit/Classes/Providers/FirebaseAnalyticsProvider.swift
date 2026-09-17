//
//  FirebaseAnalyticsProvider.swift
//  AnalyticsKit
//

import Foundation
import FirebaseCore
import FirebaseAnalytics

public final class FirebaseAnalyticsProvider: AnalyticsProvider {

    public var userID: String { AnalyticsKit.configuration.userID() }

    public init() {}

    // MARK: - Lifecycle

    public func start() {
        let plist = AnalyticsKit.configuration.firebasePlistName
        guard let path = Bundle.main.path(forResource: plist, ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path) else {
            AnalyticsKitLog.log("Firebase НЕ поднят: не найден \(plist).plist")
            return
        }
        if AnalyticsKit.configuration.isLoggingEnabled {
            // Подробный лог самого SDK: видно, какие события он принял и отправил.
            FirebaseConfiguration.shared.setLoggerLevel(.debug)
        }
        FirebaseApp.configure(options: options)
        Analytics.setAnalyticsCollectionEnabled(true)
        setUserProperties()
        AnalyticsKitLog.log("Firebase поднят, проект \(options.gcmSenderID), plist \(plist)")
    }

    private func setUserProperties() {
        Analytics.setUserID(userID)
        let language = AnalyticsKit.configuration.language() ?? Locale.current.languageCode ?? ""
        Analytics.setUserProperty(language, forName: "languageCode")
    }

    public func onboardingBegin() {
        Analytics.logEvent("onboardingBegin", parameters: nil)
    }

    public func onboardingStepPresent(step: String) {
        Analytics.logEvent("onboardingStepPresent", parameters: ["step": step])
    }

    public func onboardingStepContinue(step: String) {
        Analytics.logEvent("onboardingStepContinue", parameters: ["step": step])
    }

    public func onboardingComplete() {
        Analytics.logEvent("onboardingComplete", parameters: nil)
    }

    public func featureTutorialBegin(flow: String) {
        Analytics.logEvent("featureTutorialBegin", parameters: ["flow": flow])
    }

    public func featureTutorialStepPresent(flow: String, step: String) {
        Analytics.logEvent("featureTutorialStepPresent", parameters: ["flow": flow, "step": step])
    }

    public func featureTutorialStepContinue(flow: String, step: String) {
        Analytics.logEvent("featureTutorialStepContinue", parameters: ["flow": flow, "step": step])
    }

    public func featureTutorialSkip(flow: String, step: String) {
        Analytics.logEvent("featureTutorialSkip", parameters: ["flow": flow, "step": step])
    }

    public func featureTutorialComplete(flow: String) {
        Analytics.logEvent("featureTutorialComplete", parameters: ["flow": flow])
    }

    public func trackAuthDidPresent() {
        Analytics.logEvent("authDidPresent", parameters: nil)
    }

    public func trackAuthDidDismiss(timespent: Double) {
        Analytics.logEvent("authDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackAuthSignIn() {
        Analytics.logEvent("authSignIn", parameters: nil)
    }

    public func trackAuthSignUpBegin() {
        Analytics.logEvent("authSignUpBegin", parameters: nil)
    }

    public func trackAuthSignUpComplete() {
        Analytics.logEvent("authSignUpComplete", parameters: nil)
    }

    public func trackAuthOAuthBegin(_ type: String) {
        Analytics.logEvent("authOAuthBegin", parameters: ["type" : type])
    }

    public func trackAuthOAuthComplete(_ type: String) {
        Analytics.logEvent("authOAuthComplete", parameters: ["type" : type])
    }

    public func trackDashboardDidPresent() {
        Analytics.logEvent("dashboardDidPresent", parameters: nil)
    }

    public func trackDashboardDidDismiss(timespent: Double) {
        Analytics.logEvent("dashboardDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackDashboardDidTapSettings() {
        Analytics.logEvent("dashboardDidTapSettings", parameters: nil)
    }

    public func trackDashboardDidTapSignUp() {
        Analytics.logEvent("dashboardDidTapSignUp", parameters: nil)
    }

    public func trackDashboardDidTapProfile() {
        Analytics.logEvent("dashboardDidTapProfile", parameters: nil)
    }

    public func trackDashboardDidTapNotifications() {
        Analytics.logEvent("dashboardDidTapNotifications", parameters: nil)
    }

    public func trackDashboardDidTapBalance() {
        Analytics.logEvent("dashboardDidTapBalance", parameters: nil)
    }

    public func trackDashboardDidTapBonusAd() {
        Analytics.logEvent("dashboardDidTapBonusAd", parameters: nil)
    }

    public func trackDashboardDidTapDailyRewards() {
        Analytics.logEvent("dashboardDidTapDailyRewards", parameters: nil)
    }

    public func trackDashboardDidTapLuckySpin() {
        Analytics.logEvent("dashboardDidTapLuckySpin", parameters: nil)
    }

    public func trackDashboardDidTapChallenges() {
        Analytics.logEvent("dashboardDidTapChallenges", parameters: nil)
    }

    public func trackDashboardDidTapDemoAccount() {
        Analytics.logEvent("dashboardDidTapDemoAccount", parameters: nil)
    }

    public func trackDashboardDidTapShop() {
        Analytics.logEvent("dashboardDidTapShop", parameters: nil)
    }

    public func trackDashboardDidTapPremium() {
        Analytics.logEvent("dashboardDidTapPremium", parameters: nil)
    }

    public func trackDashboardDidTapAuction() {
        Analytics.logEvent("dashboardDidTapAuction", parameters: nil)
    }

    public func trackDashboardDidTapAppearance() {
        Analytics.logEvent("dashboardDidTapAppearance", parameters: nil)
    }

    public func trackDashboardDidTapStaking() {
        Analytics.logEvent("dashboardDidTapStaking", parameters: nil)
    }

    public func trackDashboardDidTapSlots() {
        Analytics.logEvent("dashboardDidTapSlots", parameters: nil)
    }

    public func trackTradingPortfolioDidPresent(isTournament: Bool) {
        Analytics.logEvent("tradingPortfolioDidPresent", parameters: ["isTournament" : isTournament])
    }

    public func trackTradingPortfolioDidDismiss(isTournament: Bool, timespent: Double) {
        Analytics.logEvent("tradingPortfolioDidDismiss", parameters: ["isTournament": isTournament, "timespentSec": timespent])
    }

    public func trackTradingPortfolioDidTap(isTournament: Bool, symbol: String) {
        Analytics.logEvent("tradingPortfolioDidTap", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackTradingMarketDidPresent(isTournament: Bool) {
        Analytics.logEvent("tradingMarketDidPresent", parameters: ["isTournament" : isTournament])
    }

    public func trackTradingMarketDidDismiss(isTournament: Bool, timespent: Double) {
        Analytics.logEvent("tradingMarketDidDismiss", parameters: ["isTournament": isTournament, "timespentSec": timespent])
    }

    public func trackTradingMarketDidTap(isTournament: Bool, symbol: String) {
        Analytics.logEvent("tradingMarketDidTap", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackTradingTradesDidPresent(isTournament: Bool) {
        Analytics.logEvent("tradingTradesDidPresent", parameters: ["isTournament" : isTournament])
    }

    public func trackTradingTradesDidDismiss(isTournament: Bool, timespent: Double) {
        Analytics.logEvent("tradingTradesDidDismiss", parameters: ["isTournament": isTournament, "timespentSec": timespent])
    }

    public func trackTradingTradesDidTap(isTournament: Bool, symbol: String) {
        Analytics.logEvent("tradingTradesDidTap", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackTradingOrdersDidPresent(isTournament: Bool) {
        Analytics.logEvent("tradingOrdersDidPresent", parameters: ["isTournament" : isTournament])
    }

    public func trackTradingOrdersDidDismiss(isTournament: Bool, timespent: Double) {
        Analytics.logEvent("tradingOrdersDidDismiss", parameters: ["isTournament": isTournament, "timespentSec": timespent])
    }

    public func trackTradingOrdersDidTap(isTournament: Bool, symbol: String, type: String) {
        Analytics.logEvent("tradingOrdersDidTap", parameters: ["isTournament" : isTournament, "symbol" : symbol, "type" : type])
    }

    public func trackAssetTradingDidPresent(isTournament: Bool, symbol: String) {
        Analytics.logEvent("assetTradingDidPresent", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackAssetTradingDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        Analytics.logEvent("assetTradingDidDismiss", parameters: ["isTournament": isTournament, "symbol": symbol, "timespentSec": timespent])
    }

    public func trackAssetTradingDidTapProChart(isTournament: Bool, symbol: String) {
        Analytics.logEvent("assetTradingDidTapProChart", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackAssetTradingDidTapBonusAd(isTournament: Bool, symbol: String) {
        Analytics.logEvent("assetTradingDidTapBonusAd", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackAssetTradingDidTapBuy(isTournament: Bool, symbol: String) {
        Analytics.logEvent("assetTradingDidTapBuy", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackAssetTradingDidTapSell(isTournament: Bool, symbol: String) {
        Analytics.logEvent("assetTradingDidTapSell", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackAssetTradesDidPresent(isTournament: Bool, symbol: String) {
        Analytics.logEvent("assetTradesDidPresent", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackAssetTradesDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        Analytics.logEvent("assetTradesDidDismiss", parameters: ["isTournament": isTournament, "symbol": symbol, "timespentSec": timespent])
    }

    public func trackAssetTradesDidTap(isTournament: Bool, symbol: String) {
        Analytics.logEvent("assetTradesDidTap", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackAssetOrdersDidPresent(isTournament: Bool, symbol: String) {
        Analytics.logEvent("assetOrdersDidPresent", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackAssetOrdersDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        Analytics.logEvent("assetOrdersDidDismiss", parameters: ["isTournament": isTournament, "symbol": symbol, "timespentSec": timespent])
    }

    public func trackAssetOrdersDidTap(isTournament: Bool, symbol: String, type: String) {
        Analytics.logEvent("assetOrdersDidTap", parameters: ["isTournament" : isTournament, "symbol" : symbol, "type" : type])
    }

    public func trackAssetTradeDetailDidPresent(isTournament: Bool, symbol: String) {
        Analytics.logEvent("assetTradeDetailDidPresent", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackAssetTradeDetailDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        Analytics.logEvent("tradingTradeDetailDidDismiss", parameters: ["isTournament": isTournament, "symbol": symbol, "timespentSec": timespent])
    }

    public func trackAssetOrderDetailDidPresent(isTournament: Bool, symbol: String) {
        Analytics.logEvent("assetOrderDetailDidPresent", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackAssetOrderDetailDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        Analytics.logEvent("assetOrderDetailDidDismiss", parameters: ["isTournament": isTournament, "symbol": symbol, "timespentSec": timespent])
    }

    public func trackNewOrderDidPresent(isTournament: Bool, symbol: String) {
        Analytics.logEvent("newOrderDidPresent", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackNewOrderDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        Analytics.logEvent("newOrderDidDismiss", parameters: ["isTournament": isTournament, "symbol": symbol, "timespentSec": timespent])
    }

    public func trackNewOrderDidSelectBuy(isTournament: Bool, symbol: String) {
        Analytics.logEvent("newOrderDidSelectBuy", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackNewOrderDidSelectSell(isTournament: Bool, symbol: String) {
        Analytics.logEvent("newOrderDidSelectSell", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackNewOrderDidSend(isTournament: Bool, symbol: String, amount: Decimal, takeProfit: Decimal, stopLoss: Decimal) {
        Analytics.logEvent("newOrderDidSend", parameters: ["isTournament" : isTournament, "symbol" : symbol, "amount" : amount.double, "takeProfit" : takeProfit.double, "stopLoss" : stopLoss.double])
    }

    public func trackAuctionDidPresent() {
        Analytics.logEvent("auctionDidPresent", parameters: nil)
    }

    public func trackAuctionDidDismiss(timespent: Double) {
        Analytics.logEvent("auctionDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackAuctionDidPlaceBid(amount: Decimal) {
        Analytics.logEvent("auctionDidPlaceBid", parameters: ["amount" : amount.double])
    }

    public func trackDailyRewardsDidPresent() {
        Analytics.logEvent("dailyRewardsDidPresent", parameters: nil)
    }

    public func trackDailyRewardsDidDismiss(timespent: Double) {
        Analytics.logEvent("dailyRewardsDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackDailyRewardsDidReceiveReward(day: Int) {
        Analytics.logEvent("dailyRewardsDidReceiveReward", parameters: ["day" : day])
    }

    public func trackDailyRewardsDidMultiplyReward(day: Int) {
        Analytics.logEvent("dailyRewardsDidMultiplyReward", parameters: ["day" : day])
    }

    public func trackLuckySpinDidPresent() {
        Analytics.logEvent("luckySpinDidPresent", parameters: nil)
    }

    public func trackLuckySpinDidDismiss(timespent: Double) {
        Analytics.logEvent("luckySpinDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackLuckySpinDidSpin() {
        Analytics.logEvent("luckySpinDidSpin", parameters: nil)
    }

    public func trackProfileDidPresent() {
        Analytics.logEvent("profileDidPresent", parameters: nil)
    }

    public func trackProfileDidTapAvatar() {
        Analytics.logEvent("profileDidTapAvatar", parameters: nil)
    }

    public func trackProfileDidTapAvatarEdit() {
        Analytics.logEvent("profileDidTapAvatarEdit", parameters: nil)
    }

    public func trackAvatarDidPresent() {
        Analytics.logEvent("avatarDidPresent", parameters: nil)
    }

    public func trackAvatarDidDismiss(timespent: Double) {
        Analytics.logEvent("avatarDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackAvatarDidTapChange() {
        Analytics.logEvent("avatarDidTapChange", parameters: nil)
    }

    public func trackUserProfileOtherDidPresent() {
        Analytics.logEvent("userProfileOtherDidPresent", parameters: nil)
    }

    public func trackSlotsDidPresent() {
        Analytics.logEvent("slotsDidPresent", parameters: nil)
    }

    public func trackSlotsDidDismiss(timespent: Double) {
        Analytics.logEvent("slotsDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackSlotsDidSpin(slotsCount: Int, totalSlotsCount: Int) {
        Analytics.logEvent("slotsDidSpin", parameters: ["slotsCount": slotsCount, "totalSlotsCount": totalSlotsCount])
    }

    public func trackSlotsDidLoad(loadingTime: Double) {
        Analytics.logEvent("slotsDidLoad", parameters: ["loadingTime": loadingTime])
    }

    public func trackShopDidPresent() {
        Analytics.logEvent("shopDidPresent", parameters: nil)
    }

    public func trackShopDidDismiss(timespent: Double) {
        Analytics.logEvent("shopDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackShopItemDidPresent(id: String, price: Decimal) {
        Analytics.logEvent("shopItemDidPresent", parameters: ["id" : id, "price" : price.double])
    }

    public func trackShopItemDidDismiss(id: String, price: Decimal, timespent: Double) {
        Analytics.logEvent("shopItemDidDismiss", parameters: ["id": id, "price": price.double, "timespentSec": timespent])
    }

    public func trackShopItemDidPurchase(id: String, price: Decimal) {
        Analytics.logEvent("shopItemDidPurchase", parameters: ["id" : id, "price" : price.double])
    }

    public func trackRatingDidPresent(isTournament: Bool) {
        Analytics.logEvent("ratingDidPresent", parameters: ["isTournament" : isTournament])
    }

    public func trackRatingDidDismiss(isTournament: Bool, timespent: Double) {
        Analytics.logEvent("ratingDidDismiss", parameters: ["isTournament": isTournament, "timespentSec": timespent])
    }

    public func trackTournamentWelcomeDidPresent() {
        Analytics.logEvent("tournamentWelcomeDidPresent", parameters: nil)
    }

    public func trackTournamentWelcomeDidDismiss(timespent: Double) {
        Analytics.logEvent("tournamentWelcomeDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackTournamentWelcomeSignUp() {
        Analytics.logEvent("tournamentWelcomeSignUp", parameters: nil)
    }

    public func trackTournamentDidPresent() {
        Analytics.logEvent("tournamentDidPresent", parameters: nil)
    }

    public func trackTournamentDidDismiss(timespent: Double) {
        Analytics.logEvent("tournamentDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackChallengesDidPresent() {
        Analytics.logEvent("challengesDidPresent", parameters: nil)
    }

    public func trackChallengesDidDismiss(timespent: Double) {
        Analytics.logEvent("challengesDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackChallengesAwardDidReceive(id: String, level: Int) {
        Analytics.logEvent("challengesAwardDidReceive", parameters: ["id" : id, "level" : level])
    }

    public func trackFeedbackBegin() {
        Analytics.logEvent("feedbackBegin", parameters: nil)
    }

    public func trackFeedbackRate() {
        Analytics.logEvent("feedbackRate", parameters: nil)
    }

    public func trackFeedbackComplete() {
        Analytics.logEvent("feedbackComplete", parameters: nil)
    }

    public func trackFullAdDidRequest(in placement: String, type: String, displayCount: Int, fullScreenDisplayCount: Int,totalAdsDisplayCount: Int) {
        Analytics.logEvent("adDidRequest", parameters: ["placement" : placement, "type" : type, "displayCount": displayCount, "fullScreenDisplayCount": fullScreenDisplayCount,"totalAdsDisplayCount": totalAdsDisplayCount])
    }

    public func trackFullAdDidLoad(in placement: String, type: String, displayCount: Int, fullScreenDisplayCount: Int,totalAdsDisplayCount: Int, loadingTime: Double?) {
        var parameters: [String : Any] = ["placement" : placement, "type" : type, "displayCount": displayCount, "fullScreenDisplayCount": fullScreenDisplayCount,"totalAdsDisplayCount": totalAdsDisplayCount]
        if let loadingTime { parameters["loadingTime"] = loadingTime }
        Analytics.logEvent("adDidLoad", parameters: parameters)
    }

    public func trackFullAdDidDisplay(in placement: String, type: String, failedRequests: Int, displayCount: Int, fullScreenDisplayCount: Int,totalAdsDisplayCount: Int, cpmLevel: Double?) {
        var parameters: [String : Any] = ["placement" : placement, "type" : type, "displayCount": displayCount, "fullScreenDisplayCount": fullScreenDisplayCount,"totalAdsDisplayCount": totalAdsDisplayCount]
        if let cpmLevel { parameters["cpmLevel"] = cpmLevel }
        Analytics.logEvent("adDidDisplay", parameters: parameters)
    }

    public func trackBannerAdDidRequest(in placement: String, type: String, bannersDisplayCount: Int, displayCount: Int,totalAdsDisplayCount: Int) {
        Analytics.logEvent("adDidRequest", parameters: ["placement" : placement, "type" : type, "bannersDisplayCount": bannersDisplayCount, "displayCount": displayCount,"totalAdsDisplayCount": totalAdsDisplayCount])
    }

    public func trackBannerAdDidLoad(in placement: String, type: String, bannersDisplayCount: Int, displayCount: Int,totalAdsDisplayCount: Int, loadingTime: Double?) {
        var parameters: [String : Any] = ["placement" : placement, "type" : type, "bannersDisplayCount": bannersDisplayCount, "displayCount": displayCount,"totalAdsDisplayCount": totalAdsDisplayCount]
        if let loadingTime { parameters["loadingTime"] = loadingTime }
        Analytics.logEvent("adDidLoad", parameters: parameters)
    }

    public func trackBannerAdDidDisplay(in placement: String, type: String, failedRequests: Int, bannersDisplayCount: Int, displayCount: Int,totalAdsDisplayCount: Int, cpmLevel: Double?) {
        var parameters: [String : Any] = ["placement" : placement, "type" : type, "bannersDisplayCount": bannersDisplayCount, "displayCount": displayCount,"totalAdsDisplayCount": totalAdsDisplayCount]
        if let cpmLevel { parameters["cpmLevel"] = cpmLevel }
        Analytics.logEvent("adDidDisplay", parameters: parameters)
    }

    public func trackAdDidSkipPresent(in placement: String, type: String, failedRequests: Int, cpmLevel: Double) {
        Analytics.logEvent("adDidSkipPresent", parameters: ["placement": placement, "type": type, "failedRequests": failedRequests, "cpmLevel": cpmLevel])
    }

    public func trackAdDidFailToLoad(in placement: String, type: String, failedRequests: Int, error: String?) {
        Analytics.logEvent("adDidFailToLoad", parameters: ["placement": placement, "type": type, "failedRequests": failedRequests, "error": error ?? "unknown"])
    }

    public func trackAdDidFailToDisplay(in placement: String, type: String) {
        Analytics.logEvent("adDidFailToDisplay", parameters: ["placement" : placement, "type" : type])
    }

    public func trackAdDidHide(in placement: String, type: String) {
        Analytics.logEvent("adDidHide", parameters: ["placement" : placement, "type" : type])
    }

    public func trackAdDidClick(in placement: String, type: String) {
        Analytics.logEvent("adDidClick", parameters: ["placement" : placement, "type" : type])
    }

    public func trackAdDidReward(in placement: String, type: String) {
        Analytics.logEvent("adDidReward", parameters: ["placement" : placement, "type" : type])
    }

    public func trackAdRevenue(in placement: String, type: String, value: Decimal, currency: String, network: String, adNetwork: String, unitId: String) {
        Analytics.logEvent("adRevenue", parameters: ["placement" : placement, "type" : type, "value" : value.double, "currency" : currency, "network" : network])
        // Стандартное событие Firebase: ad_platform — платформа медиации, ad_source — сеть,
        // выкупившая показ. В ad_unit_name осознанно кладём наш placement, а не ad unit сети:
        // разрез по местам показа нужнее, чем сверка с кабинетом медиации.
        // Откат нужен для Yandex: он вызывает trackAdRevenue по старой сигнатуре, adNetwork пустой.
        Analytics.logEvent(AnalyticsEventAdImpression, parameters: [
            AnalyticsParameterAdPlatform: network,
            AnalyticsParameterAdSource: adNetwork.isEmpty ? network : adNetwork,
            AnalyticsParameterAdUnitName: placement,
            AnalyticsParameterAdFormat: type,
            AnalyticsParameterValue: value.double,
            AnalyticsParameterCurrency: currency])
    }

    public func trackPrivacyPolicy() {
        Analytics.logEvent("openPrivacyPolicy", parameters: nil)
    }

    public func trackTermsOfUse() {
        Analytics.logEvent("openTermsOfUse", parameters: nil)
    }

    public func trackArticleListDidPresent() {
        Analytics.logEvent("articleListDidPresent", parameters: nil)
    }

    public func trackArticleListDidDismiss(timespent: Double) {
        Analytics.logEvent("articleListDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackArticleDetailDidPresent(id: String) {
        Analytics.logEvent("articleDetailDidPresent", parameters: ["id" : id])
    }

    public func trackArticleDetailDidDismiss(id: String, timespent: Double) {
        Analytics.logEvent("articleDetailDidDismiss", parameters: ["id": id, "timespentSec": timespent])
    }

    public func trackNotificationDidOpen(_ userInfo: [String : Any]) {
        Analytics.logEvent("notificationDidOpen", parameters: nil)
    }

    public func trackError(name: String?, error: String?) {
        Analytics.logEvent("didError", parameters: ["name" : name ?? "unknown", "error" : "unknown"])
    }

    public func trackStakingPoolsDidPresent() {
        Analytics.logEvent("stakingPoolsDidPresent", parameters: nil)
    }

    public func trackStakingPoolsDidDismiss(timespent: Double) {
        Analytics.logEvent("stakingPoolsDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackStakingPoolsDidTapInvest(coin: String, invested: Decimal, size: Decimal, roi: Decimal, duration: Int) {
        Analytics.logEvent("stakingPoolsDidTapInvest", parameters: [
            "coin": coin,
            "invested": invested.double,
            "size": size.double,
            "roi": roi,
            "duration": duration
        ])
    }

    public func trackStakingPortfolioDidPresent() {
        Analytics.logEvent("stakingPortfolioDidPresent", parameters: nil)
    }

    public func trackStakingPortfolioDidDismiss(timespent: Double) {
        Analytics.logEvent("stakingPortfolioDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackStakingPortfolioDidTapCollect(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        Analytics.logEvent("stakingPortfolioDidTapCollect", parameters: [
            "coin": coin,
            "roi": roi,
            "amount": amount.double,
            "duration": duration
        ])
    }

    public func trackStakingPortfolioDidTapRepair(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        Analytics.logEvent("stakingPortfolioDidTapRepair", parameters: [
            "coin": coin,
            "roi": roi,
            "amount": amount.double,
            "duration": duration
        ])
    }

    public func trackStakingRatingDidPresent() {
        Analytics.logEvent("stakingRatingDidPresent", parameters: nil)
    }

    public func trackStakingRatingDidDismiss(timespent: Double) {
        Analytics.logEvent("stakingRatingDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackStakingRatingDidTapUser(position: Int) {
        Analytics.logEvent("stakingRatingDidTapUser", parameters: ["position": position])
    }

    public func trackStakingInvestAmountDidPresent() {
        Analytics.logEvent("stakingInvestAmountDidPresent", parameters: nil)
    }

    public func trackStakingInvestAmountDidDismiss(timespent: Double) {
        Analytics.logEvent("stakingInvestAmountDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackStakingInvestAmountDidTapInvest(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        Analytics.logEvent("stakingInvestAmountDidTapInvest", parameters: ["coin": coin, "roi": roi, "amount": amount.double, "duration": duration])
    }

    public func trackStakingInvestAmountDidTapInvestWithProtection(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        Analytics.logEvent("stakingInvestAmountDidTapInvestWithProtection", parameters: ["coin": coin, "roi": roi, "amount": amount.double, "duration": duration])
    }

    public func trackStakingPoolHackedDidPresent() {
        Analytics.logEvent("stakingPoolHackedDidPresent", parameters: nil)
    }

    public func trackStakingPoolHackedDidDismiss(timespent: Double) {
        Analytics.logEvent("stakingPoolHackedDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackStakingPoolHackedDidTapProtection(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        Analytics.logEvent("stakingPoolHackedDidTapProtection", parameters: ["coin": coin, "roi": roi, "amount": amount.double, "duration": duration])
    }

    public func trackStakingPoolHackedDidTapLossMoney(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        Analytics.logEvent("stakingPoolHackedDidTapLossMoney", parameters: ["coin": coin, "roi": roi, "amount": amount.double, "duration": duration])
    }

    public func trackStakingProfitMultiplyDidPresent() {
        Analytics.logEvent("stakingProfitMultiplyDidPresent", parameters: nil)
    }

    public func trackStakingProfitMultiplyDidDismiss(timespent: Double) {
        Analytics.logEvent("stakingProfitMultiplyDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackStakingProfitMultiplyDidTapMultiply(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        Analytics.logEvent("stakingProfitMultiplyDidTapMultiply", parameters: ["coin": coin, "roi": roi, "amount": amount.double, "duration": duration])
    }

    public func trackStakingProfitMultiplyDidTapNotNow(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        Analytics.logEvent("stakingProfitMultiplyDidTapNotNow", parameters: ["coin": coin, "roi": roi, "amount": amount.double, "duration": duration])
    }

    public func trackSessionStart(trigger: String, textNumber: String, code: String) {
        Analytics.logEvent("sessionStart", parameters: ["trigger": trigger, "textNumber": textNumber, "code": code])
    }

    public func trackSessionFinish(duration: Double) {
        Analytics.logEvent("sessionFinish", parameters: ["sessionLength": duration])
    }

    public func trackInstall() {
        Analytics.logEvent("applicationDidInstall", parameters: nil)
    }

    public func trackMinerCollectMultiplyDidDismiss(timespent: Double) {
        Analytics.logEvent("minerCollectMultiplyDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackMinerCollectMultiplyDidPresent() {
        Analytics.logEvent("minerCollectMultiplyDidPresent", parameters: nil)
    }

    public func trackMinerCollectMultiplyDidTapCollect() {
        Analytics.logEvent("minerCollectMultiplyDidTapCollect", parameters: nil)
    }

    public func trackMinerCollectMultiplyDidTapMultiply() {
        Analytics.logEvent("minerCollectMultiplyDidTapMultiply", parameters: nil)
    }

    public func trackMinerDidCollect() {
        Analytics.logEvent("minerDidCollect", parameters: nil)
    }

    public func trackMinerDidCreate() {
        Analytics.logEvent("minerDidCreate", parameters: nil)
    }

    public func trackMinerDidCreateForAd() {
        Analytics.logEvent("minerDidCreateForAd", parameters: nil)
    }

    public func trackMinerDidDismiss(timespent: Double) {
        Analytics.logEvent("minerDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackMinerDidFailUpdate() {
        Analytics.logEvent("minerDidFailUpdate", parameters: nil)
    }

    public func trackMinerDidFix() {
        Analytics.logEvent("minerDidFix", parameters: nil)
    }

    public func trackMinerDidPresent() {
        Analytics.logEvent("minerDidPresent", parameters: nil)
    }

    public func trackMinerDidStartUpdate() {
        Analytics.logEvent("minerDidStartUpdate", parameters: nil)
    }

    public func trackMinerDidUpdate() {
        Analytics.logEvent("minerDidUpdate", parameters: nil)
    }

    public func trackMinerFixDidDismiss(timespent: Double) {
        Analytics.logEvent("minerFixDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackMinerFixDidPresent() {
        Analytics.logEvent("minerFixDidPresent", parameters: nil)
    }

    public func trackMinersListBannerDidPresent(type: String) {
        Analytics.logEvent("minersListBannerDidPresent", parameters: ["type": type])
    }

    public func trackMinersListBannerDidTap(type: String) {
        Analytics.logEvent("minersListBannerDidTap", parameters: ["type": type])
    }

    public func trackMinersListDidDismiss(timespent: Double) {
        Analytics.logEvent("minersListDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackMinersListDidPresent() {
        Analytics.logEvent("minersListDidPresent", parameters: nil)
    }

    public func trackOtherUserDidLike() {
        Analytics.logEvent("otherUserDidLike", parameters: nil)
    }

    public func trackOtherUserDidUnlike() {
        Analytics.logEvent("otherUserDidUnlike", parameters: nil)
    }

    public func trackOtherUserLikesDidDismiss(timespent: Double) {
        Analytics.logEvent("otherUserLikesDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackOtherUserLikesDidPresent() {
        Analytics.logEvent("otherUserLikesDidPresent", parameters: nil)
    }

    public func trackOtherUserLikesDidTap() {
        Analytics.logEvent("otherUserLikesDidTap", parameters: nil)
    }

    public func trackProfileDidDismiss(timespent: Double) {
        Analytics.logEvent("profileDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackUserLikesDidDismiss(timespent: Double) {
        Analytics.logEvent("userLikesDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackUserLikesDidPresent() {
        Analytics.logEvent("userLikesDidPresent", parameters: nil)
    }

    public func trackUserLikesDidTap() {
        Analytics.logEvent("userLikesDidTap", parameters: nil)
    }

    public func trackUserProfileOtherDidDismiss(timespent: Double) {
        Analytics.logEvent("userProfileOtherDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackDashboardDidTapStartup() {
        Analytics.logEvent("dashboardDidTapStartup", parameters: nil)
    }

    public func trackStartupDidChangeAmount(amount: Double, previousAmount: Double) {
        Analytics.logEvent("startupDidTapChangeInvestmentAmount", parameters: ["amount": amount, "previousAmount": previousAmount])
    }

    public func trackStartupDidCrash(amount: Double, multiplier: Double, investmentCount: Int) {
        Analytics.logEvent("startupDidCrash", parameters: ["amount": amount, "multiplier": multiplier, "investmentCount": investmentCount])
    }

    public func trackStartupDidDismiss(timespent: Double, timespentSec: Int) {
        Analytics.logEvent("startupDidDismiss", parameters: ["timespent": timespent, "timespentSec": timespentSec])
    }

    public func trackStartupDidPresent() {
        Analytics.logEvent("startupDidPresent", parameters: nil)
    }

    public func trackStartupDidTapCollectReward(profit: Double) {
        Analytics.logEvent("startupDidTapCollectReward", parameters: ["profit": profit])
    }

    public func trackStartupDidTapDoubleReward(profit: Double) {
        Analytics.logEvent("startupDidTapDoubleReward", parameters: ["profit": profit])
    }

    public func trackStartupDidTapGetProfit(amount: Double, multiplier: Double, investmentCount: Int) {
        Analytics.logEvent("startupDidTapTakeProfit", parameters: ["amount": amount, "multiplier": multiplier, "investmentCount": investmentCount])
    }

    public func trackStartupDidTapInvest(amount: Double, investmentCount: Int) {
        Analytics.logEvent("startupDidTapInvest", parameters: ["amount": amount, "investmentCount": investmentCount])
    }

    public func trackStartupDidTapTryAgain() {
        Analytics.logEvent("startupDidTapTryAgain", parameters: nil)
    }

    public func trackStartupLoseScreenDidPresent() {
        Analytics.logEvent("startupLoseScreenDidPresent", parameters: nil)
    }

    public func trackStartupWinScreenDidPresent() {
        Analytics.logEvent("startupWinScreenDidPresent", parameters: nil)
    }

    public func trackTradingDidTrade(isTournament: Bool, symbol: String, direction: String, stake: Decimal) {
        Analytics.logEvent("tradingDidTrade", parameters: ["isTournament" : isTournament, "symbol" : symbol, "direction" : direction, "stake" : stake.double])
    }
}
