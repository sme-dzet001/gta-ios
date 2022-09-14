//
//  LogoutView.swift
//  GTA
//
//  Created by DZET001 Kostiantyn Dzetsiuk on 14.09.2022.
//

import UIKit

class LogoutView: UIView {
    
    @IBOutlet weak var logoutView: UIView!
    @IBOutlet weak var softwareVersionLabel: UILabel!
    weak var logoutDelegate: LogoutDelegate?
    
    class func instanceFromNib() -> LogoutView {
        let logoutView = UINib(nibName: "LogoutView", bundle: nil).instantiate(withOwner: self, options: nil).first as! LogoutView
        return logoutView
    }
    
    func setUpView() {
        setVersion()
        logoutView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(logoutDidTapped)))
    }
    
    @objc private func logoutDidTapped() {
        logoutDelegate?.logoutDidPressed()
    }
    
    private func setVersion() {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        softwareVersionLabel.text = String(format: "Version \(version) (\(build))")
    }

}
