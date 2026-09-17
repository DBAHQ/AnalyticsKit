//
//  AnalyticsConfiguration.swift
//  AnalyticsKit
//
//  Всё прикладное, что пакету нужно от приложения. Значения, которые могут
//  меняться по ходу жизни приложения (userID, язык, пуш-токен), приходят
//  замыканиями, а не копиями.
//

import Foundation

public struct AnalyticsConfiguration {

    // MARK: - Среда

    /// Продакшен или дев-контур: выбирает песочницу Adjust и plist Firebase.
    public let isProduction: Bool

    // MARK: - Ключи

    /// Имя plist-файла Firebase без расширения.
    public let firebasePlistName: String
    public let appMetricaKey: String
    public let adjustAppToken: String

    /// Токены событий Adjust. Событие, которого нет в карте, не отправляется.
    public let adjustEventTokens: [AdjustEvent: String]

    // MARK: - Живые значения

    public let userID: () -> String
    public let language: () -> String?

    /// Первый запуск: по нему один раз отправляется `applicationDidInstall`.
    public let isFirstLaunch: () -> Bool

    /// Гейт пользовательских событий AppLovin (у приложений — флаг Remote Config).
    public let isAppLovinEventTrackingEnabled: () -> Bool

    /// Логи пакета в `os_log`. Как в AdKit — флагом, а не Remote Config.
    public let isLoggingEnabled: Bool

    // MARK: - Доход с рекламы

    public let adRevenue: AdRevenueConfiguration?

    public init(isProduction: Bool,
                firebasePlistName: String,
                appMetricaKey: String,
                adjustAppToken: String,
                adjustEventTokens: [AdjustEvent: String],
                userID: @escaping () -> String,
                language: @escaping () -> String?,
                isFirstLaunch: @escaping () -> Bool,
                isAppLovinEventTrackingEnabled: @escaping () -> Bool,
                isLoggingEnabled: Bool = false,
                adRevenue: AdRevenueConfiguration? = nil) {
        self.isProduction = isProduction
        self.firebasePlistName = firebasePlistName
        self.appMetricaKey = appMetricaKey
        self.adjustAppToken = adjustAppToken
        self.adjustEventTokens = adjustEventTokens
        self.userID = userID
        self.language = language
        self.isFirstLaunch = isFirstLaunch
        self.isAppLovinEventTrackingEnabled = isAppLovinEventTrackingEnabled
        self.isLoggingEnabled = isLoggingEnabled
        self.adRevenue = adRevenue
    }
}

public struct AdRevenueConfiguration {

    /// Слаг приложения на бекенде: tradingguru, gotrading, gocrypto, …
    public let appSlug: String
    public let apiKey: String

    /// Базовый URL со слешем на конце.
    public let host: String

    /// Kill-switch: у приложений это флаг Remote Config, по умолчанию выключен.
    public let isEnabled: () -> Bool

    public init(appSlug: String, apiKey: String, host: String, isEnabled: @escaping () -> Bool) {
        self.appSlug = appSlug
        self.apiKey = apiKey
        self.host = host
        self.isEnabled = isEnabled
    }
}
