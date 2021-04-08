//
//  AppContactsViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 10.02.2021.
//

import UIKit

class AppContactsViewController: UIViewController {
    
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
            return dataProvider?.appContactsData
        }
    }
    var appName: String = ""
    var isCollaborationContacts = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addErrorLabel(errorLabel)
        navigationController?.navigationBar.barTintColor = UIColor.white
        if isCollaborationContacts {
            loadCollaborationContactsData()
            return
        }
        if lastUpdateDate == nil || Date() >= lastUpdateDate ?? Date() {
            loadContactsData()
        }
    }
    
    private func setUpNavigationItem() {
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
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(self.backPressed))
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
        dataProvider.getAppContactsData(for: appName) { [weak self] (errorCode, error, fromCache) in
            DispatchQueue.main.async {
                self?.stopAnimation()
                if error == nil && errorCode == 200 {
                    self?.lastUpdateDate = !fromCache ? Date().addingTimeInterval(60) : self?.lastUpdateDate
                    //self?.appContactsData = contactsData
                    self?.errorLabel.isHidden = true
                    self?.tableView.isHidden = false
                    self?.tableView.reloadData()
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
        collaborationDataProvider.getTeamContacts(appSuite: appName) {[weak self] (errorCode, error) in
            DispatchQueue.main.async {
                self?.stopAnimation()
                if error == nil && errorCode == 200 {
                    //self?.appContactsData = contactsData
                    self?.errorLabel.isHidden = true
                    self?.tableView.isHidden = false
                    self?.tableView.reloadData()
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
        tableView.isHidden = true
    }
    
    private func stopAnimation() {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
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
            let imageURL = isCollaborationContacts ? collaborationDataProvider?.formImageURL(from: cellDataSource.contactPhotoUrl) : dataProvider?.formContactImageURL(from: cellDataSource.contactPhotoUrl)
            if let _ = imageURL, let url = URL(string: imageURL!) {
                cell.activityIndicator.startAnimating()
                cell.imageUrl = imageURL
                if !isCollaborationContacts {
                    dataProvider?.getContactImageData(from: url) { (data, error) in
                        if cell.imageUrl != imageURL { return }
                        cell.activityIndicator.stopAnimating()
                        if let imageData = data, error == nil {
                            let image = UIImage(data: imageData)
                            cell.photoImageView.image = image
                        } else {
                            cell.photoImageView.image = UIImage(named: "contact_default_photo")
                        }
                    }
                } else {
                    collaborationDataProvider?.getAppImageData(from: cellDataSource.contactPhotoUrl) { (data, error) in
                        if cell.imageUrl != imageURL { return }
                        cell.activityIndicator.stopAnimating()
                        if let imageData = data, error == nil {
                            let image = UIImage(data: imageData)
                            cell.photoImageView.image = image
                        } else {
                            cell.photoImageView.image = UIImage(named: "contact_default_photo")
                        }
                    }
                }
            } else {
                cell.photoImageView.image = UIImage(named: "contact_default_photo")
            }
            return cell
        }
        return UITableViewCell()
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
