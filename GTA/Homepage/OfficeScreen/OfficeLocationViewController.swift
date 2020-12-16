//
//  OfficeLocationViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 19.11.2020.
//

import UIKit
import PanModal

class OfficeLocationViewController: UIViewController {
    
    @IBOutlet weak var backArrow: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottom: NSLayoutConstraint!
    @IBOutlet weak var backButtonLeading: NSLayoutConstraint!
    
    private let defaultBackButtonLeading: CGFloat = 24
    
    var selectionIsOn: Bool = true
    var countryDataSource: [Hardcode] = []
    var regionDataSource: [Hardcode] = []
    private var heightObserver: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        UIView.animate(withDuration: 0.4) {
            self.backArrow.isHidden = self.selectionIsOn
            self.backButtonLeading.constant = self.defaultBackButtonLeading
            self.view.layoutIfNeeded()
        }
        
        setHardcodeData()
        titleLabel.text = title
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setUpTextViewLayout()
        heightObserver = self.navigationController?.presentationController?.presentedView?.observe(\.frame, changeHandler: { [weak self] (_, _) in
            self?.setUpTextViewLayout()
        })
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "AppsServiceAlertCell", bundle: nil), forCellReuseIdentifier: "AppsServiceAlertCell")
        tableView.register(UINib(nibName: "OfficeInfoCell", bundle: nil), forCellReuseIdentifier: "OfficeInfoCell")
    }
    
    private func setUpTextViewLayout() {
        let position = UIScreen.main.bounds.height - (self.navigationController?.presentationController?.presentedView?.frame.origin.y ?? 0.0)
        tableViewBottom.constant = position > 0 ? self.view.frame.height - position : 0
        self.view.layoutIfNeeded()
    }
    
    private func setHardcodeData() {
        countryDataSource = [Hardcode(imageName: "", text: "Use My Current Location", additionalText: "Will display office based on your current location"), Hardcode(imageName: "", text: "North American Region Office"), Hardcode(imageName: "", text: "South American Region Office"), Hardcode(imageName: "", text: "UK & EU Regional Office"), Hardcode(imageName: "", text: "Asia & Aus Regional Offices"), Hardcode(imageName: "", text: "Japan Regional Offices")]
        
        regionDataSource = [Hardcode(imageName: "", text: "New York", additionalText: "25 Madison Avenue, New York, NY"), Hardcode(imageName: "", text: "Culver City", additionalText: "10202 Washington Blvd, Culver City, CA"), Hardcode(imageName: "", text: "Lyndhurst", additionalText: "210 Clay Avenue, Lyndhurst, NJ"), Hardcode(imageName: "", text: "New York", additionalText: "25 Madison Avenue, New York, NY"), Hardcode(imageName: "", text: "Culver City", additionalText: "10202 Washington Blvd, Culver City, CA"), Hardcode(imageName: "", text: "Lyndhurst", additionalText: "210 Clay Avenue, Lyndhurst, NJ"), Hardcode(imageName: "", text: "New York", additionalText: "25 Madison Avenue, New York, NY"), Hardcode(imageName: "", text: "New York", additionalText: "25 Madison Avenue, New York, NY")]
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func backButtonDidPressed(_ sender: UIButton) {
        self.navigationController?.popWithFadeAnimation()
    }
    
    deinit {
        heightObserver?.invalidate()
    }
    
}

extension OfficeLocationViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectionIsOn ? countryDataSource.count : regionDataSource.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if selectionIsOn {
            return provideCountryCell(for: indexPath)
        }
        return provideRegionCell(for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == 0 && selectionIsOn {
            let cell = cell as? AppsServiceAlertCell
            cell?.parentView.backgroundColor = UIColor(red: 247.0 / 255.0, green: 247.0 / 255.0, blue: 250.0 / 255.0, alpha: 1.0)
        } else if !selectionIsOn {
            let cell = cell as? AppsServiceAlertCell
            cell?.iconWidth.constant = 17
        }
        
    }
    
    func provideCountryCell(for indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AppsServiceAlertCell", for: indexPath) as? AppsServiceAlertCell
            cell?.mainLabel.text = "Use My Current Location"
            cell?.descriptionLabel.text = "Will display office based on your current location"
            cell?.iconImageView.image = UIImage(named: "gps_icon")
            cell?.arrowIcon.isHidden = true
            cell?.separator.isHidden = false
            return cell ?? UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "OfficeInfoCell", for: indexPath) as? OfficeInfoCell
        cell?.iconImageView.image = UIImage(named: "region_icon")
        cell?.infoLabel?.text = countryDataSource[indexPath.row].text
        return cell ?? UITableViewCell()
    }
    
    func provideRegionCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AppsServiceAlertCell", for: indexPath) as? AppsServiceAlertCell
        cell?.mainLabel.text = regionDataSource[indexPath.row].text
        cell?.descriptionLabel.text = regionDataSource[indexPath.row].additionalText
        cell?.iconImageView.image = UIImage(named: "location")
        cell?.separator.isHidden = false
        cell?.arrowIcon.isHidden = true
        cell?.topSeparator.isHidden = indexPath.row != 0
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard selectionIsOn, indexPath.row != 0 else { return }
        let office = OfficeLocationViewController()
        office.selectionIsOn = false
        office.title = countryDataSource[indexPath.row].text
        self.navigationController?.pushWithFadeAnimationVC(office)
        //self.navigationController?.pushViewController(office, animated: true)
    }
    
}
