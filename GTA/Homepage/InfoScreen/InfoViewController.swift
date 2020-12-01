//
//  InfoViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 18.11.2020.
//

import UIKit

class InfoViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var officeStatusLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var screenTitleLabel: UILabel!
    var infoType: infoType = .info
    var officeDataSoure: [Hardcode] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        officeDataSoure = [Hardcode(imageName: "phone_icon", text: "(480) 555-0103"), Hardcode(imageName: "email_icon", text: "deanna.curtis@example.com"), Hardcode(imageName: "location", text: "9 Derry Street, London, W8 5HY, United Kindom"), Hardcode(imageName: "desk_finder", text: "Sony Offices", additionalText: "Select a Sony location to see current status")]
        setUpTableView()
        if infoType == .info {
            headerImageView.image = UIImage(named: "covid")
            screenTitleLabel.text = "Covid-19 Info"
        } else {
            headerImageView.image = UIImage(named: "office")
            screenTitleLabel.text = "Office Status"
        }
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        officeStatusLabel.isHidden = infoType != .office
        officeStatusLabel.layer.cornerRadius = 5
        officeStatusLabel.layer.masksToBounds = true
        infoLabel.text = self.title
        if infoType == .info {
            self.tabBarController?.tabBar.isHidden = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        self.tableView.cornerRadius = 16
        tableView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        tableView.register(UINib(nibName: "InfoArticleCell", bundle: nil), forCellReuseIdentifier: "InfoArticleCell")
        tableView.register(UINib(nibName: "AppsServiceAlertCell", bundle: nil), forCellReuseIdentifier: "AppsServiceAlertCell")
        tableView.register(UINib(nibName: "OfficeInfoCell", bundle: nil), forCellReuseIdentifier: "OfficeInfoCell")
    }

    @IBAction func backButtonDidPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

}

extension InfoViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch infoType {
        case .info:
            return 1
        default: return officeDataSoure.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return infoType == .info ? UITableView.automaticDimension : 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch infoType {
        case .info:
            let cell = tableView.dequeueReusableCell(withIdentifier: "InfoArticleCell", for: indexPath) as? InfoArticleCell
            cell?.infoLabel.text = "On 10 September 2020, Jersey reclassified nine cases as old infections resulting in negative cases reported on 11 September 2020. \n\nAs of 7 September 2020, there is a negative number of cumulative cases in Ecuador due to the removal of cases detected from rapid tests. In addition, the total number of reported COVID-19 deaths has shifted to include both probable and confirmed deaths, which lead to a steep increase on the 7 Sep.\n\nFrom end of August 2020, Swedish authorities are performing daily data consolidation leading to data retro-corrections. From week 38, the Swedish Public Health Agency will update COVID-19 daily data four times per week on Tuesday–Friday. Hence, the cumulative figures and related outputs include cases and deaths from the previous 14 days with available data at the time of data collection."
            return cell ?? UITableViewCell()
        default:
            let data = officeDataSoure[indexPath.row]
            if data.additionalText == nil {
                let cell = tableView.dequeueReusableCell(withIdentifier: "OfficeInfoCell", for: indexPath) as? OfficeInfoCell
                cell?.iconImageView.image = UIImage(named: data.imageName)
                cell?.infoLabel.text = data.text
                return cell ?? UITableViewCell()
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "AppsServiceAlertCell", for: indexPath) as? AppsServiceAlertCell
            cell?.iconImageView.image = UIImage(named: data.imageName)
            cell?.mainLabel.text = data.text
            cell?.descriptionLabel.text = data.additionalText
            cell?.separator.isHidden = false
            return cell ?? UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard infoType == .office, indexPath.row == officeDataSoure.count - 1  else { return }
        let officeLocation = OfficeLocationViewController()
        var statusBarHeight: CGFloat = 0.0
        if #available(iOS 13.0, *) {
            statusBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
            statusBarHeight = view.window?.safeAreaInsets.top ?? 0 > 24 ? statusBarHeight - 11 : statusBarHeight - 21
        } else {
            statusBarHeight = self.view.bounds.height - UIApplication.shared.statusBarFrame.height
            statusBarHeight = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0 > 24 ? statusBarHeight - 11 : statusBarHeight - 21
        }
        officeLocation.title = "Select a Sony Music Office Location"
        let panModalNavigationController = PanModalNavigationController(rootViewController: officeLocation)
        panModalNavigationController.setNavigationBarHidden(true, animated: true)
        panModalNavigationController.initialHeight = self.tableView.bounds.height - statusBarHeight
        
        presentPanModal(panModalNavigationController)
    }
    
}

//temp
struct Hardcode {
    var imageName: String
    var text: String
    var additionalText: String? = nil
}


