//
//  WeatherResponse.swift
//  WeatherApp
//
//  Created by Mohamed Kotb on 16/07/2025.
//

import Foundation

struct WeatherResponse: Decodable {
    let name: String
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
