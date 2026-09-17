//
//  AppMetricaAnalyticsProvider.swift
//  AnalyticsKit
//

import Foundation
import AppMetricaCore

public final class AppMetricaAnalyticsProvider: AnalyticsProvider {

    public var userID: String { AnalyticsKit.configuration.userID() }

    public init() {}

    // MARK: - Lifecycle

    public func start() {
        guard let configuration = AppMetricaConfiguration(apiKey: AnalyticsKit.configuration.appMetricaKey) else {
            return
        }
        configuration.userProfileID = userID
        AppMetrica.activate(with: configuration)
    }

    public func onboardingBegin() {
        AppMetrica.reportEvent(name: "onboardingBegin", parameters: nil)
    }

    public func onboardingStepPresent(step: String) {
        AppMetrica.reportEvent(name: "onboardingStepPresent", parameters: ["step": step])
    }

    public func onboardingStepContinue(step: String) {
        AppMetrica.reportEvent(name: "onboardingStepContinue", parameters: ["step": step])
    }

    public func onboardingComplete() {
        AppMetrica.reportEvent(name: "onboardingComplete", parameters: nil)
    }

    public func featureTutorialBegin(flow: String) {
        AppMetrica.reportEvent(name: "featureTutorialBegin", parameters: ["flow": flow])
    }

    public func featureTutorialStepPresent(flow: String, step: String) {
        AppMetrica.reportEvent(name: "featureTutorialStepPresent", parameters: ["flow": flow, "step": step])
    }

    public func featureTutorialStepContinue(flow: String, step: String) {
        AppMetrica.reportEvent(name: "featureTutorialStepContinue", parameters: ["flow": flow, "step": step])
    }

    public func featureTutorialSkip(flow: String, step: String) {
        AppMetrica.reportEvent(name: "featureTutorialSkip", parameters: ["flow": flow, "step": step])
    }

    public func featureTutorialComplete(flow: String) {
        AppMetrica.reportEvent(name: "featureTutorialComplete", parameters: ["flow": flow])
    }

    public func trackAuthDidPresent() {
        AppMetrica.reportEvent(name: "authDidPresent", parameters: nil)
    }

    public func trackAuthDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "authDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackAuthSignIn() {
        AppMetrica.reportEvent(name: "authSignIn", parameters: nil)
    }

    public func trackAuthSignUpBegin() {
        AppMetrica.reportEvent(name: "authSignUpBegin", parameters: nil)
    }

    public func trackAuthSignUpComplete() {
        AppMetrica.reportEvent(name: "authSignUpComplete", parameters: nil)
    }

    public func trackAuthOAuthBegin(_ type: String) {
        AppMetrica.reportEvent(name: "authOAuthBegin", parameters: ["type" : type])
    }

    public func trackAuthOAuthComplete(_ type: String) {
        AppMetrica.reportEvent(name: "authOAuthComplete", parameters: ["type" : type])
    }

    public func trackDashboardDidPresent() {
        AppMetrica.reportEvent(name: "dashboardDidPresent", parameters: nil)
    }

    public func trackDashboardDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "dashboardDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackDashboardDidTapSettings() {
        AppMetrica.reportEvent(name: "dashboardDidTapSettings", parameters: nil)
    }

    public func trackDashboardDidTapSignUp() {
        AppMetrica.reportEvent(name: "dashboardDidTapSignUp", parameters: nil)
    }

    public func trackDashboardDidTapProfile() {
        AppMetrica.reportEvent(name: "dashboardDidTapProfile", parameters: nil)
    }

    public func trackDashboardDidTapNotifications() {
        AppMetrica.reportEvent(name: "dashboardDidTapNotifications", parameters: nil)
    }

    public func trackDashboardDidTapBalance() {
        AppMetrica.reportEvent(name: "dashboardDidTapBalance", parameters: nil)
    }

    public func trackDashboardDidTapBonusAd() {
        AppMetrica.reportEvent(name: "dashboardDidTapBonusAd", parameters: nil)
    }

    public func trackDashboardDidTapDailyRewards() {
        AppMetrica.reportEvent(name: "dashboardDidTapDailyRewards", parameters: nil)
    }

    public func trackDashboardDidTapLuckySpin() {
        AppMetrica.reportEvent(name: "dashboardDidTapLuckySpin", parameters: nil)
    }

    public func trackDashboardDidTapChallenges() {
        AppMetrica.reportEvent(name: "dashboardDidTapChallenges", parameters: nil)
    }

    public func trackDashboardDidTapDemoAccount() {
        AppMetrica.reportEvent(name: "dashboardDidTapDemoAccount", parameters: nil)
    }

    public func trackDashboardDidTapShop() {
        AppMetrica.reportEvent(name: "dashboardDidTapShop", parameters: nil)
    }

    public func trackDashboardDidTapPremium() {
        AppMetrica.reportEvent(name: "dashboardDidTapPremium", parameters: nil)
    }

    public func trackDashboardDidTapAuction() {
        AppMetrica.reportEvent(name: "dashboardDidTapAuction", parameters: nil)
    }

    public func trackDashboardDidTapAppearance() {
        AppMetrica.reportEvent(name: "dashboardDidTapAppearance", parameters: nil)
    }

    public func trackDashboardDidTapStaking() {
        AppMetrica.reportEvent(name: "dashboardDidTapStaking", parameters: nil)
    }

    public func trackDashboardDidTapSlots() {
        AppMetrica.reportEvent(name: "dashboardDidTapSlots", parameters: nil)
    }

    public func trackTradingPortfolioDidPresent(isTournament: Bool) {
        AppMetrica.reportEvent(name: "tradingPortfolioDidPresent", parameters: ["isTournament" : isTournament])
    }

    public func trackTradingPortfolioDidDismiss(isTournament: Bool, timespent: Double) {
        AppMetrica.reportEvent(name: "tradingPortfolioDidDismiss", parameters: ["isTournament": isTournament, "timespentSec": timespent])
    }

    public func trackTradingPortfolioDidTap(isTournament: Bool, symbol: String) {
        AppMetrica.reportEvent(name: "tradingPortfolioDidTap", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackTradingMarketDidPresent(isTournament: Bool) {
        AppMetrica.reportEvent(name: "tradingMarketDidPresent", parameters: ["isTournament" : isTournament])
    }

    public func trackTradingMarketDidDismiss(isTournament: Bool, timespent: Double) {
        AppMetrica.reportEvent(name: "tradingMarketDidDismiss", parameters: ["isTournament": isTournament, "timespentSec": timespent])
    }

    public func trackTradingMarketDidTap(isTournament: Bool, symbol: String) {
        AppMetrica.reportEvent(name: "tradingMarketDidTap", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackTradingTradesDidPresent(isTournament: Bool) {
        AppMetrica.reportEvent(name: "tradingTradesDidPresent", parameters: ["isTournament" : isTournament])
    }

    public func trackTradingTradesDidDismiss(isTournament: Bool, timespent: Double) {
        AppMetrica.reportEvent(name: "tradingTradesDidDismiss", parameters: ["isTournament": isTournament, "timespentSec": timespent])
    }

    public func trackTradingTradesDidTap(isTournament: Bool, symbol: String) {
        AppMetrica.reportEvent(name: "tradingTradesDidTap", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackTradingOrdersDidPresent(isTournament: Bool) {
        AppMetrica.reportEvent(name: "tradingOrdersDidPresent", parameters: ["isTournament" : isTournament])
    }

    public func trackTradingOrdersDidDismiss(isTournament: Bool, timespent: Double) {
        AppMetrica.reportEvent(name: "tradingOrdersDidDismiss", parameters: ["isTournament": isTournament, "timespentSec": timespent])
    }

    public func trackTradingOrdersDidTap(isTournament: Bool, symbol: String, type: String) {
        AppMetrica.reportEvent(name: "tradingOrdersDidTap", parameters: ["isTournament" : isTournament, "symbol" : symbol, "type" : type])
    }

    public func trackAssetTradingDidPresent(isTournament: Bool, symbol: String) {
        AppMetrica.reportEvent(name: "assetTradingDidPresent", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackAssetTradingDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        AppMetrica.reportEvent(name: "assetTradingDidDismiss", parameters: ["isTournament": isTournament, "symbol": symbol, "timespentSec": timespent])
    }

    public func trackAssetTradingDidTapProChart(isTournament: Bool, symbol: String) {
        AppMetrica.reportEvent(name: "assetTradingDidTapProChart", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackAssetTradingDidTapBonusAd(isTournament: Bool, symbol: String) {
        AppMetrica.reportEvent(name: "assetTradingDidTapBonusAd", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackAssetTradingDidTapBuy(isTournament: Bool, symbol: String) {
        AppMetrica.reportEvent(name: "assetTradingDidTapBuy", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackAssetTradingDidTapSell(isTournament: Bool, symbol: String) {
        AppMetrica.reportEvent(name: "assetTradingDidTapSell", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackAssetTradesDidPresent(isTournament: Bool, symbol: String) {
        AppMetrica.reportEvent(name: "assetTradesDidPresent", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackAssetTradesDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        AppMetrica.reportEvent(name: "assetTradesDidDismiss", parameters: ["isTournament": isTournament, "symbol": symbol, "timespentSec": timespent])
    }

    public func trackAssetTradesDidTap(isTournament: Bool, symbol: String) {
        AppMetrica.reportEvent(name: "assetTradesDidTap", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackAssetOrdersDidPresent(isTournament: Bool, symbol: String) {
        AppMetrica.reportEvent(name: "assetOrdersDidPresent", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackAssetOrdersDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        AppMetrica.reportEvent(name: "assetOrdersDidDismiss", parameters: ["isTournament": isTournament, "symbol": symbol, "timespentSec": timespent])
    }

    public func trackAssetOrdersDidTap(isTournament: Bool, symbol: String, type: String) {
        AppMetrica.reportEvent(name: "assetOrdersDidTap", parameters: ["isTournament" : isTournament, "symbol" : symbol, "type" : type])
    }

    public func trackAssetTradeDetailDidPresent(isTournament: Bool, symbol: String) {
        AppMetrica.reportEvent(name: "assetTradeDetailDidPresent", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackAssetTradeDetailDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        AppMetrica.reportEvent(name: "tradingTradeDetailDidDismiss", parameters: ["isTournament": isTournament, "symbol": symbol, "timespentSec": timespent])
    }

    public func trackAssetOrderDetailDidPresent(isTournament: Bool, symbol: String) {
        AppMetrica.reportEvent(name: "assetOrderDetailDidPresent", parameters: ["isTournament" : isTournament, "symbol" : symbol])

    }

    public func trackAssetOrderDetailDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        AppMetrica.reportEvent(name: "assetOrderDetailDidDismiss", parameters: ["isTournament": isTournament, "symbol": symbol, "timespentSec": timespent])
    }

    public func trackNewOrderDidPresent(isTournament: Bool, symbol: String) {
        AppMetrica.reportEvent(name: "newOrderDidPresent", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackNewOrderDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        AppMetrica.reportEvent(name: "newOrderDidDismiss", parameters: ["isTournament": isTournament, "symbol": symbol, "timespentSec": timespent])
    }

    public func trackNewOrderDidSelectBuy(isTournament: Bool, symbol: String) {
        AppMetrica.reportEvent(name: "newOrderDidSelectBuy", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackNewOrderDidSelectSell(isTournament: Bool, symbol: String) {
        AppMetrica.reportEvent(name: "newOrderDidSelectSell", parameters: ["isTournament" : isTournament, "symbol" : symbol])
    }

    public func trackNewOrderDidSend(isTournament: Bool, symbol: String, amount: Decimal, takeProfit: Decimal, stopLoss: Decimal) {
        AppMetrica.reportEvent(name: "newOrderDidSend", parameters: ["isTournament" : isTournament, "symbol" : symbol, "amount" : amount.double, "takeProfit" : takeProfit.double, "stopLoss" : stopLoss.double])
    }

    public func trackAuctionDidPresent() {
        AppMetrica.reportEvent(name: "auctionDidPresent", parameters: nil)
    }

    public func trackAuctionDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "auctionDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackAuctionDidPlaceBid(amount: Decimal) {
        AppMetrica.reportEvent(name: "auctionDidPlaceBid", parameters: ["amount" : amount.double])
    }

    public func trackDailyRewardsDidPresent() {
        AppMetrica.reportEvent(name: "dailyRewardsDidPresent", parameters: nil)
    }

    public func trackDailyRewardsDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "dailyRewardsDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackDailyRewardsDidReceiveReward(day: Int) {
        AppMetrica.reportEvent(name: "dailyRewardsDidReceiveReward", parameters: ["day" : day])
    }

    public func trackDailyRewardsDidMultiplyReward(day: Int) {
        AppMetrica.reportEvent(name: "dailyRewardsDidMultiplyReward", parameters: ["day" : day])
    }

    public func trackLuckySpinDidPresent() {
        AppMetrica.reportEvent(name: "luckySpinDidPresent", parameters: nil)
    }

    public func trackLuckySpinDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "luckySpinDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackLuckySpinDidSpin() {
        AppMetrica.reportEvent(name: "luckySpinDidSpin", parameters: nil)
    }

    public func trackProfileDidPresent() {
        AppMetrica.reportEvent(name: "profileDidPresent", parameters: nil)
    }

    public func trackProfileDidTapAvatar() {
        AppMetrica.reportEvent(name: "profileDidTapAvatar", parameters: nil)
    }

    public func trackProfileDidTapAvatarEdit() {
        AppMetrica.reportEvent(name: "profileDidTapAvatarEdit", parameters: nil)
    }

    public func trackAvatarDidPresent() {
        AppMetrica.reportEvent(name: "avatarDidPresent", parameters: nil)
    }

    public func trackAvatarDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "avatarDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackAvatarDidTapChange() {
        AppMetrica.reportEvent(name: "avatarDidTapChange", parameters: nil)
    }

    public func trackUserProfileOtherDidPresent() {
        AppMetrica.reportEvent(name: "userProfileOtherDidPresent", parameters: nil)
    }

    public func trackSlotsDidPresent() {
        AppMetrica.reportEvent(name: "slotsDidPresent", parameters: nil)
    }

    public func trackSlotsDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "slotsDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackSlotsDidSpin(slotsCount: Int, totalSlotsCount: Int) {
        AppMetrica.reportEvent(name: "slotsDidSpin", parameters: ["slotsCount" : slotsCount, "totalSlotsCount" : totalSlotsCount])
        
    }

    public func trackSlotsDidLoad(loadingTime: Double) {
        AppMetrica.reportEvent(name: "slotsDidLoad", parameters: ["loadingTime" : loadingTime])
    }

    public func trackShopDidPresent() {
        AppMetrica.reportEvent(name: "shopDidPresent", parameters: nil)
    }

    public func trackShopDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "shopDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackShopItemDidPresent(id: String, price: Decimal) {
        AppMetrica.reportEvent(name: "shopItemDidPresent", parameters: ["id" : id, "price" : price.double])
    }

    public func trackShopItemDidDismiss(id: String, price: Decimal, timespent: Double) {
        AppMetrica.reportEvent(name: "shopItemDidDismiss", parameters: ["id": id, "price": price.double, "timespentSec": timespent])
    }

    public func trackShopItemDidPurchase(id: String, price: Decimal) {
        AppMetrica.reportEvent(name: "shopItemDidPurchase", parameters: ["id" : id, "price" : price.double])
    }

    public func trackRatingDidPresent(isTournament: Bool) {
        AppMetrica.reportEvent(name: "ratingDidPresent", parameters: ["isTournament" : isTournament])
    }

    public func trackRatingDidDismiss(isTournament: Bool, timespent: Double) {
        AppMetrica.reportEvent(name: "ratingDidDismiss", parameters: ["isTournament": isTournament, "timespentSec": timespent])
    }

    public func trackTournamentWelcomeDidPresent() {
        AppMetrica.reportEvent(name: "tournamentWelcomeDidPresent", parameters: nil)
    }

    public func trackTournamentWelcomeDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "tournamentWelcomeDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackTournamentWelcomeSignUp() {
        AppMetrica.reportEvent(name: "tournamentWelcomeSignUp", parameters: nil)
    }

    public func trackTournamentDidPresent() {
        AppMetrica.reportEvent(name: "tournamentDidPresent", parameters: nil)
    }

    public func trackTournamentDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "tournamentDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackChallengesDidPresent() {
        AppMetrica.reportEvent(name: "challengesDidPresent", parameters: nil)
    }

    public func trackChallengesDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "challengesDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackChallengesAwardDidReceive(id: String, level: Int) {
        AppMetrica.reportEvent(name: "challengesAwardDidReceive", parameters: ["id" : id, "level" : level])
    }

    public func trackFeedbackBegin() {
        AppMetrica.reportEvent(name: "feedbackBegin", parameters: nil)
    }

    public func trackFeedbackRate() {
        AppMetrica.reportEvent(name: "feedbackRate", parameters: nil)
    }

    public func trackFeedbackComplete() {
        AppMetrica.reportEvent(name: "feedbackComplete", parameters: nil)
    }

    public func trackFullAdDidRequest(in placement: String, type: String, displayCount: Int, fullScreenDisplayCount: Int,totalAdsDisplayCount: Int) {
        AppMetrica.reportEvent(name: "adDidRequest", parameters: ["placement" : placement, "type" : type, "displayCount": displayCount, "fullScreenDisplayCount": fullScreenDisplayCount,"totalAdsDisplayCount": totalAdsDisplayCount])
    }

    public func trackFullAdDidLoad(in placement: String, type: String, displayCount: Int, fullScreenDisplayCount: Int,totalAdsDisplayCount: Int, loadingTime: Double?) {
        var parameters: [AnyHashable : Any] = ["placement" : placement, "type" : type, "displayCount": displayCount, "fullScreenDisplayCount": fullScreenDisplayCount,"totalAdsDisplayCount": totalAdsDisplayCount]
        if let loadingTime { parameters["loadingTime"] = loadingTime }
        AppMetrica.reportEvent(name: "adDidLoad", parameters: parameters)
    }

    public func trackFullAdDidDisplay(in placement: String, type: String, failedRequests: Int, displayCount: Int, fullScreenDisplayCount: Int,totalAdsDisplayCount: Int, cpmLevel: Double?) {
        var parameters: [AnyHashable : Any] = ["placement" : placement, "type" : type, "displayCount": displayCount, "fullScreenDisplayCount": fullScreenDisplayCount,"totalAdsDisplayCount": totalAdsDisplayCount]
        if let cpmLevel { parameters["cpmLevel"] = cpmLevel }
        AppMetrica.reportEvent(name: "adDidDisplay", parameters: parameters)
    }

    public func trackBannerAdDidRequest(in placement: String, type: String, bannersDisplayCount: Int, displayCount: Int,totalAdsDisplayCount: Int) {
        AppMetrica.reportEvent(name: "adDidRequest", parameters: ["placement" : placement, "type" : type, "bannersDisplayCount": bannersDisplayCount, "displayCount": displayCount,"totalAdsDisplayCount": totalAdsDisplayCount])
    }

    public func trackBannerAdDidLoad(in placement: String, type: String, bannersDisplayCount: Int, displayCount: Int,totalAdsDisplayCount: Int, loadingTime: Double?) {
        var parameters: [AnyHashable : Any] = ["placement" : placement, "type" : type, "bannersDisplayCount": bannersDisplayCount, "displayCount": displayCount,"totalAdsDisplayCount": totalAdsDisplayCount]
        if let loadingTime { parameters["loadingTime"] = loadingTime }
        AppMetrica.reportEvent(name: "adDidLoad", parameters: parameters)
    }

    public func trackBannerAdDidDisplay(in placement: String, type: String, failedRequests: Int, bannersDisplayCount: Int, displayCount: Int,totalAdsDisplayCount: Int, cpmLevel: Double?) {
        var parameters: [AnyHashable : Any] = ["placement" : placement, "type" : type, "bannersDisplayCount": bannersDisplayCount, "displayCount": displayCount,"totalAdsDisplayCount": totalAdsDisplayCount]
        if let cpmLevel { parameters["cpmLevel"] = cpmLevel }
        AppMetrica.reportEvent(name: "adDidDisplay", parameters: parameters)
    }

    public func trackAdDidSkipPresent(in placement: String, type: String, failedRequests: Int, cpmLevel: Double) {
        AppMetrica.reportEvent(name: "adDidSkipPresent", parameters: ["placement" : placement, "type" : type, "failedRequests": failedRequests, "cpmLevel": cpmLevel])
    }

    public func trackAdDidFailToLoad(in placement: String, type: String, failedRequests: Int, error: String?) {
        AppMetrica.reportEvent(name: "adDidFailToLoad", parameters: ["placement" : placement, "type" : type, "failedRequests": failedRequests, "error": error ?? "unknown"])
    }

    public func trackAdDidFailToDisplay(in placement: String, type: String) {
        AppMetrica.reportEvent(name: "adDidFailToDisplay", parameters: ["placement" : placement, "type" : type])
    }

    public func trackAdDidHide(in placement: String, type: String) {
        AppMetrica.reportEvent(name: "adDidHide", parameters: ["placement" : placement, "type" : type])
    }

    public func trackAdDidClick(in placement: String, type: String) {
        AppMetrica.reportEvent(name: "adDidClick", parameters: ["placement" : placement, "type" : type])
    }

    public func trackAdDidReward(in placement: String, type: String) {
        AppMetrica.reportEvent(name: "adDidReward", parameters: ["placement" : placement, "type" : type])
    }

    public func trackAdRevenue(in placement: String, type: String, value: Decimal, currency: String, network: String, adNetwork: String, unitId: String) {
        AppMetrica.reportEvent(name: "adRevenue", parameters: ["placement" : placement, "type" : type, "value" : value.double, "currency" : currency, "network" : network])
        
        let adRevenueInfo = MutableAdRevenueInfo(adRevenue: value.nsDecimalNumber, currency: currency)
        
        if type.lowercased().contains("banner") {
            adRevenueInfo.adType = .banner
        } else if type.lowercased().contains("interstitial") {
            adRevenueInfo.adType = .interstitial
        } else if type.lowercased().contains("rewarded") {
            adRevenueInfo.adType = .rewarded
        } else if type.lowercased().contains("native") {
            adRevenueInfo.adType = .native
        } else {
            adRevenueInfo.adType = .other
        }
        
        adRevenueInfo.adNetwork = network
        adRevenueInfo.adPlacementName = placement
        adRevenueInfo.precision = "estimated"
        
        AppMetrica.reportAdRevenue(adRevenueInfo)
    }

    public func trackPrivacyPolicy() {
        AppMetrica.reportEvent(name: "openPrivacyPolicy", parameters: nil)
    }

    public func trackTermsOfUse() {
        AppMetrica.reportEvent(name: "openTermsOfUse", parameters: nil)
    }

    public func trackArticleListDidPresent() {
        AppMetrica.reportEvent(name: "articleListDidPresent", parameters: nil)
    }

    public func trackArticleListDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "articleListDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackArticleDetailDidPresent(id: String) {
        AppMetrica.reportEvent(name: "articleDetailDidPresent", parameters: ["id" : id])
    }

    public func trackArticleDetailDidDismiss(id: String, timespent: Double) {
        AppMetrica.reportEvent(name: "articleDetailDidDismiss", parameters: ["id": id, "timespentSec": timespent])
    }

    public func trackNotificationDidOpen(_ userInfo: [String : Any]) {
        AppMetrica.reportEvent(name: "notificationDidOpen", parameters: nil)
    }

    public func trackError(name: String?, error: String?) {
        AppMetrica.reportEvent(name: "didError", parameters: ["name" : name ?? "unknown", "error" : "unknown"])
    }

    public func trackStakingPoolsDidPresent() {
        AppMetrica.reportEvent(name: "stakingPoolsDidPresent", parameters: nil)
    }

    public func trackStakingPoolsDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "stakingPoolsDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackStakingPoolsDidTapInvest(coin: String, invested: Decimal, size: Decimal, roi: Decimal, duration: Int) {
        AppMetrica.reportEvent(name: "stakingPoolsDidTapInvest", parameters: [
            "coin": coin,
            "invested": invested.double,
            "size": size.double,
            "roi": roi,
            "duration": duration
        ])
    }

    public func trackStakingPortfolioDidPresent() {
        AppMetrica.reportEvent(name: "stakingPortfolioDidPresent", parameters: nil)
    }

    public func trackStakingPortfolioDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "stakingPortfolioDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackStakingPortfolioDidTapCollect(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        AppMetrica.reportEvent(name: "stakingPortfolioDidTapCollect", parameters: [
            "coin": coin,
            "roi": roi,
            "amount": amount.double,
            "duration": duration
        ])
    }

    public func trackStakingPortfolioDidTapRepair(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        AppMetrica.reportEvent(name: "stakingPortfolioDidTapRepair", parameters: [
            "coin": coin,
            "roi": roi,
            "amount": amount.double,
            "duration": duration
        ])
    }

    public func trackStakingRatingDidPresent() {
        AppMetrica.reportEvent(name: "stakingRatingDidPresent", parameters: nil)
    }

    public func trackStakingRatingDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "stakingRatingDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackStakingRatingDidTapUser(position: Int) {
        AppMetrica.reportEvent(name: "stakingRatingDidTapUser", parameters: ["position": position])
    }

    public func trackStakingInvestAmountDidPresent() {
        AppMetrica.reportEvent(name: "stakingInvestAmountDidPresent", parameters: nil)
    }

    public func trackStakingInvestAmountDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "stakingInvestAmountDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackStakingInvestAmountDidTapInvest(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        AppMetrica.reportEvent(name: "stakingInvestAmountDidTapInvest", parameters: [
            "coin": coin,
            "roi": roi,
            "amount": amount.double,
            "duration": duration
        ])
    }

    public func trackStakingInvestAmountDidTapInvestWithProtection(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        AppMetrica.reportEvent(name: "stakingInvestAmountDidTapInvestWithProtection", parameters: [
            "coin": coin,
            "roi": roi,
            "amount": amount.double,
            "duration": duration
        ])
    }

    public func trackStakingPoolHackedDidPresent() {
        AppMetrica.reportEvent(name: "stakingPoolHackedDidPresent", parameters: nil)
    }

    public func trackStakingPoolHackedDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "stakingPoolHackedDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackStakingPoolHackedDidTapProtection(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        AppMetrica.reportEvent(name: "stakingPoolHackedDidTapProtection", parameters: [
            "coin": coin,
            "roi": roi,
            "amount": amount.double,
            "duration": duration
        ])
    }

    public func trackStakingPoolHackedDidTapLossMoney(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        AppMetrica.reportEvent(name: "stakingPoolHackedDidTapLossMoney", parameters: [
            "coin": coin,
            "roi": roi,
            "amount": amount.double,
            "duration": duration
        ])
    }

    public func trackStakingProfitMultiplyDidPresent() {
        AppMetrica.reportEvent(name: "stakingProfitMultiplyDidPresent", parameters: nil)
    }

    public func trackStakingProfitMultiplyDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "stakingProfitMultiplyDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackStakingProfitMultiplyDidTapMultiply(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        AppMetrica.reportEvent(name: "stakingProfitMultiplyDidTapMultiply", parameters: [
            "coin": coin,
            "roi": roi,
            "amount": amount.double,
            "duration": duration
        ])
    }

    public func trackStakingProfitMultiplyDidTapNotNow(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        AppMetrica.reportEvent(name: "stakingProfitMultiplyDidTapNotNow", parameters: [
            "coin": coin,
            "roi": roi,
            "amount": amount.double,
            "duration": duration
        ])
    }

    public func trackSessionStart(trigger: String, textNumber: String, code: String) {
        AppMetrica.reportEvent(name: "sessionStart", parameters: ["trigger": trigger, "textNumber": textNumber, "code": code])
    }

    public func trackSessionFinish(duration: Double) {
        AppMetrica.reportEvent(name: "sessionFinish", parameters: ["sessionLength": duration])
    }

    public func trackInstall() {
        AppMetrica.reportEvent(name: "applicationDidInstall", parameters: nil)
    }

    public func trackMinerCollectMultiplyDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "minerCollectMultiplyDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackMinerCollectMultiplyDidPresent() {
        AppMetrica.reportEvent(name: "minerCollectMultiplyDidPresent", parameters: nil)
    }

    public func trackMinerCollectMultiplyDidTapCollect() {
        AppMetrica.reportEvent(name: "minerCollectMultiplyDidTapCollect", parameters: nil)
    }

    public func trackMinerCollectMultiplyDidTapMultiply() {
        AppMetrica.reportEvent(name: "minerCollectMultiplyDidTapMultiply", parameters: nil)
    }

    public func trackMinerDidCollect() {
        AppMetrica.reportEvent(name: "minerDidCollect", parameters: nil)
    }

    public func trackMinerDidCreate() {
        AppMetrica.reportEvent(name: "minerDidCreate", parameters: nil)
    }

    public func trackMinerDidCreateForAd() {
        AppMetrica.reportEvent(name: "minerDidCreateForAd", parameters: nil)
    }

    public func trackMinerDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "minerDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackMinerDidFailUpdate() {
        AppMetrica.reportEvent(name: "minerDidFailUpdate", parameters: nil)
    }

    public func trackMinerDidFix() {
        AppMetrica.reportEvent(name: "minerDidFix", parameters: nil)
    }

    public func trackMinerDidPresent() {
        AppMetrica.reportEvent(name: "minerDidPresent", parameters: nil)
    }

    public func trackMinerDidStartUpdate() {
        AppMetrica.reportEvent(name: "minerDidStartUpdate", parameters: nil)
    }

    public func trackMinerDidUpdate() {
        AppMetrica.reportEvent(name: "minerDidUpdate", parameters: nil)
    }

    public func trackMinerFixDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "minerFixDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackMinerFixDidPresent() {
        AppMetrica.reportEvent(name: "minerFixDidPresent", parameters: nil)
    }

    public func trackMinersListBannerDidPresent(type: String) {
        AppMetrica.reportEvent(name: "minersListBannerDidPresent", parameters: ["type": type])
    }

    public func trackMinersListBannerDidTap(type: String) {
        AppMetrica.reportEvent(name: "minersListBannerDidTap", parameters: ["type": type])
    }

    public func trackMinersListDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "minersListDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackMinersListDidPresent() {
        AppMetrica.reportEvent(name: "minersListDidPresent", parameters: nil)
    }

    public func trackOtherUserDidLike() {
        AppMetrica.reportEvent(name: "otherUserDidLike", parameters: nil)
    }

    public func trackOtherUserDidUnlike() {
        AppMetrica.reportEvent(name: "otherUserDidUnlike", parameters: nil)
    }

    public func trackOtherUserLikesDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "otherUserLikesDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackOtherUserLikesDidPresent() {
        AppMetrica.reportEvent(name: "otherUserLikesDidPresent", parameters: nil)
    }

    public func trackOtherUserLikesDidTap() {
        AppMetrica.reportEvent(name: "otherUserLikesDidTap", parameters: nil)
    }

    public func trackProfileDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "profileDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackUserLikesDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "userLikesDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackUserLikesDidPresent() {
        AppMetrica.reportEvent(name: "userLikesDidPresent", parameters: nil)
    }

    public func trackUserLikesDidTap() {
        AppMetrica.reportEvent(name: "userLikesDidTap", parameters: nil)
    }

    public func trackUserProfileOtherDidDismiss(timespent: Double) {
        AppMetrica.reportEvent(name: "userProfileOtherDidDismiss", parameters: ["timespentSec": timespent])
    }

    public func trackDashboardDidTapStartup() {
        AppMetrica.reportEvent(name: "dashboardDidTapStartup", parameters: nil)
    }

    public func trackStartupDidChangeAmount(amount: Double, previousAmount: Double) {
        AppMetrica.reportEvent(name: "startupDidTapChangeInvestmentAmount", parameters: ["amount": amount, "previousAmount": previousAmount])
    }

    public func trackStartupDidCrash(amount: Double, multiplier: Double, investmentCount: Int) {
        AppMetrica.reportEvent(name: "startupDidCrash", parameters: ["amount": amount, "multiplier": multiplier, "investmentCount": investmentCount])
    }

    public func trackStartupDidDismiss(timespent: Double, timespentSec: Int) {
        AppMetrica.reportEvent(name: "startupDidDismiss", parameters: ["timespent": timespent, "timespentSec": timespentSec])
    }

    public func trackStartupDidPresent() {
        AppMetrica.reportEvent(name: "startupDidPresent", parameters: nil)
    }

    public func trackStartupDidTapCollectReward(profit: Double) {
        AppMetrica.reportEvent(name: "startupDidTapCollectReward", parameters: ["profit": profit])
    }

    public func trackStartupDidTapDoubleReward(profit: Double) {
        AppMetrica.reportEvent(name: "startupDidTapDoubleReward", parameters: ["profit": profit])
    }

    public func trackStartupDidTapGetProfit(amount: Double, multiplier: Double, investmentCount: Int) {
        AppMetrica.reportEvent(name: "startupDidTapTakeProfit", parameters: ["amount": amount, "multiplier": multiplier, "investmentCount": investmentCount])
    }

    public func trackStartupDidTapInvest(amount: Double, investmentCount: Int) {
        AppMetrica.reportEvent(name: "startupDidTapInvest", parameters: ["amount": amount, "investmentCount": investmentCount])
    }

    public func trackStartupDidTapTryAgain() {
        AppMetrica.reportEvent(name: "startupDidTapTryAgain", parameters: nil)
    }

    public func trackStartupLoseScreenDidPresent() {
        AppMetrica.reportEvent(name: "startupLoseScreenDidPresent", parameters: nil)
    }

    public func trackStartupWinScreenDidPresent() {
        AppMetrica.reportEvent(name: "startupWinScreenDidPresent", parameters: nil)
    }

    public func trackTradingDidTrade(isTournament: Bool, symbol: String, direction: String, stake: Decimal) {
        AppMetrica.reportEvent(name: "tradingDidTrade", parameters: ["isTournament" : isTournament, "symbol" : symbol, "direction" : direction, "stake" : stake.double])
    }
}
