//
//  AppContactsViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 10.02.2021.
//

import UIKit

class AppContactsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    //@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    var dataProvider: MyAppsDataProvider?
    private var lastUpdateDate: Date?
    private var appContactsData: AppContactsData?
    var appName: String? = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barTintColor = UIColor.white
        if lastUpdateDate == nil || Date() >= lastUpdateDate ?? Date() {
            loadContactsData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAnimation()
    }

    private func setUpNavigationItem() {
        navigationItem.title = "Contacts"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
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
        dataProvider.getAppContactsData(for: appName) { [weak self] (contactsData, errorCode, error) in
            DispatchQueue.main.async {
                self?.stopAnimation()
                if error == nil && errorCode == 200 {
                    self?.lastUpdateDate = Date().addingTimeInterval(60)
                    self?.appContactsData = contactsData
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
        self.navigationController?.addAndCenteredActivityIndicator(activityIndicator)
        activityIndicator.hidesWhenStopped = true
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
            if let imageURL = dataProvider?.formContactImageURL(from: cellDataSource.contactPhotoUrl), let url = URL(string: imageURL) {
                cell.activityIndicator.startAnimating()
                cell.imageUrl = imageURL
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
                cell.photoImageView.image = UIImage(named: "contact_default_photo")
            }
            return cell
        }
        return UITableViewCell()
    }
    
}

struct ContactData {
    var contactPhotoUrl: String?
    var contactName: String?
    var contactEmail: String?
    var contactPosition: String?
    var contactLocation: String?
    var contactBio: String?
    var contactFunFact: String?
}
