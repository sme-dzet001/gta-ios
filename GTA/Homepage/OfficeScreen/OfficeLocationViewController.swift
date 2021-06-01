//
//  OfficeLocationViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 19.11.2020.
//

import UIKit
import PanModal

protocol OfficeSelectionDelegate: AnyObject {
    func officeWasSelected()
}

class OfficeLocationViewController: UIViewController {
    
    @IBOutlet weak var backArrow: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottom: NSLayoutConstraint!
    @IBOutlet weak var backButtonLeading: NSLayoutConstraint!
    
    private let defaultBackButtonLeading: CGFloat = 24
    
    //weak var officeSelectionDelegate: OfficeSelectionDelegate?
    
    // bottom params are used to determine if office selection is in progress
    var useMyCurrentLocationIsInProgress = false {
        didSet {
            tableView.reloadData()
        }
    }
    var officeIdGoingToBeSelected: Int? {
        didSet {
            tableView.reloadData()
        }
    }
    
    var forceOfficeSelection = false
    var selectedRegionName: String?
    var regionSelectionIsOn: Bool = true
    var dataProvider: HomeDataProvider?
    var regionDataSource: [Hardcode] = []
    var officeDataSource: [Hardcode] = []
    private var heightObserver: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if regionSelectionIsOn {
            dataProvider?.userLocationManager.userLocationManagerDelegate = self
        }
        setUpTableView()
        UIView.animate(withDuration: 0.4) {
            self.backArrow.isHidden = self.regionSelectionIsOn
            self.backButtonLeading.constant = self.defaultBackButtonLeading
            self.view.layoutIfNeeded()
        }
        
        setDataSource()
        titleLabel.text = title
        closeButton.isHidden = forceOfficeSelection
        setNeedsStatusBarAppearanceUpdate()
        setAccessibilityIdentifiers()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setUpTableViewLayout()
        heightObserver = self.navigationController?.presentationController?.presentedView?.observe(\.frame, changeHandler: { [weak self] (_, _) in
            self?.setUpTableViewLayout()
        })
    }
    
    private func setAccessibilityIdentifiers() {
        tableView.accessibilityIdentifier = "OfficeSelectionScreenTableView"
        backArrow.accessibilityIdentifier = "OfficeSelectionScreenBackButton"
        titleLabel.accessibilityIdentifier = "OfficeSelectionScreenTitleLabel"
        closeButton.accessibilityIdentifier = "OfficeSelectionScreenCloseButton"
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "AppsServiceAlertCell", bundle: nil), forCellReuseIdentifier: "AppsServiceAlertCell")
        tableView.register(UINib(nibName: "OfficeInfoCell", bundle: nil), forCellReuseIdentifier: "OfficeInfoCell")
        tableView.register(UINib(nibName: "OfficeSelectionCell", bundle: nil), forCellReuseIdentifier: "OfficeSelectionCell")
    }
    
    private func setUpTableViewLayout() {
        let position = UIScreen.main.bounds.height - (self.navigationController?.presentationController?.presentedView?.frame.origin.y ?? 0.0)
        tableViewBottom.constant = position > 0 ? self.view.frame.height - position : 0
        self.view.layoutIfNeeded()
    }
    
    private func setDataSource() {
        let regionsData = dataProvider?.getAllOfficeRegions().compactMap { Hardcode(imageName: "", text: $0) } ?? []
        regionDataSource = [Hardcode(imageName: "", text: "Use My Current Location", additionalText: "Will select office based on your current location")] + regionsData
        if let regionName = selectedRegionName {
            officeDataSource = dataProvider?.getOffices(for: regionName).compactMap { officeRow in Hardcode(imageName: "", text: officeRow.officeName ?? "", additionalText: officeRow.officeLocation ?? "", officeId: officeRow.officeId) } ?? []
        }
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        guard !forceOfficeSelection else { return }
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func backButtonDidPressed(_ sender: UIButton) {
        UIView.animate(withDuration: 0.3) {
            self.backArrow.alpha = 0
            self.backButtonLeading.constant = 60
            self.view.layoutIfNeeded()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.navigationController?.popWithFadeAnimation()
        }
    }
    
    func displayPermissionDeniedAlert() {
        let alertController = UIAlertController(title: nil, message: "Location permission needed to access your location", preferredStyle: .alert)
        let openSettingsAction = UIAlertAction(title: "Settings", style: .default) { (_) in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            }
        }
        let closeAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(openSettingsAction)
        alertController.addAction(closeAction)
        present(alertController, animated: true, completion: nil)
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
            if let cell = cell as? AppsServiceAlertCell {
                cell.parentView.backgroundColor = UIColor(red: 247.0 / 255.0, green: 247.0 / 255.0, blue: 250.0 / 255.0, alpha: 1.0)
            } else {
                cell.backgroundColor = UIColor(red: 247.0 / 255.0, green: 247.0 / 255.0, blue: 250.0 / 255.0, alpha: 1.0)
            }
        }
    }
    
    func provideRegionCell(for indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            if useMyCurrentLocationIsInProgress {
                return createLoadingCell(withBottomSeparator: true)
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "AppsServiceAlertCell", for: indexPath) as? AppsServiceAlertCell
            cell?.mainLabel.text = "Use My Current Location"
            cell?.descriptionLabel.text = "Will select office based on your current location"
            cell?.iconImageView.image = UIImage(named: "gps_icon")
            cell?.arrowIcon.isHidden = true
            cell?.separator.isHidden = false
            cell?.mainLabel.accessibilityIdentifier = "OfficeSelectionScreenOfficeCurrentLocationTitleLabel"
            cell?.descriptionLabel.accessibilityIdentifier = "OfficeSelectionScreenOfficeCurrentLocationDescriptionLabel"
            return cell ?? UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "OfficeInfoCell", for: indexPath) as? OfficeInfoCell
        cell?.iconImageView.image = UIImage(named: "region_icon")
        cell?.infoLabel?.text = regionDataSource[indexPath.row].text
        cell?.descriptionLabel.accessibilityIdentifier = "OfficeSelectionScreenOfficeRegionTitleLabel"
        return cell ?? UITableViewCell()
    }
    
    func provideOfficeCell(for indexPath: IndexPath) -> UITableViewCell {
        if let officeIdInProgress = officeIdGoingToBeSelected, officeDataSource[indexPath.row].officeId == officeIdInProgress {
            return createLoadingCell(withBottomSeparator: true, withTopSeparator: indexPath.row == 0)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "OfficeSelectionCell", for: indexPath) as? OfficeSelectionCell
        cell?.mainLabel.text = officeDataSource[indexPath.row].text
        cell?.descriptionLabel.text = officeDataSource[indexPath.row].additionalText?.replacingOccurrences(of: "\u{00A0}", with: " ")
        cell?.iconImageView.image = UIImage(named: "location")
        cell?.separator.isHidden = false
        cell?.topSeparator.isHidden = indexPath.row != 0
        cell?.mainLabel.accessibilityIdentifier = "OfficeSelectionScreenOfficeLocationTitle"
        cell?.descriptionLabel.accessibilityIdentifier = "OfficeSelectionScreenOfficeLocationDescriptionLabel"
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if regionSelectionIsOn {
            if indexPath.row == 0 {
                // "Use My Current Location" option was selected
                guard !useMyCurrentLocationIsInProgress else { return }
                useMyCurrentLocationIsInProgress = true
                let gettingLocationIsAllowed = dataProvider?.getClosestOffice()
                if let isAllowed = gettingLocationIsAllowed, !isAllowed {
                    useMyCurrentLocationIsInProgress = false
                    displayPermissionDeniedAlert()
                    //displayError(errorMessage: "Location permission needed to access your location", title: nil)
                }
            } else {
                showOfficeLocationVC(for: regionDataSource[indexPath.row].text)
            }
        } else {
            guard indexPath.row < officeDataSource.count, let selectedOfficeId = officeDataSource[indexPath.row].officeId else { return }
            guard officeIdGoingToBeSelected == nil else { return }
            officeIdGoingToBeSelected = selectedOfficeId
            setCurrentOffice(officeId: selectedOfficeId, basedOnCurrentLocation: false)
        }
    }
    
    private func showOfficeLocationVC(for regionName: String) {
        let office = OfficeLocationViewController()
        office.forceOfficeSelection = forceOfficeSelection
        //office.officeSelectionDelegate = officeSelectionDelegate
        office.regionSelectionIsOn = false
        office.title = regionName
        office.selectedRegionName = regionName
        office.dataProvider = dataProvider
        self.navigationController?.pushWithFadeAnimationVC(office)
    }
    
    private func setCurrentOffice(officeId: Int, basedOnCurrentLocation: Bool) {
        let officeWasChanged = dataProvider?.userOffice?.officeId != officeId
        guard officeWasChanged else {
            if basedOnCurrentLocation {
                useMyCurrentLocationIsInProgress = false
            } else {
                officeIdGoingToBeSelected = nil
            }
            dismiss(animated: true, completion: nil)
            return
        }
        dataProvider?.setCurrentOffice(officeId: officeId, completion: { [weak self] (errorCode, error) in
            DispatchQueue.main.async {
                if basedOnCurrentLocation {
                    self?.useMyCurrentLocationIsInProgress = false
                } else {
                    self?.officeIdGoingToBeSelected = nil
                }
                if errorCode == 200, error == nil {
                    //self?.officeSelectionDelegate?.officeWasSelected()
                    self?.dismiss(animated: true, completion: nil)
                } else {
                    self?.displayError(errorMessage: "Office Selection Failed", title: nil)
                }
            }
        })
    }
    
}

extension OfficeLocationViewController: UserLocationManagerDelegate {
    func userDeniedToGetHisLocation() {
        guard useMyCurrentLocationIsInProgress else { return }
        useMyCurrentLocationIsInProgress = false
        displayPermissionDeniedAlert()
        //displayError(errorMessage: "Location permission needed to access your location", title: nil)
    }
    
    func closestOfficeWasRetreived(officeCoord: (lat: Float, long: Float)?) {
        guard let officeCoord = officeCoord, let officeId = dataProvider?.getClosestOfficeId(by: officeCoord) else {
            showLocationManagerAlert()
            return
        }
        setCurrentOffice(officeId: officeId, basedOnCurrentLocation: true)
    }
    
    func locationManagerFailed(with error: Error) {
        //TODO: error handling
        showLocationManagerAlert()
    }
    
    private func showLocationManagerAlert() {
        if !forceOfficeSelection {
            useMyCurrentLocationIsInProgress = false
            displayError(errorMessage: "Can't find your location. Please verify location permissions and try again", title: nil)
        }
    }
    
}
