//
//  WeatherViewModel.swift
//  WeatherApp
//
//  Created by Mohamed Kotb on 16/07/2025.
//

import Combine
import Foundation
import CoreData
import Network
class WeatherViewModel {
    @Published var temperature: String = ""
    @Published var description: String = ""
    @Published var iconURL: URL?
    @Published var forecastItems: [ForecastItem] = []
    @Published var cityName: String = ""
    @Published var currentDate: String = ""


    

    private let weatherService = WeatherService()
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()

    init() {
        fetchWeatherForCurrentLocation()
    }
    
    func fetchWeather(for city: String) {
        let weatherPublisher = weatherService.fetchWeather(for: city)
        let forecastPublisher = weatherService.fetchForecast(for: city)

        Publishers.Zip(weatherPublisher, forecastPublisher)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] weather, forecast in
                self?.updateCurrentWeather(weather)
                self?.forecastItems = self?.parseForecast(forecast) ?? []
                CoreDataManager.shared.cacheWeather(weather, forecast: forecast)
            })
            .store(in: &cancellables)
    }


    func fetchWeatherForCurrentLocation() {
        locationManager.locationPublisher
            .sink { [weak self] coord in
                self?.fetchWeather(lat: coord.latitude, lon: coord.longitude)
            }.store(in: &cancellables)

        locationManager.requestLocation()
    }

    
    private func fetchWeather(lat: Double, lon: Double) {
        let weatherPublisher = weatherService.fetchWeather(lat: lat, lon: lon)
        let forecastPublisher = weatherService.fetchForecast(lat: lat, lon: lon)

        Publishers.Zip(weatherPublisher, forecastPublisher)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] weather, forecast in
                self?.updateCurrentWeather(weather)
                self?.forecastItems = self?.parseForecast(forecast) ?? []

                CoreDataManager.shared.cacheWeather(weather, forecast: forecast)
            })
            .store(in: &cancellables)
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
    
    
    func loadCachedWeather() -> (weather: CachedWeather?, forecasts: [CachedForecast]) {
        CoreDataManager.shared.loadCachedWeather()
    }
    
    func isConnectedToNetwork() -> Bool {
        return NetworkConnectivityService.shared.isConnectedToNetwork()
    }

}
