//
//  OfficeLocationViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 19.11.2020.
//

import UIKit
import PanModal

protocol OfficeSelectionDelegate: class {
    func officeWasSelected(_ officeId: Int)
}

class OfficeLocationViewController: UIViewController {
    
    @IBOutlet weak var backArrow: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottom: NSLayoutConstraint!
    @IBOutlet weak var backButtonLeading: NSLayoutConstraint!
    
    private let defaultBackButtonLeading: CGFloat = 24
    
    weak var officeSelectionDelegate: OfficeSelectionDelegate?
    
    var regionSelectionIsOn: Bool = true
    var dataProvider: HomeDataProvider?
    var regionDataSource: [Hardcode] = []
    var officeDataSource: [Hardcode] = []
    private var heightObserver: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        UIView.animate(withDuration: 0.4) {
            self.backArrow.isHidden = self.regionSelectionIsOn
            self.backButtonLeading.constant = self.defaultBackButtonLeading
            self.view.layoutIfNeeded()
        }
        
        setDataSource()
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
    
    private func setDataSource() {
        let regionsData = dataProvider?.getAllOfficeRegions().compactMap { Hardcode(imageName: "", text: $0) } ?? []
        regionDataSource = [Hardcode(imageName: "", text: "Use My Current Location", additionalText: "Will display office based on your current location")] + regionsData
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func backButtonDidPressed(_ sender: UIButton) {
        UIView.animate(withDuration: 0.3) {
            self.backArrow.alpha = 0
            self.backButtonLeading.constant = 60
            self.view.layoutIfNeeded()
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (_) in
            self.navigationController?.popWithFadeAnimation()
        }
        
    }
    
    deinit {
        heightObserver?.invalidate()
    }
    
}

extension OfficeLocationViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return regionSelectionIsOn ? regionDataSource.count : officeDataSource.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if regionSelectionIsOn {
            return provideRegionCell(for: indexPath)
        }
        return provideOfficeCell(for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == 0 && regionSelectionIsOn {
            let cell = cell as? AppsServiceAlertCell
            cell?.parentView.backgroundColor = UIColor(red: 247.0 / 255.0, green: 247.0 / 255.0, blue: 250.0 / 255.0, alpha: 1.0)
        } else if !regionSelectionIsOn {
            let cell = cell as? AppsServiceAlertCell
            cell?.iconWidth.constant = 17
        }
        
    }
    
    func provideRegionCell(for indexPath: IndexPath) -> UITableViewCell {
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
        cell?.infoLabel?.text = regionDataSource[indexPath.row].text
        return cell ?? UITableViewCell()
    }
    
    func provideOfficeCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AppsServiceAlertCell", for: indexPath) as? AppsServiceAlertCell
        cell?.mainLabel.text = officeDataSource[indexPath.row].text
        cell?.descriptionLabel.text = officeDataSource[indexPath.row].additionalText
        cell?.iconImageView.image = UIImage(named: "location")
        cell?.separator.isHidden = false
        cell?.arrowIcon.isHidden = true
        cell?.topSeparator.isHidden = indexPath.row != 0
        return cell ?? UITableViewCell()
    }
    
    // TODO: Refactor this method
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if regionSelectionIsOn {
            if indexPath.row == 0 {
                // TODO
                print(dataProvider?.getClosestOfficeId())
                // call bottom lines if all is ok, otherwise show some error
                // officeSelectionDelegate?.officeWasSelected(selectedOfficeId)
                //self.dismiss(animated: true, completion: nil)
            } else {
                let office = OfficeLocationViewController()
                office.officeSelectionDelegate = officeSelectionDelegate
                office.regionSelectionIsOn = false
                office.title = regionDataSource[indexPath.row].text
                let officesList = dataProvider?.getOffices(for: regionDataSource[indexPath.row].text).compactMap { officeRow in Hardcode(imageName: "", text: officeRow.officeName ?? "", additionalText: officeRow.officeLocation ?? "", officeId: officeRow.officeId) } ?? []
                office.officeDataSource = officesList
                self.navigationController?.pushWithFadeAnimationVC(office)
            }
        } else {
            guard indexPath.row < officeDataSource.count, let selectedOfficeId = officeDataSource[indexPath.row].officeId else { return }
            officeSelectionDelegate?.officeWasSelected(selectedOfficeId)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
}
