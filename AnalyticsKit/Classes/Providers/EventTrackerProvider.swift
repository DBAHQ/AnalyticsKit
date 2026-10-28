//
//  EventTrackerProvider.swift
//  AnalyticsKit
//
//  Свой трекер событий — перенос старого EventTracker приложений на общий
//  сервис аналитики (analytics.ironsum.com / analytics.digitalbrainapps.com).
//
//  Механика та же, что была: две очереди (события и доход), батчи по размеру
//  и таймеру, 5 повторов через секунду, офлайн-персист в Documents, дедуп
//  одинаковых событий в окне 1 с, distinctId — локальный UUID под XOR.
//  Каталог событий — имена и параметры старого трекера.
//
//  Отличия, которых требует новый сервис:
//  • заголовки `X-API-Key`, `application`, `os`, `platform`;
//  • 400/401/403/404/422 — батч выбрасывается (повтор не поможет, а очередь
//    иначе клинит навсегда); 5xx и сеть — повторы, как раньше;
//  • вложенные объекты в `properties` сервис отвергает — разворачиваем их
//    в плоские ключи `aps.alert.title`;
//  • пока флаг неизвестен (Remote Config не приехал), события копятся,
//    а не теряются; таймаут 20 с (сервер не распознаёт повторную отправку).
//

import Foundation
import Network
import UIKit

public final class EventTrackerProvider: AnalyticsProvider {

    // MARK: - Constants

    private enum Constants {
        static let eventFlushInterval: TimeInterval = 15.0
        static let revenueFlushInterval: TimeInterval = 5.0
        static let distinctIdKey = "EventTrackerDistinctID"
        static let distinctIdSecret = "EventTrackerSecretKey"
        static let maximumRetryCount = 5
        static let retryDelay: TimeInterval = 1.0
        static let maxEventBatchSize = 20
        static let maxRevenueBatchSize = 10
        /// Предохранитель: если флаг так и не приехал, очередь не растёт бесконечно.
        static let maxQueueSize = 2000
        static let requestTimeout: TimeInterval = 20.0
        static let duplicateWindowMs = 1000
    }

    private enum Stream: CaseIterable {
        case events, revenues

        var path: String {
            switch self {
            case .events:   return "v1/event/track"
            case .revenues: return "v1/revenue/track"
            }
        }

        var payloadKey: String {
            switch self {
            case .events:   return "events"
            case .revenues: return "revenues"
            }
        }

        var batchSize: Int {
            switch self {
            case .events:   return Constants.maxEventBatchSize
            case .revenues: return Constants.maxRevenueBatchSize
            }
        }

        var offlineFile: String {
            switch self {
            case .events:   return "offlineEvents.json"
            case .revenues: return "offlineRevenues.json"
            }
        }

        /// Файл, который старый трекер писал при выгрузке приложения.
        var terminationFile: String {
            switch self {
            case .events:   return "terminationEvents.json"
            case .revenues: return "terminationRevenues.json"
            }
        }
    }

    // MARK: - Properties

    public var userID: String { settings?.userID() ?? "" }

    private var settings: EventTrackerConfiguration? {
        AnalyticsKit.isConfigured ? AnalyticsKit.configuration.eventTracker : nil
    }

    /// Всё состояние ниже меняется только на этой очереди.
    private let queue = DispatchQueue(label: "com.dbahq.analyticskit.eventTracker", qos: .utility)
    private var queues: [Stream: [[String: Any]]] = [.events: [], .revenues: []]
    private var sending = Set<Stream>()
    private var recentEvents: [(name: String, timestamp: Int, placement: String?, type: String?)] = []
    private var isNetworkAvailable = true
    private var isStarted = false
    private var lastLoggedFlag: Bool??

    private var eventTimer: Timer?
    private var revenueTimer: Timer?
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "com.dbahq.analyticskit.eventTracker.network")

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Constants.requestTimeout
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: configuration)
    }()

    public init() {}

    // MARK: - Lifecycle

    public func start() {
        guard settings != nil else { return }
        var alreadyStarted = false
        queue.sync {
            alreadyStarted = isStarted
            isStarted = true
        }
        guard !alreadyStarted else { return }

        queue.async { [weak self] in
            guard let self else { return }
            _ = self.distinctIdLocked()
            Stream.allCases.forEach { self.loadOfflineLocked($0) }
        }
        startNetworkMonitoring()
        DispatchQueue.main.async { [weak self] in
            self?.registerAppStateNotifications()
            self?.startTimers()
        }
        AnalyticsKitLog.log("EventTracker поднят: \(settings?.host ?? "")")
    }

    // MARK: - App State

    private func registerAppStateNotifications() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(applicationWillResignActive),
                           name: UIApplication.willResignActiveNotification, object: nil)
        center.addObserver(self, selector: #selector(applicationDidBecomeActive),
                           name: UIApplication.didBecomeActiveNotification, object: nil)
        center.addObserver(self, selector: #selector(applicationDidEnterBackground),
                           name: UIApplication.didEnterBackgroundNotification, object: nil)
        center.addObserver(self, selector: #selector(applicationWillTerminate),
                           name: UIApplication.willTerminateNotification, object: nil)
    }

    @objc private func applicationWillResignActive() {
        eventTimer?.invalidate()
        revenueTimer?.invalidate()
    }

    @objc private func applicationDidBecomeActive() {
        startTimers()
        flushAll()
    }

    @objc private func applicationDidEnterBackground() {
        queue.async { [weak self] in
            guard let self else { return }
            Stream.allCases.forEach {
                self.flushLocked($0)
                self.persistLocked($0)
            }
        }
    }

    @objc private func applicationWillTerminate() {
        queue.sync { Stream.allCases.forEach { persistLocked($0) } }
    }

    // MARK: - Network

    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let isAvailable = path.status == .satisfied
            self.queue.async {
                let wasAvailable = self.isNetworkAvailable
                self.isNetworkAvailable = isAvailable
                if !wasAvailable && isAvailable {
                    Stream.allCases.forEach { self.flushLocked($0) }
                }
            }
        }
        networkMonitor.start(queue: networkQueue)
    }

    // MARK: - Timers

    private func startTimers() {
        eventTimer?.invalidate()
        revenueTimer?.invalidate()

        let eventTimer = Timer(timeInterval: Constants.eventFlushInterval, target: self,
                               selector: #selector(flushEventsFromTimer), userInfo: nil, repeats: true)
        let revenueTimer = Timer(timeInterval: Constants.revenueFlushInterval, target: self,
                                 selector: #selector(flushRevenuesFromTimer), userInfo: nil, repeats: true)
        RunLoop.main.add(eventTimer, forMode: .common)
        RunLoop.main.add(revenueTimer, forMode: .common)
        self.eventTimer = eventTimer
        self.revenueTimer = revenueTimer
    }

    @objc private func flushEventsFromTimer() {
        queue.async { [weak self] in self?.flushLocked(.events) }
    }

    @objc private func flushRevenuesFromTimer() {
        queue.async { [weak self] in self?.flushLocked(.revenues) }
    }

    private func flushAll() {
        queue.async { [weak self] in
            guard let self else { return }
            Stream.allCases.forEach { self.flushLocked($0) }
        }
    }

    // MARK: - Enqueue

    private func trackEvent(name: String, properties: [String: Any]? = nil) {
        guard let settings, settings.isEnabled() != false else { return }

        let timestamp = Self.nowMs
        let placement = properties?["placement"] as? String
        let type = properties?["type"] as? String
        let flatProperties = Self.flatten(properties ?? [:])

        queue.async { [weak self] in
            guard let self else { return }

            // Дедуп как в старом трекере: одно и то же событие чаще раза в секунду —
            // повтор; у рекламных событий сравниваем ещё placement и type.
            self.recentEvents.removeAll { timestamp - $0.timestamp >= 5000 }
            let isDuplicate = self.recentEvents.contains {
                guard $0.name == name, abs(timestamp - $0.timestamp) < Constants.duplicateWindowMs else { return false }
                return name.hasPrefix("ad") ? ($0.placement == placement && $0.type == type) : true
            }
            guard !isDuplicate else { return }
            self.recentEvents.append((name: name, timestamp: timestamp, placement: placement, type: type))

            self.appendLocked(.events, [
                "eventId": "\(timestamp)_\(UUID().uuidString)",
                "timestamp": timestamp,
                "event": name,
                "properties": flatProperties
            ])
        }
    }

    private func trackRevenue(amount: Decimal, currency: String = "USD", source: String,
                              properties: [String: Any]? = nil) {
        guard let settings, settings.isEnabled() != false else { return }
        guard !amount.isNaN else { return }

        let revenue: [String: Any] = [
            "eventId": UUID().uuidString,
            "timestamp": Self.nowMs,
            "amount": NSDecimalNumber(decimal: amount),
            "currency": currency,
            "source": source,
            "properties": Self.flatten(properties ?? [:])
        ]
        queue.async { [weak self] in self?.appendLocked(.revenues, revenue) }
    }

    // MARK: - Queue (вызывать только на `queue`)

    private func appendLocked(_ stream: Stream, _ item: [String: Any]) {
        var items = queues[stream] ?? []
        items.append(item)
        if items.count > Constants.maxQueueSize {
            items.removeFirst(items.count - Constants.maxQueueSize)
        }
        queues[stream] = items
        if items.count >= stream.batchSize {
            flushLocked(stream)
        }
    }

    private func flushLocked(_ stream: Stream) {
        guard let settings, !sending.contains(stream), !(queues[stream] ?? []).isEmpty else { return }

        let isEnabled = settings.isEnabled()
        if isEnabled != lastLoggedFlag {
            lastLoggedFlag = isEnabled
            AnalyticsKitLog.log("EventTracker флаг: \(isEnabled.map { $0 ? "включён" : "выключен" } ?? "ждём Remote Config")")
        }
        switch isEnabled {
        case nil:
            return  // Remote Config ещё не приехал — придерживаем
        case false?:
            queues[stream] = []
            removeFile(stream.offlineFile)
            return
        case true?:
            break
        }

        guard isNetworkAvailable else {
            persistLocked(stream)
            return
        }

        var items = queues[stream] ?? []
        let count = min(items.count, stream.batchSize)
        let batch = Array(items.prefix(count))
        items.removeFirst(count)
        queues[stream] = items
        sending.insert(stream)

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        let payload: [String: Any] = [
            "distinctId": distinctIdLocked(),
            "userId": settings.userID(),
            "platform": "ios",
            "appVersion": "\(version) (\(build))",
            stream.payloadKey: batch,
            "batchTimestamp": Self.nowMs,
            "country": Locale.current.regionCode ?? ""
        ]
        send(stream, payload: payload, batch: batch, settings: settings, retryCount: 0)
    }

    private func send(_ stream: Stream, payload: [String: Any], batch: [[String: Any]],
                      settings: EventTrackerConfiguration, retryCount: Int) {
        guard let url = URL(string: settings.host + stream.path),
              JSONSerialization.isValidJSONObject(payload),
              let body = try? JSONSerialization.data(withJSONObject: payload) else {
            // Сформировать запрос нельзя и повтор не поможет — не клиним очередь.
            AnalyticsKitLog.log("EventTracker ✗ \(stream.path): батч не сериализуется, выброшен")
            sending.remove(stream)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(settings.apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(settings.appSlug, forHTTPHeaderField: "application")
        request.setValue("IOS", forHTTPHeaderField: "os")
        request.setValue("ios", forHTTPHeaderField: "platform")
        request.httpBody = body

        let names = batch.map { ($0["event"] ?? $0["source"]).map { "\($0)" } ?? "?" }
        AnalyticsKitLog.log("EventTracker → POST \(stream.path) [\(batch.count)] \(names.joined(separator: ", "))")
        // os_log режет длинные строки — тело печатаем кусками.
        let text = String(data: body, encoding: .utf8) ?? ""
        stride(from: 0, to: text.count, by: 800).forEach { offset in
            let start = text.index(text.startIndex, offsetBy: offset)
            let end = text.index(start, offsetBy: 800, limitedBy: text.endIndex) ?? text.endIndex
            AnalyticsKitLog.log("EventTracker   body[\(offset / 800)] \(text[start..<end])")
        }

        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let reply = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            AnalyticsKitLog.log("EventTracker ← \(stream.path) \(status) \(error?.localizedDescription ?? reply)")

            self.queue.async {
                if error == nil, (200...299).contains(status) {
                    self.sending.remove(stream)
                    self.persistLocked(stream)
                    self.flushLocked(stream)
                } else if (400...499).contains(status) {
                    // Ошибка в самом запросе — повтор не поможет.
                    self.sending.remove(stream)
                    self.flushLocked(stream)
                } else if retryCount < Constants.maximumRetryCount {
                    self.queue.asyncAfter(deadline: .now() + Constants.retryDelay) {
                        self.send(stream, payload: payload, batch: batch, settings: settings,
                                  retryCount: retryCount + 1)
                    }
                } else {
                    self.queues[stream]?.insert(contentsOf: batch, at: 0)
                    self.sending.remove(stream)
                    self.persistLocked(stream)
                }
            }
        }.resume()
    }

    // MARK: - Offline Storage (вызывать только на `queue`)

    private func fileURL(_ name: String) -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(name)
    }

    private func removeFile(_ name: String) {
        guard let url = fileURL(name) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Снимок очереди на диск. Пустая очередь — файл удаляется, чтобы
    /// уже отправленное не поднялось заново при следующем запуске.
    private func persistLocked(_ stream: Stream) {
        let items = queues[stream] ?? []
        guard !items.isEmpty else {
            removeFile(stream.offlineFile)
            return
        }
        guard let url = fileURL(stream.offlineFile),
              let data = try? JSONSerialization.data(withJSONObject: items) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func loadOfflineLocked(_ stream: Stream) {
        var known = Set((queues[stream] ?? []).compactMap { $0["eventId"] as? String })
        for name in [stream.offlineFile, stream.terminationFile] {
            guard let url = fileURL(name),
                  let data = try? Data(contentsOf: url),
                  let items = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { continue }
            for item in items {
                guard let id = item["eventId"] as? String, !known.contains(id) else { continue }
                known.insert(id)
                queues[stream, default: []].append(item)
            }
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Distinct ID (вызывать только на `queue`)

    private func distinctIdLocked() -> String {
        if let stored = readDistinctId() { return stored }
        let newId = UUID().uuidString
        writeDistinctId(newId)
        return newId
    }

    private func readDistinctId() -> String? {
        guard let encrypted = UserDefaults.standard.data(forKey: Constants.distinctIdKey),
              !encrypted.isEmpty else { return nil }
        let key = Data(Constants.distinctIdSecret.utf8)
        let decrypted = Data(encrypted.enumerated().map { $0.element ^ key[$0.offset % key.count] })
        guard let result = String(data: decrypted, encoding: .utf8), !result.isEmpty else { return nil }
        return result
    }

    private func writeDistinctId(_ id: String) {
        let data = Data(id.utf8)
        let key = Data(Constants.distinctIdSecret.utf8)
        let encrypted = Data(data.enumerated().map { $0.element ^ key[$0.offset % key.count] })
        UserDefaults.standard.set(encrypted, forKey: Constants.distinctIdKey)
    }

    // MARK: - Helpers

    private static var nowMs: Int { Int(Date().timeIntervalSince1970 * 1000) }

    /// Сервис принимает в `properties` только плоские значения: вложенные
    /// словари разворачиваем в ключи через точку, остальное — в строку.
    static func flatten(_ properties: [String: Any], prefix: String = "") -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in properties {
            let fullKey = prefix.isEmpty ? key : "\(prefix).\(key)"
            switch value {
            case let nested as [String: Any]:
                result.merge(flatten(nested, prefix: fullKey)) { $1 }
            case let nested as [AnyHashable: Any]:
                let stringKeyed = Dictionary(nested.map { ("\($0.key)", $0.value) }, uniquingKeysWith: { $1 })
                result.merge(flatten(stringKeyed, prefix: fullKey)) { $1 }
            case let string as String:
                result[fullKey] = string
            case let decimal as Decimal:
                result[fullKey] = "\(decimal)"
            case let double as Double where !double.isFinite:
                result[fullKey] = "\(double)"
            case let number as NSNumber:
                result[fullKey] = number
            default:
                result[fullKey] = "\(value)"
            }
        }
        return result
    }

    // MARK: - Session

    public func trackSessionStart(trigger: String, textNumber: String, code: String) {
        trackEvent(name: "sessionStart", properties: ["trigger": trigger, "textNumber": textNumber, "code": code])
    }

    public func trackSessionFinish(duration: Double) {
        trackEvent(name: "sessionFinish", properties: ["sessionLength": duration])
    }

    public func trackInstall() {
        trackEvent(name: "applicationDidInstall")
    }

    // MARK: - Onboarding

    public func onboardingBegin() {
        trackEvent(name: "onboardingBegin")
    }

    public func onboardingStepPresent(step: String) {
        trackEvent(name: "onboardingStepPresent", properties: ["step": step])
    }

    public func onboardingStepContinue(step: String) {
        trackEvent(name: "onboardingStepContinue", properties: ["step": step])
    }

    public func onboardingComplete() {
        trackEvent(name: "onboardingComplete")
    }

    // MARK: - Feature Tutorial

    public func featureTutorialBegin(flow: String) {
        trackEvent(name: "featureTutorialBegin", properties: ["flow": flow])
    }

    public func featureTutorialStepPresent(flow: String, step: String) {
        trackEvent(name: "featureTutorialStepPresent", properties: ["flow": flow, "step": step])
    }

    public func featureTutorialStepContinue(flow: String, step: String) {
        trackEvent(name: "featureTutorialStepContinue", properties: ["flow": flow, "step": step])
    }

    public func featureTutorialSkip(flow: String, step: String) {
        trackEvent(name: "featureTutorialSkip", properties: ["flow": flow, "step": step])
    }

    public func featureTutorialComplete(flow: String) {
        trackEvent(name: "featureTutorialComplete", properties: ["flow": flow])
    }

    // MARK: - Auth

    public func trackAuthDidPresent() {
        trackEvent(name: "authDidPresent")
    }

    public func trackAuthDidDismiss(timespent: Double) {
        trackEvent(name: "authDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackAuthSignIn() {
        trackEvent(name: "authSignIn")
    }

    public func trackAuthSignUpBegin() {
        trackEvent(name: "authSignUpBegin")
    }

    public func trackAuthSignUpComplete() {
        trackEvent(name: "authSignUpComplete")
    }

    public func trackAuthOAuthBegin(_ type: String) {
        trackEvent(name: "authOauthBegin", properties: ["type": type])
    }

    public func trackAuthOAuthComplete(_ type: String) {
        trackEvent(name: "authOauthComplete", properties: ["type": type])
    }

    // MARK: - Profile

    public func trackProfileDidPresent() {
        trackEvent(name: "profileDidPresent")
    }

    public func trackProfileDidDismiss(timespent: Double) {
        trackEvent(name: "profileDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackProfileDidTapAvatar() {
        trackEvent(name: "profileDidTapAvatar")
    }

    public func trackProfileDidTapAvatarEdit() {
        trackEvent(name: "profileDidTapAvatarEdit")
    }

    public func trackAvatarDidPresent() {
        trackEvent(name: "avatarDidPresent")
    }

    public func trackAvatarDidDismiss(timespent: Double) {
        trackEvent(name: "avatarDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackAvatarDidTapChange() {
        trackEvent(name: "avatarDidTapChange")
    }

    public func trackUserProfileOtherDidPresent() {
        trackEvent(name: "userProfileOtherDidPresent")
    }

    public func trackUserProfileOtherDidDismiss(timespent: Double) {
        trackEvent(name: "userProfileOtherDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackOtherUserDidLike() {
        trackEvent(name: "otherUserDidLike")
    }

    public func trackOtherUserDidUnlike() {
        trackEvent(name: "otherUserDidUnlike")
    }

    public func trackOtherUserLikesDidPresent() {
        trackEvent(name: "otherUserLikesDidPresent")
    }

    public func trackOtherUserLikesDidDismiss(timespent: Double) {
        trackEvent(name: "otherUserLikesDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackOtherUserLikesDidTap() {
        trackEvent(name: "otherUserLikesDidTap")
    }

    public func trackUserLikesDidPresent() {
        trackEvent(name: "userLikesDidPresent")
    }

    public func trackUserLikesDidDismiss(timespent: Double) {
        trackEvent(name: "userLikesDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackUserLikesDidTap() {
        trackEvent(name: "userLikesDidTap")
    }

    // MARK: - Dashboard

    public func trackDashboardDidPresent() {
        trackEvent(name: "dashboardDidPresent")
    }

    public func trackDashboardDidDismiss(timespent: Double) {
        trackEvent(name: "dashboardDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackDashboardDidTapSettings() {
        trackEvent(name: "dashboardDidTapSettings")
    }

    public func trackDashboardDidTapSignUp() {
        trackEvent(name: "dashboardDidTapSignUp")
    }

    public func trackDashboardDidTapProfile() {
        trackEvent(name: "dashboardDidTapProfile")
    }

    public func trackDashboardDidTapNotifications() {
        trackEvent(name: "dashboardDidTapNotifications")
    }

    public func trackDashboardDidTapBalance() {
        trackEvent(name: "dashboardDidTapBalance")
    }

    public func trackDashboardDidTapBonusAd() {
        trackEvent(name: "dashboardDidTapBonusAd")
    }

    public func trackDashboardDidTapDailyRewards() {
        trackEvent(name: "dashboardDidTapDailyRewards")
    }

    public func trackDashboardDidTapLuckySpin() {
        trackEvent(name: "dashboardDidTapLuckySpin")
    }

    public func trackDashboardDidTapChallenges() {
        trackEvent(name: "dashboardDidTapChallenges")
    }

    public func trackDashboardDidTapDemoAccount() {
        trackEvent(name: "dashboardDidTapDemoAccount")
    }

    public func trackDashboardDidTapShop() {
        trackEvent(name: "dashboardDidTapShop")
    }

    public func trackDashboardDidTapPremium() {
        trackEvent(name: "dashboardDidTapPremium")
    }

    public func trackDashboardDidTapAuction() {
        trackEvent(name: "dashboardDidTapAuction")
    }

    public func trackDashboardDidTapAppearance() {
        trackEvent(name: "dashboardDidTapAppearance")
    }

    public func trackDashboardDidTapStaking() {
        trackEvent(name: "dashboardDidTapStaking")
    }

    public func trackDashboardDidTapSlots() {
        trackEvent(name: "dashboardDidTapSlots")
    }

    public func trackDashboardDidTapStartup() {
        trackEvent(name: "dashboardDidTapStartup")
    }

    // MARK: - Staking

    public func trackStakingPoolsDidPresent() {
        trackEvent(name: "stakingPoolsDidPresent")
    }

    public func trackStakingPoolsDidDismiss(timespent: Double) {
        trackEvent(name: "stakingPoolsDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackStakingPoolsDidTapInvest(coin: String, invested: Decimal, size: Decimal, roi: Decimal, duration: Int) {
        trackEvent(name: "stakingPoolsDidTapInvest", properties: [
            "coin": coin,
            "invested": "\(invested)",
            "size": "\(size)",
            "roi": "\(roi)",
            "duration": duration
        ])
    }

    public func trackStakingPortfolioDidPresent() {
        trackEvent(name: "stakingPortfolioDidPresent")
    }

    public func trackStakingPortfolioDidDismiss(timespent: Double) {
        trackEvent(name: "stakingPortfolioDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackStakingPortfolioDidTapCollect(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        trackEvent(name: "stakingPortfolioDidTapCollect", properties: Self.staking(coin, roi, amount, duration))
    }

    public func trackStakingPortfolioDidTapRepair(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        trackEvent(name: "stakingPortfolioDidTapRepair", properties: Self.staking(coin, roi, amount, duration))
    }

    public func trackStakingRatingDidPresent() {
        trackEvent(name: "stakingRatingDidPresent")
    }

    public func trackStakingRatingDidDismiss(timespent: Double) {
        trackEvent(name: "stakingRatingDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackStakingRatingDidTapUser(position: Int) {
        trackEvent(name: "stakingRatingDidTapUser", properties: ["position": position])
    }

    public func trackStakingInvestAmountDidPresent() {
        trackEvent(name: "stakingInvestAmountDidPresent")
    }

    public func trackStakingInvestAmountDidDismiss(timespent: Double) {
        trackEvent(name: "stakingInvestAmountDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackStakingInvestAmountDidTapInvest(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        trackEvent(name: "stakingInvestAmountDidTapInvest", properties: Self.staking(coin, roi, amount, duration))
    }

    public func trackStakingInvestAmountDidTapInvestWithProtection(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        trackEvent(name: "stakingInvestAmountDidTapInvestWithProtection", properties: Self.staking(coin, roi, amount, duration))
    }

    public func trackStakingPoolHackedDidPresent() {
        trackEvent(name: "stakingPoolHackedDidPresent")
    }

    public func trackStakingPoolHackedDidDismiss(timespent: Double) {
        trackEvent(name: "stakingPoolHackedDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackStakingPoolHackedDidTapProtection(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        trackEvent(name: "stakingPoolHackedDidTapProtection", properties: Self.staking(coin, roi, amount, duration))
    }

    public func trackStakingPoolHackedDidTapLossMoney(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        trackEvent(name: "stakingPoolHackedDidTapLossMoney", properties: Self.staking(coin, roi, amount, duration))
    }

    public func trackStakingProfitMultiplyDidPresent() {
        trackEvent(name: "stakingProfitMultiplyDidPresent")
    }

    public func trackStakingProfitMultiplyDidDismiss(timespent: Double) {
        trackEvent(name: "stakingProfitMultiplyDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackStakingProfitMultiplyDidTapMultiply(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        trackEvent(name: "stakingProfitMultiplyDidTapMultiply", properties: Self.staking(coin, roi, amount, duration))
    }

    public func trackStakingProfitMultiplyDidTapNotNow(coin: String, roi: Decimal, amount: Decimal, duration: Int) {
        trackEvent(name: "stakingProfitMultiplyDidTapNotNow", properties: Self.staking(coin, roi, amount, duration))
    }

    private static func staking(_ coin: String, _ roi: Decimal, _ amount: Decimal, _ duration: Int) -> [String: Any] {
        ["coin": coin, "roi": "\(roi)", "amount": "\(amount)", "duration": duration]
    }

    // MARK: - Trading

    public func trackTradingPortfolioDidPresent(isTournament: Bool) {
        trackEvent(name: "tradingPortfolioDidPresent", properties: ["isTournament": isTournament])
    }

    public func trackTradingPortfolioDidDismiss(isTournament: Bool, timespent: Double) {
        trackEvent(name: "tradingPortfolioDidDismiss", properties: ["isTournament": isTournament, "timespentSec": timespent])
    }

    public func trackTradingPortfolioDidTap(isTournament: Bool, symbol: String) {
        trackEvent(name: "tradingPortfolioDidTap", properties: ["isTournament": isTournament, "symbol": symbol])
    }

    public func trackTradingMarketDidPresent(isTournament: Bool) {
        trackEvent(name: "tradingMarketDidPresent", properties: ["isTournament": isTournament])
    }

    public func trackTradingMarketDidDismiss(isTournament: Bool, timespent: Double) {
        trackEvent(name: "tradingMarketDidDismiss", properties: ["isTournament": isTournament, "timespentSec": timespent])
    }

    public func trackTradingMarketDidTap(isTournament: Bool, symbol: String) {
        trackEvent(name: "tradingMarketDidTap", properties: ["isTournament": isTournament, "symbol": symbol])
    }

    public func trackTradingTradesDidPresent(isTournament: Bool) {
        trackEvent(name: "tradingTradesDidPresent", properties: ["isTournament": isTournament])
    }

    public func trackTradingTradesDidDismiss(isTournament: Bool, timespent: Double) {
        trackEvent(name: "tradingTradesDidDismiss", properties: ["isTournament": isTournament, "timespentSec": timespent])
    }

    public func trackTradingTradesDidTap(isTournament: Bool, symbol: String) {
        trackEvent(name: "tradingTradesDidTap", properties: ["isTournament": isTournament, "symbol": symbol])
    }

    public func trackTradingOrdersDidPresent(isTournament: Bool) {
        trackEvent(name: "tradingOrdersDidPresent", properties: ["isTournament": isTournament])
    }

    public func trackTradingOrdersDidDismiss(isTournament: Bool, timespent: Double) {
        trackEvent(name: "tradingOrdersDidDismiss", properties: ["isTournament": isTournament, "timespentSec": timespent])
    }

    public func trackTradingOrdersDidTap(isTournament: Bool, symbol: String, type: String) {
        trackEvent(name: "tradingOrdersDidTap", properties: ["isTournament": isTournament, "symbol": symbol, "type": type])
    }

    public func trackTradingDidTrade(isTournament: Bool, symbol: String, direction: String, stake: Decimal) {
        trackEvent(name: "tradingDidTrade", properties: [
            "isTournament": isTournament,
            "symbol": symbol,
            "direction": direction,
            "stake": "\(stake)"
        ])
    }

    // MARK: - Asset Trading

    public func trackAssetTradingDidPresent(isTournament: Bool, symbol: String) {
        trackEvent(name: "assetTradingDidPresent", properties: ["isTournament": isTournament, "symbol": symbol])
    }

    public func trackAssetTradingDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        trackEvent(name: "assetTradingDidDismiss", properties: ["isTournament": isTournament, "symbol": symbol, "timespentSec": timespent])
    }

    public func trackAssetTradingDidTapProChart(isTournament: Bool, symbol: String) {
        trackEvent(name: "assetTradingDidTapProChart", properties: ["isTournament": isTournament, "symbol": symbol])
    }

    public func trackAssetTradingDidTapBonusAd(isTournament: Bool, symbol: String) {
        trackEvent(name: "assetTradingDidTapBonusAd", properties: ["isTournament": isTournament, "symbol": symbol])
    }

    public func trackAssetTradingDidTapBuy(isTournament: Bool, symbol: String) {
        trackEvent(name: "assetTradingDidTapBuy", properties: ["isTournament": isTournament, "symbol": symbol])
    }

    public func trackAssetTradingDidTapSell(isTournament: Bool, symbol: String) {
        trackEvent(name: "assetTradingDidTapSell", properties: ["isTournament": isTournament, "symbol": symbol])
    }

    public func trackAssetTradesDidPresent(isTournament: Bool, symbol: String) {
        trackEvent(name: "assetTradesDidPresent", properties: ["isTournament": isTournament, "symbol": symbol])
    }

    public func trackAssetTradesDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        trackEvent(name: "assetTradesDidDismiss", properties: ["isTournament": isTournament, "symbol": symbol, "timespentSec": timespent])
    }

    public func trackAssetTradesDidTap(isTournament: Bool, symbol: String) {
        trackEvent(name: "assetTradesDidTap", properties: ["isTournament": isTournament, "symbol": symbol])
    }

    public func trackAssetOrdersDidPresent(isTournament: Bool, symbol: String) {
        trackEvent(name: "assetOrdersDidPresent", properties: ["isTournament": isTournament, "symbol": symbol])
    }

    public func trackAssetOrdersDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        trackEvent(name: "assetOrdersDidDismiss", properties: ["isTournament": isTournament, "symbol": symbol, "timespentSec": timespent])
    }

    public func trackAssetOrdersDidTap(isTournament: Bool, symbol: String, type: String) {
        trackEvent(name: "assetOrdersDidTap", properties: ["isTournament": isTournament, "symbol": symbol, "type": type])
    }

    public func trackAssetTradeDetailDidPresent(isTournament: Bool, symbol: String) {
        trackEvent(name: "assetTradeDetailDidPresent", properties: ["isTournament": isTournament, "symbol": symbol])
    }

    public func trackAssetTradeDetailDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        trackEvent(name: "tradingTradeDetailDidDismiss", properties: ["isTournament": isTournament, "symbol": symbol, "timespentSec": timespent])
    }

    public func trackAssetOrderDetailDidPresent(isTournament: Bool, symbol: String) {
        trackEvent(name: "assetOrderDetailDidPresent", properties: ["isTournament": isTournament, "symbol": symbol])
    }

    public func trackAssetOrderDetailDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        trackEvent(name: "assetOrderDetailDidDismiss", properties: ["isTournament": isTournament, "symbol": symbol, "timespentSec": timespent])
    }

    // MARK: - New Order

    public func trackNewOrderDidPresent(isTournament: Bool, symbol: String) {
        trackEvent(name: "newOrderDidPresent", properties: ["isTournament": isTournament, "symbol": symbol])
    }

    public func trackNewOrderDidDismiss(isTournament: Bool, symbol: String, timespent: Double) {
        trackEvent(name: "newOrderDidDismiss", properties: ["isTournament": isTournament, "symbol": symbol, "timespentSec": timespent])
    }

    public func trackNewOrderDidSelectBuy(isTournament: Bool, symbol: String) {
        trackEvent(name: "newOrderDidSelectBuy", properties: ["isTournament": isTournament, "symbol": symbol])
    }

    public func trackNewOrderDidSelectSell(isTournament: Bool, symbol: String) {
        trackEvent(name: "newOrderDidSelectSell", properties: ["isTournament": isTournament, "symbol": symbol])
    }

    public func trackNewOrderDidSend(isTournament: Bool, symbol: String, amount: Decimal, takeProfit: Decimal, stopLoss: Decimal) {
        trackEvent(name: "newOrderDidSend", properties: [
            "isTournament": isTournament,
            "symbol": symbol,
            "amount": "\(amount)",
            "takeProfit": "\(takeProfit)",
            "stopLoss": "\(stopLoss)"
        ])
    }

    // MARK: - Auction

    public func trackAuctionDidPresent() {
        trackEvent(name: "auctionDidPresent")
    }

    public func trackAuctionDidDismiss(timespent: Double) {
        trackEvent(name: "auctionDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackAuctionDidPlaceBid(amount: Decimal) {
        trackEvent(name: "auctionDidPlaceBid", properties: ["amount": "\(amount)"])
    }

    // MARK: - Daily Rewards

    public func trackDailyRewardsDidPresent() {
        trackEvent(name: "dailyRewardsDidPresent")
    }

    public func trackDailyRewardsDidDismiss(timespent: Double) {
        trackEvent(name: "dailyRewardsDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackDailyRewardsDidReceiveReward(day: Int) {
        trackEvent(name: "dailyRewardsDidReceiveReward", properties: ["day": day])
    }

    public func trackDailyRewardsDidMultiplyReward(day: Int) {
        trackEvent(name: "dailyRewardsDidMultiplyReward", properties: ["day": day])
    }

    // MARK: - Lucky Spin

    public func trackLuckySpinDidPresent() {
        trackEvent(name: "luckySpinDidPresent")
    }

    public func trackLuckySpinDidDismiss(timespent: Double) {
        trackEvent(name: "luckySpinDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackLuckySpinDidSpin(spinCount: Int, totalSpinCount: Int) {
        trackEvent(name: "luckySpinDidSpin", properties: ["spinCount": spinCount, "totalSpinCount": totalSpinCount])
    }

    // MARK: - Slots

    public func trackSlotsDidPresent() {
        trackEvent(name: "slotsDidPresent")
    }

    public func trackSlotsDidDismiss(timespent: Double) {
        trackEvent(name: "slotsDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackSlotsDidSpin(slotsCount: Int, totalSlotsCount: Int) {
        trackEvent(name: "slotsDidSpin", properties: ["slotsCount": slotsCount, "totalSlotsCount": totalSlotsCount])
    }

    public func trackSlotsDidLoad(loadingTime: Double) {
        trackEvent(name: "slotsDidLoad", properties: ["loadingTime": loadingTime])
    }

    // MARK: - Shop

    public func trackShopDidPresent() {
        trackEvent(name: "shopDidPresent")
    }

    public func trackShopDidDismiss(timespent: Double) {
        trackEvent(name: "shopDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackShopItemDidPresent(id: String, price: Decimal) {
        trackEvent(name: "shopItemDidPresent", properties: ["id": id, "price": "\(price)"])
    }

    public func trackShopItemDidDismiss(id: String, price: Decimal, timespent: Double) {
        trackEvent(name: "shopItemDidDismiss", properties: ["id": id, "price": "\(price)", "timespentSec": timespent])
    }

    public func trackShopItemDidPurchase(id: String, price: Decimal) {
        trackEvent(name: "shopItemDidPurchase", properties: ["id": id, "price": "\(price)"])
        trackRevenue(amount: price, source: "shop", properties: ["itemId": id])
    }

    // MARK: - Rating & Tournament

    public func trackRatingDidPresent(isTournament: Bool) {
        trackEvent(name: "ratingDidPresent", properties: ["isTournament": isTournament])
    }

    public func trackRatingDidDismiss(isTournament: Bool, timespent: Double) {
        trackEvent(name: "ratingDidDismiss", properties: ["isTournament": isTournament, "timespentSec": timespent])
    }

    public func trackTournamentWelcomeDidPresent() {
        trackEvent(name: "tournamentWelcomeDidPresent")
    }

    public func trackTournamentWelcomeDidDismiss(timespent: Double) {
        trackEvent(name: "tournamentWelcomeDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackTournamentWelcomeSignUp() {
        trackEvent(name: "tournamentWelcomeSignUp")
    }

    public func trackTournamentDidPresent() {
        trackEvent(name: "tournamentDidPresent")
    }

    public func trackTournamentDidDismiss(timespent: Double) {
        trackEvent(name: "tournamentDidDismiss", properties: ["timespentSec": timespent])
    }

    // MARK: - Challenges

    public func trackChallengesDidPresent() {
        trackEvent(name: "challengesDidPresent")
    }

    public func trackChallengesDidDismiss(timespent: Double) {
        trackEvent(name: "challengesDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackChallengesAwardDidReceive(id: String, level: Int) {
        trackEvent(name: "challengesAwardDidReceive", properties: ["id": id, "level": level])
    }

    // MARK: - Feedback

    public func trackFeedbackBegin() {
        trackEvent(name: "feedbackBegin")
    }

    public func trackFeedbackRate() {
        trackEvent(name: "feedbackRate")
    }

    public func trackFeedbackComplete() {
        trackEvent(name: "feedbackComplete")
    }

    // MARK: - Ad

    public func trackFullAdDidRequest(in placement: String, type: String, displayCount: Int, fullScreenDisplayCount: Int, totalAdsDisplayCount: Int) {
        trackEvent(name: "adDidRequest", properties: ["placement": placement, "type": type, "displayCount": displayCount, "fullScreenDisplayCount": fullScreenDisplayCount, "totalAdsDisplayCount": totalAdsDisplayCount])
    }

    public func trackFullAdDidLoad(in placement: String, type: String, displayCount: Int, fullScreenDisplayCount: Int, totalAdsDisplayCount: Int, loadingTime: Double?) {
        var properties: [String: Any] = ["placement": placement, "type": type, "displayCount": displayCount, "fullScreenDisplayCount": fullScreenDisplayCount, "totalAdsDisplayCount": totalAdsDisplayCount]
        if let loadingTime { properties["loadingTime"] = loadingTime }
        trackEvent(name: "adDidLoad", properties: properties)
    }

    public func trackFullAdDidDisplay(in placement: String, type: String, failedRequests: Int, displayCount: Int, fullScreenDisplayCount: Int, totalAdsDisplayCount: Int, cpmLevel: Double?) {
        var properties: [String: Any] = ["placement": placement, "type": type, "displayCount": displayCount, "fullScreenDisplayCount": fullScreenDisplayCount, "totalAdsDisplayCount": totalAdsDisplayCount]
        if let cpmLevel { properties["cpmLevel"] = cpmLevel }
        trackEvent(name: "adDidDisplay", properties: properties)
    }

    public func trackBannerAdDidRequest(in placement: String, type: String, bannersDisplayCount: Int, displayCount: Int, totalAdsDisplayCount: Int) {
        trackEvent(name: "adDidRequest", properties: ["placement": placement, "type": type, "bannersDisplayCount": bannersDisplayCount, "displayCount": displayCount, "totalAdsDisplayCount": totalAdsDisplayCount])
    }

    public func trackBannerAdDidLoad(in placement: String, type: String, bannersDisplayCount: Int, displayCount: Int, totalAdsDisplayCount: Int, loadingTime: Double?) {
        var properties: [String: Any] = ["placement": placement, "type": type, "bannersDisplayCount": bannersDisplayCount, "displayCount": displayCount, "totalAdsDisplayCount": totalAdsDisplayCount]
        if let loadingTime { properties["loadingTime"] = loadingTime }
        trackEvent(name: "adDidLoad", properties: properties)
    }

    public func trackBannerAdDidDisplay(in placement: String, type: String, failedRequests: Int, bannersDisplayCount: Int, displayCount: Int, totalAdsDisplayCount: Int, cpmLevel: Double?) {
        var properties: [String: Any] = ["placement": placement, "type": type, "bannersDisplayCount": bannersDisplayCount, "displayCount": displayCount, "totalAdsDisplayCount": totalAdsDisplayCount]
        if let cpmLevel { properties["cpmLevel"] = cpmLevel }
        trackEvent(name: "adDidDisplay", properties: properties)
    }

    public func trackAdDidSkipPresent(in placement: String, type: String, failedRequests: Int, cpmLevel: Double) {
        trackEvent(name: "adDidSkipPresent", properties: ["placement": placement, "type": type, "failedRequests": failedRequests, "cpmLevel": cpmLevel])
    }

    public func trackAdDidFailToLoad(in placement: String, type: String, failedRequests: Int, error: String?) {
        trackEvent(name: "adDidFailToLoad", properties: ["placement": placement, "type": type, "failedRequests": failedRequests, "error": error ?? ""])
    }

    public func trackAdDidFailToDisplay(in placement: String, type: String) {
        trackEvent(name: "adDidFailToDisplay", properties: ["placement": placement, "type": type])
    }

    public func trackAdDidHide(in placement: String, type: String) {
        trackEvent(name: "adDidHide", properties: ["placement": placement, "type": type])
    }

    public func trackAdDidClick(in placement: String, type: String) {
        trackEvent(name: "adDidClick", properties: ["placement": placement, "type": type])
    }

    public func trackAdDidReward(in placement: String, type: String) {
        trackEvent(name: "adDidReward", properties: ["placement": placement, "type": type])
    }

    /// Доход с показа идёт и сюда, и отдельно в `api/v1/ad-revenue`.
    /// `source` — платформа медиации (AdMob / AppLovin / Yandex): по нему
    /// сверяет источники Telegram-отчёт бекенда.
    public func trackAdRevenue(in placement: String, type: String, value: Decimal, currency: String, network: String, adNetwork: String, unitId: String) {
        trackRevenue(amount: value, currency: currency, source: network,
                     properties: ["adPlacement": placement, "adType": type, "network": network])
    }

    // MARK: - Legal

    public func trackPrivacyPolicy() {
        trackEvent(name: "privacyPolicy")
    }

    public func trackTermsOfUse() {
        trackEvent(name: "termsOfUse")
    }

    // MARK: - Article

    public func trackArticleListDidPresent() {
        trackEvent(name: "articleListDidPresent")
    }

    public func trackArticleListDidDismiss(timespent: Double) {
        trackEvent(name: "articleListDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackArticleDetailDidPresent(id: String) {
        trackEvent(name: "articleDetailDidPresent", properties: ["id": id])
    }

    public func trackArticleDetailDidDismiss(id: String, timespent: Double) {
        trackEvent(name: "articleDetailDidDismiss", properties: ["id": id, "timespentSec": timespent])
    }

    // MARK: - Notifications & Errors

    public func trackNotificationDidOpen(_ userInfo: [String: Any]) {
        trackEvent(name: "notificationDidOpen", properties: userInfo)
    }

    public func trackError(name: String?, error: String?) {
        trackEvent(name: "error", properties: ["name": name ?? "unknown", "message": error ?? "unknown"])
    }

    // MARK: - Miner

    public func trackMinerCollectMultiplyDidDismiss(timespent: Double) {
        trackEvent(name: "minerCollectMultiplyDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackMinerCollectMultiplyDidPresent() {
        trackEvent(name: "minerCollectMultiplyDidPresent")
    }

    public func trackMinerCollectMultiplyDidTapCollect() {
        trackEvent(name: "minerCollectMultiplyDidTapCollect")
    }

    public func trackMinerCollectMultiplyDidTapMultiply() {
        trackEvent(name: "minerCollectMultiplyDidTapMultiply")
    }

    public func trackMinerDidCollect() {
        trackEvent(name: "minerDidCollect")
    }

    public func trackMinerDidCreate() {
        trackEvent(name: "minerDidCreate")
    }

    public func trackMinerDidCreateForAd() {
        trackEvent(name: "minerDidCreateForAd")
    }

    public func trackMinerDidDismiss(timespent: Double) {
        trackEvent(name: "minerDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackMinerDidFailUpdate() {
        trackEvent(name: "minerDidFailUpdate")
    }

    public func trackMinerDidFix() {
        trackEvent(name: "minerDidFix")
    }

    public func trackMinerDidPresent() {
        trackEvent(name: "minerDidPresent")
    }

    public func trackMinerDidStartUpdate() {
        trackEvent(name: "minerDidStartUpdate")
    }

    public func trackMinerDidUpdate() {
        trackEvent(name: "minerDidUpdate")
    }

    public func trackMinerFixDidDismiss(timespent: Double) {
        trackEvent(name: "minerFixDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackMinerFixDidPresent() {
        trackEvent(name: "minerFixDidPresent")
    }

    public func trackMinersListBannerDidPresent(type: String) {
        trackEvent(name: "minersListBannerDidPresent", properties: ["type": type])
    }

    public func trackMinersListBannerDidTap(type: String) {
        trackEvent(name: "minersListBannerDidTap", properties: ["type": type])
    }

    public func trackMinersListDidDismiss(timespent: Double) {
        trackEvent(name: "minersListDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackMinersListDidPresent() {
        trackEvent(name: "minersListDidPresent")
    }

    // MARK: - Бизнес

    public func trackBusinessListDidPresent() {
        trackEvent(name: "businessListDidPresent")
    }

    public func trackBusinessListDidDismiss(timespent: Double) {
        trackEvent(name: "businessListDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackBusinessListBannerDidPresent(type: String) {
        trackEvent(name: "businessListBannerDidPresent", properties: ["type": type])
    }

    public func trackBusinessListBannerDidTap(type: String) {
        trackEvent(name: "businessListBannerDidTap", properties: ["type": type])
    }

    public func trackBusinessCompanyDidPresent() {
        trackEvent(name: "businessCompanyDidPresent")
    }

    public func trackBusinessCompanyDidDismiss(timespent: Double) {
        trackEvent(name: "businessCompanyDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackBusinessCompanyDidCreate() {
        trackEvent(name: "businessCompanyDidCreate")
    }

    public func trackBusinessCompanyDidCreateForAd() {
        trackEvent(name: "businessCompanyDidCreateForAd")
    }

    public func trackBusinessDidCollect() {
        trackEvent(name: "businessDidCollect")
    }

    public func trackBusinessCollectMultiplyDidPresent() {
        trackEvent(name: "businessCollectMultiplyDidPresent")
    }

    public func trackBusinessCollectMultiplyDidDismiss(timespent: Double) {
        trackEvent(name: "businessCollectMultiplyDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackBusinessCollectMultiplyDidTapCollect() {
        trackEvent(name: "businessCollectMultiplyDidTapCollect")
    }

    public func trackBusinessCollectMultiplyDidTapMultiply() {
        trackEvent(name: "businessCollectMultiplyDidTapMultiply")
    }

    public func trackBusinessDidStartUpgrade() {
        trackEvent(name: "businessDidStartUpgrade")
    }

    public func trackBusinessDidUpgrade() {
        trackEvent(name: "businessDidUpgrade")
    }

    public func trackBusinessDidFailUpgrade() {
        trackEvent(name: "businessDidFailUpgrade")
    }

    public func trackBusinessDidRescue() {
        trackEvent(name: "businessDidRescue")
    }

    public func trackBusinessCrisisDidPresent() {
        trackEvent(name: "businessCrisisDidPresent")
    }

    public func trackBusinessCrisisDidDismiss(timespent: Double) {
        trackEvent(name: "businessCrisisDidDismiss", properties: ["timespentSec": timespent])
    }

    public func trackBusinessCrisisDidClose() {
        trackEvent(name: "businessCrisisDidClose")
    }

    // MARK: - Startup

    public func trackStartupDidChangeAmount(amount: Double, previousAmount: Double) {
        trackEvent(name: "startupDidTapChangeInvestmentAmount", properties: ["amount": amount, "previousAmount": previousAmount])
    }

    public func trackStartupDidCrash(amount: Double, multiplier: Double, investmentCount: Int) {
        trackEvent(name: "startupDidCrash", properties: ["amount": amount, "multiplier": multiplier, "investmentCount": investmentCount])
    }

    public func trackStartupDidDismiss(timespent: Double, timespentSec: Int) {
        trackEvent(name: "startupDidDismiss", properties: ["timespent": timespent, "timespentSec": timespentSec])
    }

    public func trackStartupDidPresent() {
        trackEvent(name: "startupDidPresent")
    }

    public func trackStartupDidTapCollectReward(profit: Double) {
        trackEvent(name: "startupDidTapCollectReward", properties: ["profit": profit])
    }

    public func trackStartupDidTapDoubleReward(profit: Double) {
        trackEvent(name: "startupDidTapDoubleReward", properties: ["profit": profit])
    }

    public func trackStartupDidTapGetProfit(amount: Double, multiplier: Double, investmentCount: Int) {
        trackEvent(name: "startupDidTapTakeProfit", properties: ["amount": amount, "multiplier": multiplier, "investmentCount": investmentCount])
    }

    public func trackStartupDidTapInvest(amount: Double, investmentCount: Int) {
        trackEvent(name: "startupDidTapInvest", properties: ["amount": amount, "investmentCount": investmentCount])
    }

    public func trackStartupDidTapTryAgain() {
        trackEvent(name: "startupDidTapTryAgain")
    }

    public func trackStartupLoseScreenDidPresent() {
        trackEvent(name: "startupLoseScreenDidPresent")
    }

    public func trackStartupWinScreenDidPresent() {
        trackEvent(name: "startupWinScreenDidPresent")
    }
}
