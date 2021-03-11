//
//  SystemStatusHeader.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 11.11.2020.
//

import UIKit

class SystemStatusHeader: UIView {
    
    @IBOutlet weak var appStatusDescription: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var statusParentView: UIView!
    @IBOutlet weak var onlineStatusView: UIView!
    @IBOutlet weak var offlineStatusView: UIView!
    @IBOutlet weak var otherStatusView: UIView!
    
    var systemStatus: SystemStatus = .none
    
    class func instanceFromNib() -> SystemStatusHeader {
        let header = UINib(nibName: "SystemStatusHeader", bundle: nil).instantiate(withOwner: self, options: nil).first as! SystemStatusHeader
        return header
    }
    
    func setUpSignalViews() { // temp name
        statusParentView.layer.cornerRadius = statusParentView.frame.size.width / 6
        statusParentView.layer.shadowColor = UIColor(red: 235.0 / 255.0, green: 235.0 / 255.0, blue: 239.0 / 255.0, alpha: 1.0).cgColor
        statusParentView.layer.shadowOpacity = 1
        statusParentView.layer.shadowOffset = .zero
        statusParentView.layer.shadowRadius = 2
        let contactRect = CGRect(x: 0, y: (statusParentView.frame.height / 2) - 5, width: statusParentView.frame.width - 10, height: (statusParentView.frame.height / 2) + 5)
        statusParentView.layer.shadowPath = UIBezierPath(roundedRect: contactRect, cornerRadius: statusParentView.frame.size.width / 2).cgPath
        
        
        onlineStatusView.layer.cornerRadius = onlineStatusView.frame.size.width / 2
        offlineStatusView.layer.cornerRadius = offlineStatusView.frame.size.width / 2
        otherStatusView.layer.cornerRadius = otherStatusView.frame.size.width / 2
        var appStatus: String = "Everything Online, Looking Good!"
        switch systemStatus {
        case .online, .none:
            onlineStatusView.backgroundColor = onlineStatusView.backgroundColor?.withAlphaComponent(1.0)
        case .offline:
            offlineStatusView.backgroundColor = offlineStatusView.backgroundColor?.withAlphaComponent(1.0)
            appStatus = "Complete Outage"
        case .pendingAlerts:
            otherStatusView.backgroundColor = otherStatusView.backgroundColor?.withAlphaComponent(1.0)
            appStatus = "Something Wrong "
        case .expired:
            appStatus = ""
        }
        appStatusDescription.text = appStatus
    }
    
    override func draw(_ rect: CGRect) {
        setUpSignalViews()
    }
    
}
