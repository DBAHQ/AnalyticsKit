//
//  AnalyticsKitLog.swift
//  AnalyticsKit
//
//  Логи включаются флагом в конфигурации, а не Remote Config — как в AdKit.
//  Смотреть в Console.app по фильтру [AnalyticsKit].
//

import Foundation
import os

enum AnalyticsKitLog {

    private static let logger = Logger(subsystem: "AnalyticsKit", category: "analytics")

    private static var isEnabled: Bool {
        AnalyticsKit.isConfigured && AnalyticsKit.configuration.isLoggingEnabled
    }

    static func log(_ message: String) {
        guard isEnabled else { return }
        logger.notice("[AnalyticsKit] \(message, privacy: .public)")
    }

    /// Событие ушло в фанаут. Параметры печатаем отсортированными, чтобы
    /// строку можно было механически сверять между запусками.
    static func event(_ name: String, _ parameters: [String: Any] = [:]) {
        guard isEnabled else { return }
        let rendered = parameters.isEmpty
            ? ""
            : " " + parameters.keys.sorted().map { "\($0)=\(parameters[$0] ?? "nil")" }.joined(separator: " ")
        logger.notice("[AnalyticsKit] → \(name, privacy: .public)\(rendered, privacy: .public)")
    }
}
