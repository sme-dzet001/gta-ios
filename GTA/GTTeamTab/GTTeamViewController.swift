//
//  GTTeamViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 07.05.2021.
//

import UIKit

class GTTeamViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navBarTitle: UILabel!
    
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private var errorLabel: UILabel = UILabel()
    var dataProvider = GTTeamDataProvider()
    private var appContactsData: GTTeamResponse? {
        return dataProvider.GTTeamContactsData
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        addErrorLabel(errorLabel)
        navigationController?.navigationBar.barTintColor = UIColor.white
        loadContactsData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "AppContactCell", bundle: nil), forCellReuseIdentifier: "AppContactCell")
    }
    
    private func loadContactsData() {
        let contactsDataIsEmpty = appContactsData?.data?.rows == nil || appContactsData?.data?.rows?.count == 0
        if contactsDataIsEmpty {
            startAnimation()
        }
        dataProvider.getGTTeamData(completion: {[weak self] dataWasChanged, errorCode, error in
            DispatchQueue.main.async {
                self?.stopAnimation()
                if error == nil && errorCode == 200 {
                    self?.errorLabel.isHidden = true
                    self?.tableView.alpha = 1
                    if dataWasChanged { self?.tableView.reloadData() }
                } else {
                    let contactsDataIsEmpty = self?.appContactsData?.data?.rows == nil || self?.appContactsData?.data?.rows?.count == 0
                    self?.errorLabel.isHidden = !contactsDataIsEmpty
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
            }
        })
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
    
}

extension GTTeamViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.appContactsData?.data?.rows?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: (tableView.frame.width * 0.133) + 24 ))
        return footer
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let footerHeight = (tableView.frame.width * 0.133) + 24
        return footerHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard (appContactsData?.data?.rows?.count ?? 0) > indexPath.row else { return UITableViewCell() }
        if let cell = tableView.dequeueReusableCell(withIdentifier: "AppContactCell", for: indexPath) as? AppContactCell {
            let data = appContactsData?.contactsData ?? []
            let cellDataSource = data[indexPath.row]
            cell.contactEmail = data[indexPath.row].contactEmail
            cell.setUpCell(with: cellDataSource)
            let imageURL = dataProvider.formImageURL(from: cellDataSource.contactPhotoUrl)
            let url = URL(string: imageURL )
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
