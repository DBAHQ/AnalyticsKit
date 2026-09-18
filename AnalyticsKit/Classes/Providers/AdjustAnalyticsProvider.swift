//
//  AdjustAnalyticsProvider.swift
//  AnalyticsKit
//
//  Adjust получает лишь те события, для которых приложение дало токен.
//  Поэтому провайдер частичный: всё остальное гасится пустыми реализациями
//  из `PartialAnalyticsProvider`.
//

import Foundation
import AdjustSdk

public final class AdjustAnalyticsProvider: NSObject, PartialAnalyticsProvider {

    public var userID: String { AnalyticsKit.configuration.userID() }

    public override init() {
        super.init()
    }

    // MARK: - Lifecycle

    public func start() {
        let config = AnalyticsKit.configuration
        let environment = (config.isProduction ? ADJEnvironmentProduction : ADJEnvironmentSandbox) as String
        let adjustConfig = ADJConfig(appToken: config.adjustAppToken, environment: environment)
        // Delayed mode (Adjust v5): SDK инициализируется в память и НЕ отправляет первую
        // сессию, пока не будет вызван endFirstSessionDelay() — после ответа по ATT.
        adjustConfig?.enableFirstSessionDelay()
        if AnalyticsKit.configuration.isLoggingEnabled {
            adjustConfig?.logLevel = .verbose
        }
        // Делегат — единственный способ узнать вердикт сервера Adjust на
        // Production-сборке: собственные логи SDK там отключены наглухо
        // (в ADJLogger каждый метод начинается с `if isProductionEnvironment return`).
        adjustConfig?.delegate = self
        Adjust.initSdk(adjustConfig)
        AnalyticsKitLog.log("Adjust поднят, среда \(environment), токенов событий: \(config.adjustEventTokens.count)")
    }

    /// Adjust v5: отпускает придержанную первую сессию. Зовётся после ответа
    /// пользователя по ATT и отправки DMA-согласий.
    public static func endFirstSessionDelay() {
        Adjust.endFirstSessionDelay()
    }

    // MARK: - Private

    private func token(_ event: AdjustEvent) -> String? {
        AnalyticsKit.configuration.adjustEventTokens[event]
    }

    /// Отправляет событие, если приложение дало для него токен.
    private func send(_ event: AdjustEvent, _ parameters: [String: String] = [:]) {
        guard let token = token(event) else {
            AnalyticsKitLog.log("Adjust пропускает '\(event.rawValue)' — токена нет в карте")
            return
        }
        guard let adjEvent = ADJEvent(eventToken: token) else {
            AnalyticsKitLog.log("Adjust НЕ создал событие '\(event.rawValue)' по токену \(token)")
            return
        }
        AnalyticsKitLog.log("Adjust шлёт '\(event.rawValue)' токеном \(token)")
        for (key, value) in parameters {
            adjEvent.addPartnerParameter(key, value: value)
        }
        Adjust.trackEvent(adjEvent)
    }

    // MARK: - Events

    public func onboardingComplete() {
        send(.onboardingComplete)
    }

    public func featureTutorialComplete(flow: String) {
        send(.featureTutorialComplete, ["flow": flow])
    }

    public func trackChallengesAwardDidReceive(id: String, level: Int) {
        send(.challengesAwardDidReceive, ["id": id, "level": String(level)])
    }

    public func trackAuthSignUpBegin() {
        send(.authSignUpBegin)
    }

    public func trackAuthSignUpComplete() {
        send(.authSignUpComplete)
    }

    public func trackAuthOAuthComplete(_ type: String) {
        send(.authOAuthComplete, ["type": type])
    }

    public func trackTradingDidTrade(isTournament: Bool, symbol: String, direction: String, stake: Decimal) {
        send(.tradingDidTrade, ["isTournament": String(isTournament),
                                "symbol": symbol,
                                "direction": direction,
                                "stake": stake.description])
    }

    public func trackNewOrderDidSend(isTournament: Bool, symbol: String, amount: Decimal,
                                     takeProfit: Decimal, stopLoss: Decimal) {
        send(.newOrderDidSend, ["isTournament": String(isTournament),
                                "symbol": symbol,
                                "amount": amount.description])
    }

    public func trackShopItemDidPurchase(id: String, price: Decimal) {
        send(.shopItemDidPurchase, ["id": id, "price": price.description])
    }

    // MARK: - Ad revenue

    public func trackAdRevenue(in placement: String, type: String, value: Decimal,
                               currency: String, network: String, adNetwork: String, unitId: String) {
        send(.adRevenue, ["placement": placement,
                          "type": type,
                          "value": "\(value)",
                          "currency": currency,
                          "network": network])

        guard let adRevenue = ADJAdRevenue(source: Self.adjustSource(for: network)) else { return }
        adRevenue.setAdRevenueUnit(placement)
        adRevenue.setAdRevenuePlacement(placement)
        adRevenue.setAdRevenueNetwork(network)
        adRevenue.setRevenue(value.double, currency: currency.uppercased())
        Adjust.trackAdRevenue(adRevenue)
    }

    /// Источник дохода в терминах Adjust.
    private static func adjustSource(for network: String) -> String {
        switch network.lowercased() {
        case "applovin":              return "applovin_max_sdk"
        case "admob", "google":       return "admob_sdk"
        case "ironsource":            return "ironsource_sdk"
        default:                      return "publisher_sdk"
        }
    }
}

// MARK: - Вердикт сервера Adjust

extension AdjustAnalyticsProvider: AdjustDelegate {

    public func adjustEventTrackingSucceeded(_ eventSuccessResponse: ADJEventSuccess?) {
        let token = eventSuccessResponse?.eventToken ?? "?"
        AnalyticsKitLog.log("Adjust ПРИНЯЛ событие, токен \(token), adid \(eventSuccessResponse?.adid ?? "—")")
    }

    public func adjustEventTrackingFailed(_ eventFailureResponse: ADJEventFailure?) {
        let token = eventFailureResponse?.eventToken ?? "?"
        let message = eventFailureResponse?.message ?? "без сообщения"
        let retry = eventFailureResponse?.willRetry == true ? ", будет повтор" : ""
        let json = eventFailureResponse?.jsonResponse.map { "\($0)" } ?? "нет тела ответа"
        AnalyticsKitLog.log("Adjust ОТКЛОНИЛ событие, токен \(token): \(message)\(retry) | ответ: \(json)")
    }

    public func adjustSessionTrackingSucceeded(_ sessionSuccessResponse: ADJSessionSuccess?) {
        AnalyticsKitLog.log("Adjust принял сессию, adid \(sessionSuccessResponse?.adid ?? "—")")
    }

    public func adjustSessionTrackingFailed(_ sessionFailureResponse: ADJSessionFailure?) {
        let message = sessionFailureResponse?.message ?? "без сообщения"
        let json = sessionFailureResponse?.jsonResponse.map { "\($0)" } ?? "нет тела ответа"
        AnalyticsKitLog.log("Adjust отклонил сессию: \(message) | ответ: \(json)")
    }
}
