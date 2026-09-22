//
//  AppLovinEventTracker.swift
//  AnalyticsKit
//
//  Отправка пользовательских событий в AppLovin через `ALSdk.eventService`
//  (документ AppLovin «Gaming — Tracking User Events with the SDK»).
//
//  Трекер намеренно не входит в `AnalyticsProvider`: эти события уходят только
//  в AppLovin и не дублируются в Firebase/Adjust/AppMetrica.
//
//  `ALSdk` инициализируется асинхронно, поэтому события, отправленные до
//  колбэка инициализации (`app_open` на старте, `tutorial_complete` у быстрых
//  юзеров), копятся в очереди и уходят из `sdkDidInitialize()`.
//

import Foundation
import AppLovinSDK

public final class AppLovinEventTracker {

    // MARK: - Static Properties

    public static let shared = AppLovinEventTracker()

    // MARK: - Events

    private enum Event {
        static let rewardedAdOpportunity = "rewarded_ad_opportunity"
        static let virtualResourceTransaction = "virtual_resource_transaction"
        static let tutorialComplete = "tutorial_complete"
        static let gameShopEnter = "game_shop_enter"
        static let login = "login"
        static let signUp = "sign_up"
        static let appOpen = "app_open"
    }

    private enum ParameterKey {
        static let value = "value"
        static let resourceType = "resource_type"
    }

    /// В приложениях одна виртуальная (не настоящая) валюта — игровой баланс.
    private static let resourceType = "COINS"

    /// Сколько событий держим в очереди, пока не готов SDK. Столько на старте
    /// не набирается никогда — это защита от утечки, если инициализация упала.
    private static let pendingEventsLimit = 32

    /// Сколько всего ждём, пока приложение узнает значение флага (у приложений это
    /// активация Remote Config — пара секунд, запас взят на медленную сеть).
    private static let configurationWaitLimit: TimeInterval = 15
    /// Шаг перепроверки внутри этого ожидания.
    private static let configurationRetryStep: TimeInterval = 0.5

    // MARK: - Properties

    private let queue = DispatchQueue(label: "com.dbahq.analyticskit.applovin.event-tracker")
    private var isSDKReady = false
    private var pendingEvents: [(name: String, parameters: [String: String]?)] = []

    // MARK: - Lifecycle

    private init() {}

    // MARK: - SDK Readiness

    /// Вызывается из рекламной инициализации в колбэке готовности `ALSdk`.
    public func sdkDidInitialize() {
        queue.async { [weak self] in
            guard let self = self, !self.isSDKReady else { return }
            self.isSDKReady = true

            let events = self.pendingEvents
            self.pendingEvents = []
            events.forEach { self.send(name: $0.name, parameters: $0.parameters) }
        }
    }

    // MARK: - Public Methods

    /// Пользователю показана возможность посмотреть ревордед-рекламу.
    public func trackRewardedAdOpportunity() {
        track(Event.rewardedAdOpportunity)
    }

    /// Трата или начисление виртуальной валюты.
    /// - Parameter value: сумма операции; списание передаётся отрицательным.
    public func trackVirtualResourceTransaction(value: Decimal) {
        track(Event.virtualResourceTransaction,
              parameters: [ParameterKey.value: Self.string(from: value),
                           ParameterKey.resourceType: Self.resourceType])
    }

    /// Покупка товара в магазине — списание виртуальной валюты.
    public func trackShopPurchase(price: Decimal) {
        trackVirtualResourceTransaction(value: -abs(price))
    }

    /// Завершение онбординга.
    public func trackTutorialComplete() {
        track(Event.tutorialComplete)
    }

    /// Открытие магазина.
    public func trackGameShopEnter() {
        track(Event.gameShopEnter)
    }

    /// Успешный вход в существующий аккаунт по e-mail.
    public func trackLogin() {
        track(Event.login)
    }

    /// Успешная авторизация через Apple ID (и регистрация, и повторный вход —
    /// бэкенд их не различает), а также регистрация по e-mail.
    public func trackSignUp() {
        track(Event.signUp)
    }

    /// Запуск приложения / возврат из фона.
    public func trackAppOpen() {
        track(Event.appOpen)
    }

    // MARK: - Private Methods

    private func track(_ name: String, parameters: [String: String]? = nil) {
        queue.async { [weak self] in
            guard let self = self else { return }

            guard self.isSDKReady else {
                guard self.pendingEvents.count < Self.pendingEventsLimit else { return }
                self.pendingEvents.append((name, parameters))
                return
            }

            self.send(name: name, parameters: parameters)
        }
    }

    /// Гейт стоит именно здесь — это единственная точка, через которую уходят
    /// и мгновенные события, и накопленные до подъёма SDK.
    ///
    /// Отдельный случай — флаг ещё не известен (`nil`). Рекламный SDK поднимается
    /// раньше, чем активируется Remote Config, и очередь сливалась в это окно: при
    /// выключенном флаге всё равно уходили первые события каждой установки
    /// (`app_open`, `rewarded_ad_opportunity`). Теперь ждём и перепроверяем.
    private func send(name: String, parameters: [String: String]?, waitedFor: TimeInterval = 0) {
        DispatchQueue.main.async { [weak self] in
            switch AnalyticsKit.configuration.isAppLovinEventTrackingEnabled() {
            case .some(false):
                AnalyticsKitLog.log("событие AppLovin '\(name)' не отправлено — трекинг выключен")

            case .some(true):
                ALSdk.shared().eventService.trackEvent(name, parameters: parameters ?? [:])

            case .none where waitedFor < Self.configurationWaitLimit:
                DispatchQueue.main.asyncAfter(deadline: .now() + Self.configurationRetryStep) {
                    self?.send(name: name,
                               parameters: parameters,
                               waitedFor: waitedFor + Self.configurationRetryStep)
                }

            case .none:
                // Значение так и не приехало: нет сети или ключа нет вовсе. Ведём себя
                // как раньше — молча терять аналитику хуже, чем отправить.
                AnalyticsKitLog.log("событие AppLovin '\(name)': значение флага не приехало за \(Int(Self.configurationWaitLimit)) с, отправляю")
                ALSdk.shared().eventService.trackEvent(name, parameters: parameters ?? [:])
            }
        }
    }

    /// Локаленезависимое представление суммы: разделитель всегда `.`.
    private static func string(from value: Decimal) -> String {
        return NSDecimalNumber(decimal: value).stringValue
    }
}
