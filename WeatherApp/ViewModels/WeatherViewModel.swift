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
        let weatherPublisher = weatherService.fetchWeather(lat: lat, lon: lon)
        let forecastPublisher = weatherService.fetchForecast(lat: lat, lon: lon)

        Publishers.Zip(weatherPublisher, forecastPublisher)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] weather, forecast in
                self?.updateCurrentWeather(weather)
                self?.forecastItems = self?.parseForecast(forecast) ?? []
                self?.cacheWeather(weather, forecast: forecast)
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
    
    func cacheWeather(_ response: WeatherResponse, forecast: ForecastResponse) {
        let context = CoreDataManager.shared.context

        // Remove old cache
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CachedWeather")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try? context.execute(deleteRequest)
        
        let fetchRequest2: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CachedForecast")
        let deleteRequest2 = NSBatchDeleteRequest(fetchRequest: fetchRequest2)
        try? context.execute(deleteRequest2)

        // Save new weather
        let weatherEntity = CachedWeather(context: context)
        weatherEntity.cityName = response.name
        weatherEntity.temperature = response.main.temp
        weatherEntity.condition = response.weather.first?.description ?? ""
        weatherEntity.date = Date()

        // Save forecast
        for item in forecast.list.prefix(5) {
            let forecastEntity = CachedForecast(context: context)
            forecastEntity.cityName = response.name
            forecastEntity.temperature = item.main.temp
            forecastEntity.icon = item.weather.first?.icon ?? ""
            forecastEntity.date = Date(timeIntervalSince1970: item.dt)
        }

        CoreDataManager.shared.saveContext()
    }
    
    func loadCachedWeather() -> (weather: CachedWeather?, forecasts: [CachedForecast]) {
        let context = CoreDataManager.shared.context

        let weatherRequest: NSFetchRequest<CachedWeather> = CachedWeather.fetchRequest()
        weatherRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let weather = try? context.fetch(weatherRequest).first

        let forecastRequest: NSFetchRequest<CachedForecast> = CachedForecast.fetchRequest()
        forecastRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        let forecasts = (try? context.fetch(forecastRequest)) ?? []

        return (weather, forecasts)
    }

    

    func isConnectedToNetwork() -> Bool {
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        var isConnected = false

        monitor.pathUpdateHandler = { path in
            isConnected = path.status == .satisfied
            semaphore.signal()
            monitor.cancel()
        }

        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        semaphore.wait()
        return isConnected
    }

}
