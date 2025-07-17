//
//  WeatherViewModel.swift
//  WeatherApp
//
//  Created by Mohamed Kotb on 16/07/2025.
//

import Combine
import Foundation

class WeatherViewModel {
    @Published var temperature: String = ""
    @Published var description: String = ""
    @Published var iconURL: URL?
    @Published var forecastItems: [ForecastItem] = []
    @Published var cityName: String = ""
    @Published var currentDate: String = ""


    struct ForecastItem {
        let dateText: String
        let temp: String
        let iconURL: URL?
    }

    private let weatherService = WeatherService()
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()

    init() {
        fetchWeatherForCurrentLocation()
    }

    func fetchWeather(for city: String) {
        weatherService.fetchWeather(for: city)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] response in
                self?.updateCurrentWeather(response)
            }).store(in: &cancellables)

        weatherService.fetchForecast(for: city)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] response in
                self?.forecastItems = self?.parseForecast(response) ?? []
            }).store(in: &cancellables)
    }

    func fetchWeatherForCurrentLocation() {
        locationManager.locationPublisher
            .sink { [weak self] coord in
                self?.fetchWeather(lat: coord.latitude, lon: coord.longitude)
            }.store(in: &cancellables)

        locationManager.requestLocation()
    }

    private func fetchWeather(lat: Double, lon: Double) {
        weatherService.fetchWeather(lat: lat, lon: lon)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] response in
                self?.updateCurrentWeather(response)
            }).store(in: &cancellables)

        weatherService.fetchForecast(lat: lat, lon: lon)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] response in
                self?.forecastItems = self?.parseForecast(response) ?? []
            }).store(in: &cancellables)
    }


    func updateCurrentWeather(_ response: WeatherResponse) {
        let roundedTemp = Int(response.main.temp.rounded())
        temperature = "\(roundedTemp)°"
        description = response.weather.first?.description.capitalized ?? ""
        cityName = response.name

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d" 
        currentDate = formatter.string(from: Date())

        if let icon = response.weather.first?.icon {
            iconURL = URL(string: "https://openweathermap.org/img/wn/\(icon)@2x.png")
        }
    }

    private func parseForecast(_ response: ForecastResponse) -> [ForecastItem] {
        let formatter = DateFormatter()
        formatter.dateFormat = "E" 

        let filtered = response.list.filter {
            Calendar.current.component(.hour, from: Date(timeIntervalSince1970: $0.dt)) == 12
        }

        return filtered.map {
            let date = Date(timeIntervalSince1970: $0.dt)
            let roundedTemp = Int($0.main.temp.rounded())
            let tempString = "\(roundedTemp)°"

            let icon = $0.weather.first?.icon ?? ""

            return ForecastItem(
                dateText: formatter.string(from: date),
                temp: tempString,
                iconURL: URL(string: "https://openweathermap.org/img/wn/\(icon)@2x.png")
            )
        }
    }

}
