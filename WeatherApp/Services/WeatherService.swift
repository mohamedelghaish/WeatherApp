//
//  WeatherService.swift
//  WeatherApp
//
//  Created by Mohamed Kotb on 16/07/2025.
//

import Combine
import Foundation

class WeatherService {
    private let apiKey = "3d91b6692ca2f8900c21f4c7cd8099a9"

    func fetchWeather(for city: String) -> AnyPublisher<WeatherResponse, Error> {
        let url = "https://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=\(apiKey)&units=metric"
        return request(url)
    }

    func fetchWeather(lat: Double, lon: Double) -> AnyPublisher<WeatherResponse, Error> {
        let url = "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        return request(url)
    }

    func fetchForecast(for city: String) -> AnyPublisher<ForecastResponse, Error> {
        let url = "https://api.openweathermap.org/data/2.5/forecast?q=\(city)&appid=\(apiKey)&units=metric"
        return request(url)
    }

    func fetchForecast(lat: Double, lon: Double) -> AnyPublisher<ForecastResponse, Error> {
        let url = "https://api.openweathermap.org/data/2.5/forecast?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        return request(url)
    }

    private func request<T: Decodable>(_ urlString: String) -> AnyPublisher<T, Error> {
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: T.self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
}
