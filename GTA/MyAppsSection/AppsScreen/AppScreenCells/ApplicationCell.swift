//
//  ApplicationCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 06.11.2020.
//

import UIKit

class ApplicationCell: UITableViewCell {

    @IBOutlet weak var appIcon: UIImageView!
    @IBOutlet weak var appStatus: UIView!
    @IBOutlet weak var appName: UILabel!
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusParentView: UIView!
    @IBOutlet weak var separator: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setUpCell(with data: AppInfo) {
        iconLabel.isHidden = true
        if data.appImageData.imageStatus == .loading {
            startAnimation()
        } else {
            stopAnimation()
        }
        if let imageData = data.appImageData.imageData, let image = UIImage(data: imageData) {
            appIcon.image = image
        } else if data.appImageData.imageStatus == .failed {
            showFirstCharFrom(data.app_name)
        }
        appName.text = data.app_name
        var color: UIColor = .clear
        switch data.appStatus {
        case .expired:
            appStatus.backgroundColor = .clear
            statusParentView.backgroundColor = .clear
        case .online, .none:
            color = UIColor(red: 52.0 / 255.0, green: 199.0 / 255.0, blue: 89.0 / 255.0, alpha: 1.0)
        case .offline:
            color = UIColor(red: 255.0 / 255.0, green: 62.0 / 255.0, blue: 51.0 / 255.0, alpha: 1.0)
        default:
            color = UIColor(red: 255.0 / 255.0, green: 153.0 / 255.0, blue: 0.0 / 255.0, alpha: 1.0)
        }
        if data.appStatus != .expired {
            setUpStatusCircle(with: color)
        }
    }
    
    private func setUpStatusCircle(with color: UIColor) {
        appStatus.backgroundColor = color
        statusParentView.backgroundColor = .white
        statusParentView.layer.cornerRadius = statusParentView.frame.size.width / 2
        appStatus.layer.cornerRadius = appStatus.frame.size.width / 2
    }
    
    private func showFirstCharFrom(_ text: String?) {
        appIcon.isHidden = false
        appIcon.image = UIImage(named: "empty_app_icon")
        guard let char = text?.trimmingCharacters(in: .whitespacesAndNewlines).first else { return }
        iconLabel.text = char.uppercased()
        iconLabel.isHidden = false
    }
    
    private func startAnimation() {
        appIcon.isHidden = true
        self.activityIndicator.isHidden = false
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.startAnimating()
        appStatus.isHidden = true
        statusParentView.isHidden = true
    }
    
    private func stopAnimation() {
        appIcon.isHidden = false
        self.activityIndicator.isHidden = true
        self.activityIndicator.stopAnimating()
        appStatus.isHidden = false
        statusParentView.isHidden = false
    }
    
}
