//
//  ForecastCell.swift
//  WeatherApp
//
//  Created by Mohamed Kotb on 16/07/2025.
//

import UIKit

class ForecastCell: UICollectionViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!

    func configure(with item: WeatherViewModel.ForecastItem) {
        dayLabel.text = item.dateText
        tempLabel.text = item.temp
        if let url = item.iconURL {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data {
                    DispatchQueue.main.async {
                        self.iconImageView.image = UIImage(data: data)
                    }
                }
            }.resume()
        }
    }
}
