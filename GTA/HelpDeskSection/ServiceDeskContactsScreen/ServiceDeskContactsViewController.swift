//
//  ServiceDeskContactsViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 01.12.2020.
//

import UIKit

class ServiceDeskContactsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    //@IBOutlet weak var errorLabel: UILabel!
    
    private var errorLabel: UILabel = UILabel()
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    var dataProvider: HelpDeskDataProvider?
    private var lastUpdateDate: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addErrorLabel(errorLabel, isGSD: true)
        if lastUpdateDate == nil || Date() >= lastUpdateDate ?? Date() {
            loadContactsData()
        }
    }
    
    private func setUpNavigationItem() {
        let tlabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        tlabel.text = "Service Desk Contacts"
        tlabel.textColor = UIColor.black
        tlabel.textAlignment = .center
        tlabel.font = UIFont(name: "SFProDisplay-Medium", size: 20.0)
        tlabel.backgroundColor = UIColor.clear
        tlabel.minimumScaleFactor = 0.6
        tlabel.numberOfLines = 2
        tlabel.adjustsFontSizeToFitWidth = true
        self.navigationItem.titleView = tlabel
        self.navigationItem.titleView?.accessibilityIdentifier = "ServiceDeskContactsTitleLabel"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
        navigationItem.leftBarButtonItem?.customView?.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        navigationItem.leftBarButtonItem?.accessibilityIdentifier = "ServiceDeskContactsBackButton"
    }
    
    private func setUpTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "ServiceDeskContactCell", bundle: nil), forCellReuseIdentifier: "ServiceDeskContactCell")
        tableView.accessibilityIdentifier = "ServiceDeskContactsTableView"
    }
    
    private func loadContactsData() {
        guard let dataProvider = dataProvider else { return }
        if dataProvider.teamContactsDataIsEmpty {
            startAnimation()
        }
        dataProvider.getTeamContactsData { [weak self] (dataWasChanged, errorCode, error, fromCache) in
            DispatchQueue.main.async {
                self?.stopAnimation()
                if error == nil && errorCode == 200 {
                    self?.lastUpdateDate = !fromCache ? Date().addingTimeInterval(60) : self?.lastUpdateDate
                    self?.errorLabel.isHidden = true
                    self?.tableView.isHidden = false
                    if dataWasChanged { self?.tableView.reloadData() }
                } else {
                    self?.errorLabel.isHidden = !dataProvider.teamContactsDataIsEmpty
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
            }
        }
    }
    
    private func startAnimation() {
        self.addLoadingIndicator(activityIndicator, isGSD: true)
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

extension ServiceDeskContactsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataProvider?.teamContactsData.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: (tableView.frame.width * 0.15) + 24 ))
        return footer
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let footerHeight = (tableView.frame.width * 0.15) + 24
        return footerHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ServiceDeskContactCell", for: indexPath) as? ServiceDeskContactCell {
            let data = dataProvider?.teamContactsData ?? []
            let cellDataSource = data[indexPath.row]
            cell.contactEmail = data[indexPath.row].contactEmail
            cell.setUpCell(with: cellDataSource)
            let imageURL = dataProvider?.formImageURL(from: cellDataSource.contactPhotoUrl) ?? ""
            let url = URL(string: imageURL)
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
    
}
