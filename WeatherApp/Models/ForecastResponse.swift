//
//  ForecastResponse.swift
//  WeatherApp
//
//  Created by Mohamed Kotb on 16/07/2025.
//

import Foundation

struct ForecastResponse: Decodable {
    let list: [Forecast]

    struct Forecast: Decodable {
        let dt: TimeInterval
        let main: Main
        let weather: [Weather]

        struct Main: Decodable {
            let temp: Double
        }

        struct Weather: Decodable {
            let description: String
            let icon: String
        }
    }
}

struct ForecastItem {
    let dateText: String
    let temp: String
    let iconURL: URL?
}
