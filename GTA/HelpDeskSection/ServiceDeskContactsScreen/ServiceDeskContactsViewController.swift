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
    
    var dataProvider: HelpDeskDataProvider?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadContactsData()
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = "Service Desk Contacts"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
    }
    
    private func setUpTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "ServiceDeskContactCell", bundle: nil), forCellReuseIdentifier: "ServiceDeskContactCell")
    }
    
    private func loadContactsData() {
        guard let dataProvider = dataProvider else { return }
        if dataProvider.teamContactsDataIsEmpty {
            activityIndicator.startAnimating()
            tableView.isHidden = true
        }
        dataProvider.getTeamContactsData { [weak self] (errorCode, error) in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                if error == nil && errorCode == 200 {
                    self?.tableView.isHidden = false
                    self?.tableView.reloadData()
                } else {
                    self?.displayError(errorMessage: "Error was happened!")
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
            cell.setUpCell(with: cellDataSource)
            if let imageURL = dataProvider?.formImageURL(from: cellDataSource.contactPhotoUrl), let url = URL(string: imageURL) {
                cell.imageUrl = imageURL
                dataProvider?.getContactImageData(from: url) { (data, error) in
                    if cell.imageUrl != imageURL { return }
                    if let imageData = data, error == nil {
                        let image = UIImage(data: imageData)
                        cell.photoImageView.image = image
                    }
                }
            }
            return cell
        }
        return UITableViewCell()
    }
    
}
