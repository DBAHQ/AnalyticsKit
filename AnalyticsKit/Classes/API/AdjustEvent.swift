//
//  AdjustEvent.swift
//  AnalyticsKit
//
//  В Adjust уходит не весь каталог событий, а единицы: те, что настроены
//  в кабинете и на которые смотрит закупка. Приложение перечисляет их в
//  `AnalyticsConfiguration.adjustEventTokens`; событие без токена в карте
//  просто не отправляется.
//

import Foundation

public enum AdjustEvent: String, CaseIterable {
    case onboardingComplete
    case featureTutorialComplete
    case challengesAwardDidReceive
    case authSignUpBegin
    case authSignUpComplete
    case authOAuthComplete
    case tradingDidTrade
    case shopItemDidPurchase

    /// Отдельное событие дохода. Рядом с ним всегда уходит нативный
    /// `Adjust.trackAdRevenue`, он токена не требует.
    case adRevenue
}
