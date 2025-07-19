//
//  ViewController.swift
//  WeatherApp
//
//  Created by Mohamed Kotb on 16/07/2025.
//

import UIKit
import Combine

class ViewController: UIViewController {
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var forecastCollectionView: UICollectionView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!

    private let viewModel = WeatherViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var forecastItems: [ForecastItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        registerForecastCell()
        setupCollectionView()
        viewModel.fetchWeatherForCurrentLocation()
        if !viewModel.isConnectedToNetwork() {
            loadOfflineWeatherIfAvailable()
        }
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        DispatchQueue.main.async {
            self.forecastCollectionView.collectionViewLayout.invalidateLayout()
            self.forecastCollectionView.reloadData()
        }
    }

    private func registerForecastCell() {
        let nib = UINib(nibName: "ForecastCell", bundle: nil)
        forecastCollectionView.register(nib, forCellWithReuseIdentifier: "ForecastCell")
    }

    private func setupBindings() {
        viewModel.$temperature
            .assign(to: \.text!, on: tempLabel)
            .store(in: &cancellables)

        viewModel.$description
            .assign(to: \.text!, on: descLabel)
            .store(in: &cancellables)

        viewModel.$iconURL
            .sink { [weak self] url in
                guard let url = url else { return }
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    if let data = data {
                        DispatchQueue.main.async {
                            self?.iconImageView.image = UIImage(data: data)
                        }
                    }
                }.resume()
            }.store(in: &cancellables)

        viewModel.$forecastItems
            .sink { [weak self] items in
                self?.forecastItems = items
                DispatchQueue.main.async {
                    self?.forecastCollectionView.reloadData()
                    self?.forecastCollectionView.collectionViewLayout.invalidateLayout()
                }
                
            }.store(in: &cancellables)
        
        viewModel.$cityName
            .assign(to: \.text!, on: cityLabel)
            .store(in: &cancellables)

        viewModel.$currentDate
            .assign(to: \.text!, on: dateLabel)
            .store(in: &cancellables)

    }

    private func setupCollectionView() {
        forecastCollectionView.dataSource = self
        forecastCollectionView.delegate = self
    }
    func loadOfflineWeatherIfAvailable() {
        let cached = viewModel.loadCachedWeather()
        
        if let weather = cached.weather {
            cityLabel.text = weather.cityName
            tempLabel.text = "\(Int(weather.temperature))°"
            descLabel.text = weather.condition
            
            
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.dateFormat = "EEEE, MMM d"
            if let date = weather.date {
                dateLabel.text = formatter.string(from: date)
            }
        }
        
        self.forecastItems = cached.forecasts.enumerated().compactMap { index, forecast in
            guard let originalDate = forecast.date,
                  let icon = forecast.icon else { return nil }
            
            let adjustedDate = Calendar.current.date(byAdding: .day, value: index, to: originalDate) ?? originalDate
            
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "EEE"
            
            let dateText = formatter.string(from: adjustedDate)
            let temp = String(Int(forecast.temperature)) + "°"
            let iconURL = URL(string: "https://openweathermap.org/img/wn/\(icon)@2x.png")
            
            return ForecastItem(dateText: dateText, temp: temp, iconURL: iconURL)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.forecastCollectionView.reloadData()
                self.forecastCollectionView.collectionViewLayout.invalidateLayout()
            }
        
    }
        
    @IBAction func searchButtonTapped(_ sender: UIButton) {
        guard let city = cityTextField.text, !city.isEmpty else { return }
        viewModel.fetchWeather(for: city)
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        forecastItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ForecastCell", for: indexPath) as! ForecastCell
        cell.configure(with: forecastItems[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 80, height: 170)
    }
}
