//
//  AnalyticsProvider.swift
//  AnalyticsKit
//
//  Объединённый контракт продуктовых событий всех пяти приложений.
//
//  Часть методов относится к фичам, которых в конкретном приложении нет
//  (стейкинг, майнинг, startup): приложение их просто не вызывает.
//  Типы приложения в контракт не протекают — `flow` и OAuth-`type` приходят
//  строками, приложение подставляет `.rawValue` своего энума.
//

import Foundation

public protocol AnalyticsProvider: AnyObject {
    
    // MARK: - Properties
    
    var userID: String { get }
    
    // MARK: - Methods
    
    func start()
    
    // MARK: - Onboarding Analytics
    
    func onboardingBegin()
    func onboardingStepPresent(step: String)
    func onboardingStepContinue(step: String)
    func onboardingComplete()
    
    // MARK: - Feature Tutorial Analytics
    
    func featureTutorialBegin(flow: String)
    func featureTutorialStepPresent(flow: String, step: String)
    func featureTutorialStepContinue(flow: String, step: String)
    func featureTutorialSkip(flow: String, step: String)
    func featureTutorialComplete(flow: String)
    
    func trackAuthDidPresent()
    func trackAuthDidDismiss(timespent: Double)
    func trackAuthSignIn()
    func trackAuthSignUpBegin()
    func trackAuthSignUpComplete()
    func trackAuthOAuthBegin(_ type: String)
    func trackAuthOAuthComplete(_ type: String)
    
    func trackDashboardDidPresent()
    func trackDashboardDidDismiss(timespent: Double)
    func trackDashboardDidTapSettings()
    func trackDashboardDidTapSignUp()
    func trackDashboardDidTapProfile()
    func trackDashboardDidTapNotifications()
    func trackDashboardDidTapBalance()
    func trackDashboardDidTapBonusAd()
    func trackDashboardDidTapDailyRewards()
    func trackDashboardDidTapLuckySpin()
    func trackDashboardDidTapChallenges()
    func trackDashboardDidTapDemoAccount()
    func trackDashboardDidTapShop()
    func trackDashboardDidTapPremium()
    func trackDashboardDidTapAuction()
    func trackDashboardDidTapAppearance()
    func trackDashboardDidTapStaking()
    func trackDashboardDidTapSlots()
    
    func trackTradingPortfolioDidPresent(isTournament: Bool)
    func trackTradingPortfolioDidDismiss(isTournament: Bool, timespent: Double)
    func trackTradingPortfolioDidTap(isTournament: Bool, symbol: String)
    func trackTradingMarketDidPresent(isTournament: Bool)
    func trackTradingMarketDidDismiss(isTournament: Bool, timespent: Double)
    func trackTradingMarketDidTap(isTournament: Bool, symbol: String)
    func trackTradingTradesDidPresent(isTournament: Bool)
    func trackTradingTradesDidDismiss(isTournament: Bool, timespent: Double)
    func trackTradingTradesDidTap(isTournament: Bool, symbol: String)
    func trackTradingOrdersDidPresent(isTournament: Bool)
    func trackTradingOrdersDidDismiss(isTournament: Bool, timespent: Double)
    func trackTradingOrdersDidTap(isTournament: Bool, symbol: String, type: String)
    
    func trackAssetTradingDidPresent(isTournament: Bool, symbol: String)
    func trackAssetTradingDidDismiss(isTournament: Bool, symbol: String, timespent: Double)
    func trackAssetTradingDidTapProChart(isTournament: Bool, symbol: String)
    func trackAssetTradingDidTapBonusAd(isTournament: Bool, symbol: String)
    func trackAssetTradingDidTapBuy(isTournament: Bool, symbol: String)
    func trackAssetTradingDidTapSell(isTournament: Bool, symbol: String)
    func trackAssetTradesDidPresent(isTournament: Bool, symbol: String)
    func trackAssetTradesDidDismiss(isTournament: Bool, symbol: String, timespent: Double)
    func trackAssetTradesDidTap(isTournament: Bool, symbol: String)
    func trackAssetOrdersDidPresent(isTournament: Bool, symbol: String)
    func trackAssetOrdersDidDismiss(isTournament: Bool, symbol: String, timespent: Double)
    func trackAssetOrdersDidTap(isTournament: Bool, symbol: String, type: String)
    
    func trackAssetTradeDetailDidPresent(isTournament: Bool, symbol: String)
    func trackAssetTradeDetailDidDismiss(isTournament: Bool, symbol: String, timespent: Double)
    func trackAssetOrderDetailDidPresent(isTournament: Bool, symbol: String)
    func trackAssetOrderDetailDidDismiss(isTournament: Bool, symbol: String, timespent: Double)
    
    func trackNewOrderDidPresent(isTournament: Bool, symbol: String)
    func trackNewOrderDidDismiss(isTournament: Bool, symbol: String, timespent: Double)
    func trackNewOrderDidSelectBuy(isTournament: Bool, symbol: String)
    func trackNewOrderDidSelectSell(isTournament: Bool, symbol: String)
    func trackNewOrderDidSend(isTournament: Bool, symbol: String, amount: Decimal, takeProfit: Decimal, stopLoss: Decimal)
    
    func trackAuctionDidPresent()
    func trackAuctionDidDismiss(timespent: Double)
    func trackAuctionDidPlaceBid(amount: Decimal)
    
    func trackDailyRewardsDidPresent()
    func trackDailyRewardsDidDismiss(timespent: Double)
    func trackDailyRewardsDidReceiveReward(day: Int)
    func trackDailyRewardsDidMultiplyReward(day: Int)
    
    func trackLuckySpinDidPresent()
    func trackLuckySpinDidDismiss(timespent: Double)
    func trackLuckySpinDidSpin()
    
    func trackProfileDidPresent()
    func trackProfileDidTapAvatar()
    func trackProfileDidTapAvatarEdit()
    func trackAvatarDidPresent()
    func trackAvatarDidDismiss(timespent: Double)
    func trackAvatarDidTapChange()
    func trackUserProfileOtherDidPresent()

    func trackSlotsDidPresent()
    func trackSlotsDidDismiss(timespent: Double)
    func trackSlotsDidSpin(slotsCount: Int, totalSlotsCount: Int)
    func trackSlotsDidLoad(loadingTime: Double)
    
    func trackShopDidPresent()
    func trackShopDidDismiss(timespent: Double)
    func trackShopItemDidPresent(id: String, price: Decimal)
    func trackShopItemDidDismiss(id: String, price: Decimal, timespent: Double)
    func trackShopItemDidPurchase(id: String, price: Decimal)
    
    func trackRatingDidPresent(isTournament: Bool)
    func trackRatingDidDismiss(isTournament: Bool, timespent: Double)
    
    func trackTournamentWelcomeDidPresent()
    func trackTournamentWelcomeDidDismiss(timespent: Double)
    func trackTournamentWelcomeSignUp()
    func trackTournamentDidPresent()
    func trackTournamentDidDismiss(timespent: Double)
    
    func trackChallengesDidPresent()
    func trackChallengesDidDismiss(timespent: Double)
    func trackChallengesAwardDidReceive(id: String, level: Int)
    
    func trackFeedbackBegin()
    func trackFeedbackRate()
    func trackFeedbackComplete()
    
    func trackFullAdDidRequest(in placement: String, type: String, displayCount: Int, fullScreenDisplayCount: Int,totalAdsDisplayCount: Int)

    func trackFullAdDidLoad(in placement: String, type: String, displayCount: Int, fullScreenDisplayCount: Int,totalAdsDisplayCount: Int, loadingTime: Double?)

    func trackFullAdDidDisplay(in placement: String, type: String, failedRequests: Int, displayCount: Int, fullScreenDisplayCount: Int,totalAdsDisplayCount: Int, cpmLevel: Double?)

    func trackBannerAdDidRequest(in placement: String, type: String, bannersDisplayCount: Int, displayCount: Int,totalAdsDisplayCount: Int)

    func trackBannerAdDidLoad(in placement: String, type: String, bannersDisplayCount: Int, displayCount: Int,totalAdsDisplayCount: Int, loadingTime: Double?)

    func trackBannerAdDidDisplay(in placement: String, type: String, failedRequests: Int, bannersDisplayCount: Int, displayCount: Int,totalAdsDisplayCount: Int, cpmLevel: Double?)

    /// Показ рекламы пропущен из-за низкого CPM (CPM-бэкофф). Параметры как у adDidFailToLoad,
    /// плюс cpmLevel — на сколько % CPM ниже базового первого показа сессии (выше базового → со знаком минус).
    func trackAdDidSkipPresent(in placement: String, type: String, failedRequests: Int, cpmLevel: Double)

    func trackAdDidFailToLoad(in placement: String, type: String, failedRequests: Int, error: String?)
    func trackAdDidFailToDisplay(in placement: String, type: String)
    func trackAdDidHide(in placement: String, type: String)
    func trackAdDidClick(in placement: String, type: String)
    func trackAdDidReward(in placement: String, type: String)
    func trackAdRevenue(in placement: String, type: String, value: Decimal, currency: String, network: String, adNetwork: String, unitId: String)
    
    func trackPrivacyPolicy()
    func trackTermsOfUse()
    
    func trackArticleListDidPresent()
    func trackArticleListDidDismiss(timespent: Double)
    func trackArticleDetailDidPresent(id: String)
    func trackArticleDetailDidDismiss(id: String, timespent: Double)
    
    func trackNotificationDidOpen(_ userInfo: [String : Any])
    
    func trackError(name: String?, error: String?)
    
    // MARK: - Staking
    
    func trackStakingPoolsDidPresent()
    func trackStakingPoolsDidDismiss(timespent: Double)
    func trackStakingPoolsDidTapInvest(coin: String, invested: Decimal, size: Decimal, roi: Decimal, duration: Int)
    
    func trackStakingPortfolioDidPresent()
    func trackStakingPortfolioDidDismiss(timespent: Double)
    func trackStakingPortfolioDidTapCollect(coin: String, roi: Decimal, amount: Decimal, duration: Int)
    func trackStakingPortfolioDidTapRepair(coin: String, roi: Decimal, amount: Decimal, duration: Int)
    
    func trackStakingRatingDidPresent()
    func trackStakingRatingDidDismiss(timespent: Double)
    func trackStakingRatingDidTapUser(position: Int)
    
    func trackStakingInvestAmountDidPresent()
    func trackStakingInvestAmountDidDismiss(timespent: Double)
    func trackStakingInvestAmountDidTapInvest(coin: String, roi: Decimal, amount: Decimal, duration: Int)
    func trackStakingInvestAmountDidTapInvestWithProtection(coin: String, roi: Decimal, amount: Decimal, duration: Int)
    
    func trackStakingPoolHackedDidPresent()
    func trackStakingPoolHackedDidDismiss(timespent: Double)
    func trackStakingPoolHackedDidTapProtection(coin: String, roi: Decimal, amount: Decimal, duration: Int)
    func trackStakingPoolHackedDidTapLossMoney(coin: String, roi: Decimal, amount: Decimal, duration: Int)
    
    func trackStakingProfitMultiplyDidPresent()
    func trackStakingProfitMultiplyDidDismiss(timespent: Double)
    func trackStakingProfitMultiplyDidTapMultiply(coin: String, roi: Decimal, amount: Decimal, duration: Int)
    func trackStakingProfitMultiplyDidTapNotNow(coin: String, roi: Decimal, amount: Decimal, duration: Int)

    // MARK: - Session

    func trackSessionStart(trigger: String, textNumber: String, code: String)
    func trackSessionFinish(duration: Double)
    func trackInstall()

    // MARK: - Майнинг, лайки и профиль
    // Есть в GoTrading и Gocrypto.
    func trackMinerCollectMultiplyDidDismiss(timespent: Double)
    func trackMinerCollectMultiplyDidPresent()
    func trackMinerCollectMultiplyDidTapCollect()
    func trackMinerCollectMultiplyDidTapMultiply()
    func trackMinerDidCollect()
    func trackMinerDidCreate()
    func trackMinerDidCreateForAd()
    func trackMinerDidDismiss(timespent: Double)
    func trackMinerDidFailUpdate()
    func trackMinerDidFix()
    func trackMinerDidPresent()
    func trackMinerDidStartUpdate()
    func trackMinerDidUpdate()
    func trackMinerFixDidDismiss(timespent: Double)
    func trackMinerFixDidPresent()
    func trackMinersListBannerDidPresent(type: String)
    func trackMinersListBannerDidTap(type: String)
    func trackMinersListDidDismiss(timespent: Double)
    func trackMinersListDidPresent()
    func trackOtherUserDidLike()
    func trackOtherUserDidUnlike()
    func trackOtherUserLikesDidDismiss(timespent: Double)
    func trackOtherUserLikesDidPresent()
    func trackOtherUserLikesDidTap()
    func trackProfileDidDismiss(timespent: Double)
    func trackUserLikesDidDismiss(timespent: Double)
    func trackUserLikesDidPresent()
    func trackUserLikesDidTap()
    func trackUserProfileOtherDidDismiss(timespent: Double)

    // MARK: - Startup
    // Есть только в GoTrading.
    func trackDashboardDidTapStartup()
    func trackStartupDidChangeAmount(amount: Double, previousAmount: Double)
    func trackStartupDidCrash(amount: Double, multiplier: Double, investmentCount: Int)
    func trackStartupDidDismiss(timespent: Double, timespentSec: Int)
    func trackStartupDidPresent()
    func trackStartupDidTapCollectReward(profit: Double)
    func trackStartupDidTapDoubleReward(profit: Double)
    func trackStartupDidTapGetProfit(amount: Double, multiplier: Double, investmentCount: Int)
    func trackStartupDidTapInvest(amount: Double, investmentCount: Int)
    func trackStartupDidTapTryAgain()
    func trackStartupLoseScreenDidPresent()
    func trackStartupWinScreenDidPresent()

    // MARK: - Ставки
    // Есть только в TradingClub.
    func trackTradingDidTrade(isTournament: Bool, symbol: String, direction: String, stake: Decimal)

}
