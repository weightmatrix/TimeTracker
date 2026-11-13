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
}

@MainActor
final class LiveWeatherSnapshotCenter: NSObject, CLLocationManagerDelegate {
    static let shared = LiveWeatherSnapshotCenter()
    static let cacheKey = "liveWeatherSnapshotV1"

    private let locationManager = CLLocationManager()
    private var isFetching = false
    private var lastAttempt = Date.distantPast

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func refreshIfNeeded() {
        guard !isFetching, Date().timeIntervalSince(lastAttempt) >= 30 * 60 else { return }
        lastAttempt = Date()
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            isFetching = true
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            lastAttempt = .distantPast
            refreshIfNeeded()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { isFetching = false; return }
        Task {
            defer { isFetching = false }
            do {
                let weather = try await WeatherService.shared.weather(for: location)
                let attribution = try await WeatherService.shared.attribution
                guard let today = weather.dailyForecast.forecast.first else { return }
                let snapshot = LiveWeatherSnapshot(
                    fetchedAt: Date(), symbolName: weather.currentWeather.symbolName,
                    temperature: Int(weather.currentWeather.temperature.converted(to: .celsius).value.rounded()),
                    summary: weather.currentWeather.condition.description,
                    high: Int(today.highTemperature.converted(to: .celsius).value.rounded()),
                    low: Int(today.lowTemperature.converted(to: .celsius).value.rounded()),
                    attributionURL: attribution.legalPageURL)
                guard let defaults = UserDefaults(suiteName: "group.Han.TimeTracker"),
                      let data = try? JSONEncoder().encode(snapshot) else { return }
                defaults.set(data, forKey: Self.cacheKey)
                for activity in Activity<TimeTrackerAttributes>.activities {
                    await activity.update(activity.content, timestamp: Date())
                }
            } catch {
                // Weather is optional; keep the timer usable when unavailable.
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isFetching = false
    }
}
#endif
