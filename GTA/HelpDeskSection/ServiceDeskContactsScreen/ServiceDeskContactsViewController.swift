//
//  ServiceDeskContactsViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 01.12.2020.
//

import UIKit

class ServiceDeskContactsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    
    var dataProvider: HelpDeskDataProvider?
    private var lastUpdateDate: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if lastUpdateDate == nil || Date() >= lastUpdateDate ?? Date() {
            loadContactsData()
        }
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = "Service Desk Contacts"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
        navigationItem.leftBarButtonItem?.customView?.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
    }
    
    private func setUpTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "ServiceDeskContactCell", bundle: nil), forCellReuseIdentifier: "ServiceDeskContactCell")
    }
    
    private func loadContactsData() {
        guard let dataProvider = dataProvider else { return }
        if dataProvider.teamContactsDataIsEmpty {
            activityIndicator.startAnimating()
            errorLabel.isHidden = true
            tableView.isHidden = true
        }
        dataProvider.getTeamContactsData { [weak self] (errorCode, error) in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                if error == nil && errorCode == 200 {
                    self?.lastUpdateDate = Date().addingTimeInterval(60)
                    self?.errorLabel.isHidden = true
                    self?.tableView.isHidden = false
                    self?.tableView.reloadData()
                } else {
                    self?.errorLabel.isHidden = !dataProvider.teamContactsDataIsEmpty
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
            }
        }
    }
    
    @objc private func backPressed() {
        navigationController?.popViewController(animated: true)
    }

}

extension ServiceDeskContactsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataProvider?.teamContactsData.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ServiceDeskContactCell", for: indexPath) as? ServiceDeskContactCell {
            let data = dataProvider?.teamContactsData ?? []
            let cellDataSource = data[indexPath.row]
            cell.contactEmail = data[indexPath.row].contactEmail
            cell.setUpCell(with: cellDataSource)
            if let imageURL = dataProvider?.formImageURL(from: cellDataSource.contactPhotoUrl), let url = URL(string: imageURL) {
                cell.imageUrl = imageURL
                dataProvider?.getContactImageData(from: url) { (data, error) in
                    if cell.imageUrl != imageURL { return }
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
