//
//  CoreDataManager.swift
//  WeatherApp
//
//  Created by Mohamed Kotb on 17/07/2025.
//

import Foundation
import CoreData
import UIKit


class CoreDataManager {
    static let shared = CoreDataManager()

    let context: NSManagedObjectContext
    private let persistentContainer: NSPersistentContainer

    private init() {
        persistentContainer = NSPersistentContainer(name: "WeatherApp")
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        context = persistentContainer.viewContext
    }

    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed saving context: \(error)")
            }
        }
    }

    
    func cacheWeather(_ response: WeatherResponse, forecast: ForecastResponse) {
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

        saveContext()
    }

    
    func loadCachedWeather() -> (weather: CachedWeather?, forecasts: [CachedForecast]) {
        let weatherRequest: NSFetchRequest<CachedWeather> = CachedWeather.fetchRequest()
        weatherRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let weather = try? context.fetch(weatherRequest).first

        let forecastRequest: NSFetchRequest<CachedForecast> = CachedForecast.fetchRequest()
        forecastRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        let forecasts = (try? context.fetch(forecastRequest)) ?? []

        return (weather, forecasts)
    }
}
