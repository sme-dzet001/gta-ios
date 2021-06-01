//
//  AppContactsViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 10.02.2021.
//

import UIKit

class AppContactsViewController: UIViewController {
    
    @IBOutlet weak var navBarView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private var errorLabel: UILabel = UILabel()
    var dataProvider: MyAppsDataProvider?
    var collaborationDataProvider: CollaborationDataProvider?
    private var lastUpdateDate: Date?
    private var appContactsData: AppContactsData? {
        if isCollaborationContacts {
            return collaborationDataProvider?.appContactsData
        } else {
            return dataProvider?.appContactsData[appName] ?? nil
        }
    }
    var appName: String = ""
    var isCollaborationContacts = false

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.accessibilityIdentifier = "AppContactsTableView"
        setUpNavigationItem()
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navBarView.isHidden = isCollaborationContacts
        addErrorLabel(errorLabel, isGSD: !isCollaborationContacts)
        if !isCollaborationContacts {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        }
        navigationController?.navigationBar.barTintColor = UIColor.white
        if isCollaborationContacts {
            loadCollaborationContactsData()
            return
        }
        if lastUpdateDate == nil || Date() >= lastUpdateDate ?? Date() {
            loadContactsData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    private func setUpNavigationItem() {
        if !isCollaborationContacts {
            titleLabel.text = appName
            subtitleLabel.text = "Contacts"
            titleLabel.accessibilityIdentifier = "AppContactsMainTitle"
            subtitleLabel.accessibilityIdentifier = "AppContactsSubTitle"
            return
        }
        let tlabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        let titleText = !isCollaborationContacts ? "\(appName)\nContacts" : "Team Contacts"
        tlabel.text = titleText
        tlabel.textColor = UIColor.black
        tlabel.textAlignment = .center
        tlabel.font = UIFont(name: "SFProDisplay-Medium", size: 20.0)
        tlabel.backgroundColor = UIColor.clear
        tlabel.minimumScaleFactor = 0.6
        tlabel.numberOfLines = 2
        tlabel.adjustsFontSizeToFitWidth = true
        self.navigationItem.titleView = tlabel
        self.navigationItem.titleView?.accessibilityIdentifier = "AppContactsTitle"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(self.backPressed))
        self.navigationItem.leftBarButtonItem?.accessibilityIdentifier = "AppContactsBackButton"
    }
    
    private func setUpTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "AppContactCell", bundle: nil), forCellReuseIdentifier: "AppContactCell")
    }
    
    private func loadContactsData() {
        guard let dataProvider = dataProvider else { return }
        let contactsDataIsEmpty = appContactsData?.contactsData == nil || appContactsData?.contactsData?.count == 0
        if contactsDataIsEmpty {
            startAnimation()
        }
        dataProvider.getAppContactsData(for: appName) { [weak self] (dataWasChanged, errorCode, error, fromCache) in
            DispatchQueue.main.async {
                self?.stopAnimation()
                if error == nil && errorCode == 200 {
                    self?.lastUpdateDate = !fromCache ? Date().addingTimeInterval(60) : self?.lastUpdateDate
                    //self?.appContactsData = contactsData
                    self?.errorLabel.isHidden = true
                    self?.tableView.alpha = 1
                    if dataWasChanged { self?.tableView.reloadData() }
                } else {
                    let contactsDataIsEmpty = self?.appContactsData?.contactsData == nil || self?.appContactsData?.contactsData?.count == 0
                    self?.errorLabel.isHidden = !contactsDataIsEmpty
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
            }
        }
    }
    
    private func loadCollaborationContactsData() {
        guard let collaborationDataProvider = collaborationDataProvider else { return }
        let contactsDataIsEmpty = appContactsData?.contactsData == nil || appContactsData?.contactsData?.count == 0
        if contactsDataIsEmpty {
            startAnimation()
        }
        collaborationDataProvider.getTeamContacts(appSuite: appName) {[weak self] (dataWasChanged, errorCode, error) in
            DispatchQueue.main.async {
                self?.stopAnimation()
                if error == nil && errorCode == 200 {
                    //self?.appContactsData = contactsData
                    self?.errorLabel.isHidden = true
                    self?.tableView.alpha = 1
                    if dataWasChanged { self?.tableView.reloadData() }
                } else {
                    let contactsDataIsEmpty = self?.appContactsData?.contactsData == nil || self?.appContactsData?.contactsData?.count == 0
                    self?.errorLabel.isHidden = !contactsDataIsEmpty
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
            }
        }
    }
    
    private func startAnimation() {
        self.addLoadingIndicator(activityIndicator)
        activityIndicator.startAnimating()
        errorLabel.isHidden = true
        tableView.alpha = 0
    }
    
    private func stopAnimation() {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        backPressed()
    }
    
    @objc private func backPressed() {
        navigationController?.popViewController(animated: true)
    }
}

extension AppContactsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appContactsData?.contactsData?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "AppContactCell", for: indexPath) as? AppContactCell {
            let data = appContactsData?.contactsData ?? []
            let cellDataSource = data[indexPath.row]
            cell.contactEmail = data[indexPath.row].contactEmail
            cell.setUpCell(with: cellDataSource)
            setAccessibilityIdentifiers(for: cell)
            let imageURL = isCollaborationContacts ? collaborationDataProvider?.formImageURL(from: cellDataSource.contactPhotoUrl) : dataProvider?.formImageURL(from: cellDataSource.contactPhotoUrl)
            let url = URL(string: imageURL ?? "")
            cell.photoImageView.kf.indicatorType = .activity
            cell.photoImageView.kf.setImage(with: url, placeholder: nil, options: nil, completionHandler: { (result) in
                switch result {
                case .success(let resData):
                    cell.photoImageView.image = resData.image
                case .failure(let error):
                    if !error.isNotCurrentTask {
                        cell.photoImageView.image = UIImage(named: "contact_default_photo")
                    }
                }
            })
            return cell
        }
        return UITableViewCell()
    }
    
    private func setAccessibilityIdentifiers(for cell: AppContactCell) {
        cell.positionLabel.accessibilityIdentifier = "AppContactDescriptionLabel"
        cell.descriptionLabel.accessibilityIdentifier = "AppContactPhotoImageView"
        cell.contactNameLabel.accessibilityIdentifier = "AppContactTitleLabel"
        cell.emailLabel.accessibilityIdentifier = "AppContactEmailLabel"
        cell.photoImageView.accessibilityIdentifier = "AppContactPhotoImageView"
        cell.locationLabel.accessibilityIdentifier = "AppContactLocationLabel"
        cell.funFactLabel.accessibilityIdentifier = "AppContactFunFactLabel"
    }
    
}

struct ContactData: Equatable {
    var contactPhotoUrl: String?
    var contactName: String?
    var contactEmail: String?
    var contactPosition: String?
    var contactLocation: String?
    var contactBio: String?
    var contactFunFact: String?
    
    static func == (lhs: ContactData, rhs: ContactData) -> Bool {
        return lhs.contactName == rhs.contactName && lhs.contactEmail == rhs.contactEmail && lhs.contactPhotoUrl == rhs.contactPhotoUrl && lhs.contactPosition == rhs.contactPosition && lhs.contactBio == rhs.contactBio
    }
    
}
