//
//  AnalyticsKit.swift
//  AnalyticsKit
//

import Foundation

public enum AnalyticsKit {

    private static var _configuration: AnalyticsConfiguration?

    /// Конфигурация пакета. Обращение до `configure` — ошибка программиста,
    /// а не повод молча проглотить события.
    public static var configuration: AnalyticsConfiguration {
        guard let _configuration else {
            preconditionFailure("AnalyticsKit.configure(_:) не вызван до обращения к аналитике")
        }
        return _configuration
    }

    public static var isConfigured: Bool { _configuration != nil }

    public static func configure(_ configuration: AnalyticsConfiguration) {
        _configuration = configuration
    }
}
