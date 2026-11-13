#if os(iOS) && !targetEnvironment(macCatalyst)
import ActivityKit
import CoreLocation
import Foundation
import WeatherKit

struct LiveWeatherSnapshot: Codable {
    let fetchedAt: Date
    let symbolName: String
    let temperature: Int
    let summary: String
    let high: Int
    let low: Int
    let attributionURL: URL
    let precipitationAlert: String?
    let precipitationKind: String?
}

@MainActor
final class LiveWeatherSnapshotCenter: NSObject, CLLocationManagerDelegate {
    static let shared = LiveWeatherSnapshotCenter()
    static let cacheKey = "liveWeatherSnapshotV1"

    private let locationManager = CLLocationManager()
    private var isFetching = false
    private var lastAttempt = Date.distantPast
    private var lastSuccess = Date.distantPast

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func refreshIfNeeded() {
        guard !isFetching, Date().timeIntervalSince(lastAttempt) >= (lastSuccess >= lastAttempt ? 30 * 60 : 2 * 60) else { return }
        lastAttempt = Date()
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            note("location-requested")
            isFetching = true
            locationManager.requestLocation()
        case .notDetermined:
            note("location-permission-pending")
            locationManager.requestWhenInUseAuthorization()
        default:
            note("location-denied")
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            lastAttempt = .distantPast
            refreshIfNeeded()
        } else if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            note("location-denied")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { isFetching = false; note("location-empty"); return }
        Task {
            defer { isFetching = false }
            do {
                note("weather-requested")
                let weather = try await WeatherService.shared.weather(for: location)
                let today = weather.dailyForecast.forecast.first
                let attribution = try? await WeatherService.shared.attribution
                let nearHours = weather.hourlyForecast.forecast.filter {
                    $0.date >= Date().addingTimeInterval(-3600) && $0.date <= Date().addingTimeInterval(12 * 3600)
                }
                let upcoming = nearHours.first {
                    $0.precipitation != .none &&
                    ($0.precipitationChance >= 0.35 || $0.precipitationAmount.converted(to: .millimeters).value >= 0.1)
                }
                let kind: String? = upcoming.map {
                    switch $0.precipitation {
                    case .snow, .sleet, .mixed: return "snow"
                    default: return "rain"
                    }
                }
                let alert: String? = upcoming.map { hour in
                    let prefix = hour.date <= Date().addingTimeInterval(3600) ? "当前" : "未来12小时"
                    return "\(prefix)有\(kind == "snow" ? "雪" : "雨") \(Int((hour.precipitationChance * 100).rounded()))%"
                }
                let snapshot = LiveWeatherSnapshot(
                    fetchedAt: Date(), symbolName: weather.currentWeather.symbolName,
                    temperature: Int(weather.currentWeather.temperature.converted(to: .celsius).value.rounded()),
                    summary: weather.currentWeather.condition.description,
                    high: Int((today?.highTemperature ?? weather.currentWeather.temperature).converted(to: .celsius).value.rounded()),
                    low: Int((today?.lowTemperature ?? weather.currentWeather.temperature).converted(to: .celsius).value.rounded()),
                    attributionURL: attribution?.legalPageURL ?? URL(string: "https://weatherkit.apple.com/legal-attribution.html")!,
                    precipitationAlert: alert, precipitationKind: kind)
                guard let defaults = UserDefaults(suiteName: "group.Han.TimeTracker"),
                      let data = try? JSONEncoder().encode(snapshot) else { note("cache-encode-failed"); return }
                defaults.set(data, forKey: Self.cacheKey)
                lastSuccess = Date()
                note("weather-ready")
                for activity in Activity<TimeTrackerAttributes>.activities {
                    await activity.update(activity.content, timestamp: Date())
                }
            } catch {
                note("weather-error: \(error.localizedDescription)")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isFetching = false
        note("location-error: \(error.localizedDescription)")
    }

    private func note(_ status: String) {
        UserDefaults(suiteName: "group.Han.TimeTracker")?.set(status, forKey: "liveWeatherStatusV1")
    }
}
#endif
