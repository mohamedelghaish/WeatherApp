//
//  NetworkConnectivityService.swift
//  WeatherApp
//
//  Created by Mohamed Kotb on 19/07/2025.
//

import Foundation
import Network

class NetworkConnectivityService {
    static let shared = NetworkConnectivityService()

    private init() {}

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
