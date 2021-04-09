//
//  Office365ViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 13.03.2021.
//

import UIKit

class Office365ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    //@IBOutlet weak var errorLabel: UILabel!
    
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private var errorLabel: UILabel = UILabel()
    
    var dataProvider: CollaborationDataProvider?
    var appName: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setUpNavigationItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addErrorLabel(errorLabel)
        getAppSuiteDetails()
        dataProvider?.imageLoadingDelegate = self
    }
    
    private func setUpNavigationItem() {
        let tlabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        tlabel.text = "Office 365 Applications"
        tlabel.textColor = UIColor.black
        tlabel.textAlignment = .center
        tlabel.font = UIFont(name: "SFProDisplay-Medium", size: 20.0)
        tlabel.backgroundColor = UIColor.clear
        tlabel.minimumScaleFactor = 0.6
        tlabel.adjustsFontSizeToFitWidth = true
        self.navigationItem.titleView = tlabel
        self.navigationItem.title = appName
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(self.backPressed))
    }
    
    private func startAnimation() {
        self.tableView.alpha = 0
        errorLabel.isHidden = true
        self.addLoadingIndicator(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    private func stopAnimation() {
        if dataProvider?.collaborationAppDetailsRows != nil {
            errorLabel.isHidden = true
            self.tableView.alpha = 1
        }
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
    
    private func getAppSuiteDetails() {
        if dataProvider?.collaborationAppDetailsRows == nil {
            startAnimation()
        }
        dataProvider?.getAppDetails(appSuite: appName) {[weak self] (dataWasChanged, errorCode, error) in
            DispatchQueue.main.async {
                if error != nil || errorCode != 200 {
                    self?.errorLabel.isHidden = self?.dataProvider?.collaborationAppDetailsRows != nil
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
                if dataWasChanged { self?.tableView.reloadData() }
                self?.stopAnimation()
            }
        }
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80
        tableView.register(UINib(nibName: "Office365AppCell", bundle: nil), forCellReuseIdentifier: "Office365AppCell")
    }
    
    private func showAppDetailsScreen(with details: CollaborationAppDetailsRow) {
        let aboutScreen = AboutViewController()
        aboutScreen.isCollaborationDetails = true
        aboutScreen.collaborationDetails = details
        aboutScreen.collaborationDataProvider = dataProvider
        aboutScreen.appTitle = details.fullTitle
        aboutScreen.appImageUrl = details.imageUrl ?? ""
        navigationController?.pushViewController(aboutScreen, animated: true)
    }
    
    @objc private func backPressed() {
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension Office365ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = dataProvider?.collaborationAppDetailsRows?.count {
            return count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "Office365AppCell", for: indexPath) as? Office365AppCell {
            guard let cellData = dataProvider?.collaborationAppDetailsRows else { return cell }
            cell.setUpCell(with: cellData[indexPath.row], isAppsScreen: true)
            if let imageURL = dataProvider?.formImageURL(from: cellData[indexPath.row].imageUrl), let _ = URL(string: imageURL) {
                cell.activityIndicator.startAnimating()
                cell.imageUrl = imageURL
                dataProvider?.getAppImageData(from: cellData[indexPath.row].imageUrl) { (data, error) in
                    if cell.imageUrl != imageURL { return }
                    cell.activityIndicator.stopAnimating()
                    if let imageData = data, error == nil {
                        let image = UIImage(data: imageData)
                        cell.iconImageView.image = image
                    } else {
                        cell.iconImageView.image = nil// UIImage(named: "contact_default_photo")
                    }
                }
            } else {
                cell.iconImageView.image = nil// UIImage(named: "contact_default_photo")
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let detailsRows = dataProvider?.collaborationAppDetailsRows, indexPath.row < detailsRows.count else { return }
        showAppDetailsScreen(with: detailsRows[indexPath.row])
    }
}

extension Office365ViewController: ImageLoadingDelegate {

    func setImage(for app: String) {
        DispatchQueue.main.async {
            let rowIndex = self.dataProvider?.collaborationAppDetailsRows?.firstIndex(where: {$0.fullTitle == app})
            guard let _ = rowIndex else { return }
            if let cell = self.tableView.cellForRow(at: IndexPath(row: rowIndex!, section: 0)) as? Office365AppCell, let cellData = self.dataProvider?.collaborationAppDetailsRows?[rowIndex!] {
                cell.setUpCell(with: cellData)
            }
        }
    }
}

