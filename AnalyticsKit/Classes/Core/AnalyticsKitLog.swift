//
//  AnalyticsKitLog.swift
//  AnalyticsKit
//
//  Логи включаются флагом в конфигурации, а не Remote Config — как в AdKit.
//

import Foundation
import os

enum AnalyticsKitLog {

    private static let logger = Logger(subsystem: "AnalyticsKit", category: "analytics")

    static func log(_ message: String) {
        guard AnalyticsKit.isConfigured, AnalyticsKit.configuration.isLoggingEnabled else { return }
        logger.notice("[AnalyticsKit] \(message, privacy: .public)")
    }
}
