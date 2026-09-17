//
//  AdRevenueBackendProvider.swift
//  AnalyticsKit
//
//  Батч-отправка дохода с рекламы на бэкенд аналитики (analytics.ironsum.com).
//  Логика очереди повторяет revenue-ветку EventTracker: копим элементы, флашим
//  батчами по размеру/таймеру, персистим офлайн, дедупим на клиенте.
//  Отправка — живой POST (URLSession), гейтится RC-флагом isCustomRevenueTrackingEnabled;
//  Yandex не отправляется. Без логирования.
//

import Foundation
import Network
import UIKit

public final class AdRevenueBackendProvider {

    public static let shared = AdRevenueBackendProvider()

    // MARK: - Config

    private enum Constants {
        static let batchSize = 10                      // как revenueQueue в EventTracker
        static let flushInterval: TimeInterval = 20.0  // флаш раз в 20 сек
        static let maxRetryCount = 5
        static let retryDelay: TimeInterval = 1.0
        static let offlineFile = "adRevenueQueue.json"
    }

    // MARK: - Endpoint

    /// Слаг приложения, хост и ключ приходят из `AnalyticsConfiguration.adRevenue`.
    private var settings: AdRevenueConfiguration? { AnalyticsKit.configuration.adRevenue }

    private let path = "api/v1/ad-revenue"

    // MARK: - State

    private let queueSync = DispatchQueue(label: "com.dbahq.analyticskit.adRevenue.queueSync")
    private var revenueQueue: [[String: Any]] = []
    /// Клиентский дедуп. Ключи (_eventId) на бэкенд НЕ уходят.
    private var processedIds = Set<String>()
    private var isSending = false
    private var flushTimer: Timer?
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "com.dbahq.analyticskit.adRevenue.network")
    private var isNetworkAvailable = true
    private var isStarted = false

    private init() {}

    // MARK: - Lifecycle

    public func start() {
        var alreadyStarted = false
        queueSync.sync {
            alreadyStarted = isStarted
            isStarted = true
        }
        guard !alreadyStarted else { return }

        queueSync.async { [weak self] in self?.loadOfflineQueue() }
        startNetworkMonitoring()
        DispatchQueue.main.async { [weak self] in
            self?.registerLifecycleObservers()
            self?.startTimer()
        }
    }

    // MARK: - Public API (вызывается из AnalyticsManager.trackAdRevenue)

    public func track(placement: String, type: String, value: Decimal, currency: String,
                      network: String, adNetwork: String, unitId: String) {
        // Kill-switch со стороны приложения (у приложений — флаг Remote Config).
        guard let settings, settings.isEnabled() else { return }
        // Yandex не отправляем — в проекте не используется.
        guard network != "Yandex" else { return }

        let eventId = UUID().uuidString
        // 7 полей контракта (camelCase, adType — в нижнем регистре) + внутренний _eventId.
        let item: [String: Any] = [
            "adNetwork": adNetwork.isEmpty ? network : adNetwork,
            "adType": type,   // PascalCase, как ждёт бэк (Banner/Interstitial/Rewarded/AppOpen/Native)
            "amount": NSDecimalNumber(decimal: value),
            "currency": currency,
            "mediation": network,
            "unitId": unitId,
            "_eventId": eventId
        ]

        queueSync.async { [weak self] in
            guard let self = self else { return }
            guard !self.processedIds.contains(eventId) else { return }
            self.processedIds.insert(eventId)
            self.revenueQueue.append(item)
            if self.revenueQueue.count >= Constants.batchSize {
                self.flushLocked(reason: "size")
            }
        }
    }

    // MARK: - Timer

    private func startTimer() {
        flushTimer?.invalidate()
        let timer = Timer(timeInterval: Constants.flushInterval, target: self,
                          selector: #selector(flushFromTimer), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        flushTimer = timer
    }

    @objc private func flushFromTimer() {
        queueSync.async { [weak self] in self?.flushLocked(reason: "timer") }
    }

    // MARK: - Flush (вызывать только внутри queueSync)

    private func flushLocked(reason: String) {
        guard !isSending, !revenueQueue.isEmpty else { return }

        let batchCount = min(revenueQueue.count, Constants.batchSize)
        let batch = Array(revenueQueue.prefix(batchCount))
        revenueQueue.removeFirst(batchCount)   // оптимистичное удаление — защита от двойной отправки
        isSending = true

        // Готовим wire-payload: убираем внутренний _eventId, оставляем 7 полей.
        let wireItems: [[String: Any]] = batch.map { item in
            var copy = item
            copy.removeValue(forKey: "_eventId")
            return copy
        }
        let payload: [String: Any] = ["revenues": wireItems]

        // Реальная отправка (URLSession). Гейт по RC-флагу — в track(), сюда доходит только когда включено.
        // Политика ошибок:
        //   • успех (2xx) → batch уже удалён, дошлём остаток;
        //   • постоянная (4xx) → дропаем batch (кейс редкий, потеря приемлема) — очередь не клинит;
        //   • временная (нет сети / таймаут / 5xx) → вернуть в начало + персист, дошлём позже.
        guard let settings,
              let url = URL(string: settings.host + path),
              let body = try? JSONSerialization.data(withJSONObject: payload) else {
            revenueQueue.insert(contentsOf: batch, at: 0)   // не смогли сформировать — не теряем
            isSending = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(settings.apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(settings.appSlug, forHTTPHeaderField: "application")
        request.setValue("IOS", forHTTPHeaderField: "os")
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            self?.queueSync.async {
                guard let self = self else { return }
                self.isSending = false
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                if error == nil, (200...299).contains(status) {
                    // 2xx — успех, дошлём остаток
                    if !self.revenueQueue.isEmpty { self.flushLocked(reason: "drain") }
                } else if (400...499).contains(status) {
                    // 4xx — дропаем batch (уже удалён из очереди), чтобы не заклинить
                } else {
                    // 5xx / нет сети / таймаут — вернуть в очередь + персист
                    self.revenueQueue.insert(contentsOf: batch, at: 0)
                    self.storeOfflineQueue()
                }
            }
        }.resume()
    }

    // MARK: - App lifecycle

    private func registerLifecycleObservers() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(appDidEnterBackground),
                       name: UIApplication.didEnterBackgroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(appWillEnterForeground),
                       name: UIApplication.willEnterForegroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(appWillTerminate),
                       name: UIApplication.willTerminateNotification, object: nil)
    }

    @objc private func appDidEnterBackground() {
        queueSync.async { [weak self] in
            guard let self = self else { return }
            self.flushLocked(reason: "background")
            self.storeOfflineQueue()
        }
    }

    @objc private func appWillEnterForeground() {
        queueSync.async { [weak self] in self?.flushLocked(reason: "foreground") }
    }

    @objc private func appWillTerminate() {
        queueSync.sync { storeOfflineQueue() }
    }

    // MARK: - Network monitoring

    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let available = path.status == .satisfied
            self.queueSync.async {
                let wasAvailable = self.isNetworkAvailable
                self.isNetworkAvailable = available
                if !wasAvailable && available {
                    self.flushLocked(reason: "network-restore")
                }
            }
        }
        networkMonitor.start(queue: networkQueue)
    }

    // MARK: - Offline persistence (вызывать только внутри queueSync)

    private var offlineURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(Constants.offlineFile)
    }

    private func storeOfflineQueue() {
        guard let url = offlineURL, !revenueQueue.isEmpty else { return }
        if let data = try? JSONSerialization.data(withJSONObject: revenueQueue) {
            try? data.write(to: url)
        }
    }

    private func loadOfflineQueue() {
        guard let url = offlineURL,
              let data = try? Data(contentsOf: url),
              let items = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
        for item in items {
            guard let id = item["_eventId"] as? String, !processedIds.contains(id) else { continue }
            processedIds.insert(id)
            revenueQueue.append(item)
        }
        try? FileManager.default.removeItem(at: url)
    }
}
