//
//  CollaborationViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 09.03.2021.
//

import UIKit

class CollaborationViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private var dataProvider: CollaborationDataProvider = CollaborationDataProvider()
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var errorLabel: UILabel!

    private var headerTitleView: CollaborationHeader = CollaborationHeader.instanceFromNib()
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    private var dataSource: [CollaborationCellData] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setUpHardCodeData()
        self.navigationItem.titleView = headerTitleView
        dataProvider.appSuiteIconDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getCollaborationDetails()
        self.navigationController?.setNavigationBarSeparator(with: UIColor(hex: 0xF2F2F7))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAnimation()
    }
    
    private func startAnimation() {
        self.tableView.alpha = 0
        errorLabel.isHidden = true
        self.navigationController?.addAndCenteredActivityIndicator(activityIndicator)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
    }
    
    private func stopAnimation() {
        if dataProvider.collaborationDetails != nil {
            errorLabel.isHidden = true
            self.tableView.alpha = 1
        }
        self.tableView.reloadData()
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
    
    private func getCollaborationDetails() {
        if dataProvider.collaborationDetails == nil {
            headerTitleView.hideViews()
            startAnimation()
        }
        dataProvider.getCollaborationDetails(appSuite: "Office365") {[weak self] (errorCode, error) in
            DispatchQueue.main.async {
                if error != nil && errorCode != 200 {
                    self?.errorLabel.isHidden = self?.dataProvider.collaborationDetails != nil
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
                self?.setHeaderData()
                self?.stopAnimation()
            }
        }
    }
    
    private func setHeaderData() {
        let data = self.dataProvider.collaborationDetails
        headerTitleView.headerTitle.text = data?.groupName
        headerTitleView.showViews()
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "CollaborationHeaderCell", bundle: nil), forCellReuseIdentifier: "CollaborationHeaderCell")
        tableView.register(UINib(nibName: "HelpDeskCell", bundle: nil), forCellReuseIdentifier: "HelpDeskCell")
        tableView.register(UINib(nibName: "Office365AppCell", bundle: nil), forCellReuseIdentifier: "Office365AppCell")
    }
    
    private func setUpHardCodeData() {
        dataSource.append(CollaborationCellData(cellTitle: dataProvider.collaborationDetails?.description, updatesNumber: nil))
        dataSource.append(CollaborationCellData(imageName: nil, cellTitle: "Office 365 Applications", cellSubtitle: "Create, Collaborate & Connect", updatesNumber: nil, imageStatus: .loading))
        dataSource.append(CollaborationCellData(imageName: "quick_help_icon", cellTitle: "Tips & Tricks", cellSubtitle: "Get the most from the app", updatesNumber: nil))
        dataSource.append(CollaborationCellData(imageName: "contacts_icon", cellTitle: "Team Contacts", cellSubtitle: "Key Contacts and Member Profiles", updatesNumber: nil))
    }
    
    private func showContactsScreen() {
        let contactsScreen = AppContactsViewController()
        contactsScreen.isCollaborationContacts = true
        contactsScreen.appName = "Office365"
        navigationController?.pushViewController(contactsScreen, animated: true)
    }
    
    private func showTipsAndTricksScreen() {
        let quickHelpVC = QuickHelpViewController()
        quickHelpVC.appName = "Office365"
        quickHelpVC.screenType = .collaborationTipsAndTricks
        navigationController?.pushViewController(quickHelpVC, animated: true)
    }
    
    private func showOffice365Screen() {
        let office365 = Office365ViewController()
        office365.appName = "Office365"
        office365.dataProvider = dataProvider
        navigationController?.pushViewController(office365, animated: true)
    }

    private func createAttributedString(for text: String?) -> NSAttributedString? {
        let attributedText = NSMutableAttributedString(string: text ?? "")
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = .left
        if let font = UIFont(name: "SFProText-Light", size: 16.0) {
            attributedText.addAttribute(.font, value: font, range: NSRange(location: 0, length: attributedText.length))
        }
        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
        return attributedText
    }
    
}

extension CollaborationViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == 0 ? UITableView.automaticDimension : 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "CollaborationHeaderCell", for: indexPath) as? CollaborationHeaderCell {
            cell.descriptionLabel.attributedText = createAttributedString(for: dataProvider.collaborationDetails?.description)
            return cell
        }
        if indexPath.row == 1, let cell = tableView.dequeueReusableCell(withIdentifier: "Office365AppCell", for: indexPath) as? Office365AppCell {
            cell.appTitleLabel.text = dataSource[indexPath.row].cellTitle
            cell.descriptionLabel.text = dataSource[indexPath.row].cellSubtitle
            cell.setImage(with: dataSource[indexPath.row].imageData, status: dataSource[indexPath.row].imageStatus)
            return cell
        }
        if let cell = tableView.dequeueReusableCell(withIdentifier: "HelpDeskCell", for: indexPath) as? HelpDeskCell {
            let cellData = dataSource[indexPath.row]
            cell.setUpCell(with: cellData, isActive: true, isNeedCornerRadius: true)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 1:
            showOffice365Screen()
        case 2:
            showTipsAndTricksScreen()
        case 3:
            showContactsScreen()
        default:
            return
        }
    }
}

extension CollaborationViewController: AppSuiteIconDelegate {
    func appSuiteIconChanged(with data: Data?, status: ImageLoadingStatus) {
        DispatchQueue.main.async {
            if let _ = data {
                self.headerTitleView.headerImageView.image = UIImage(data: data!)
            }
            guard self.dataSource.count > 1 else { return }
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? Office365AppCell {
                self.dataSource[1].imageData = data
                self.dataSource[1].imageStatus = status
                cell.setImage(with: data, status: status)
            }
        }
    }
}

struct CollaborationCellData: ContactsCellDataProtocol {
    var imageName: String?
    var cellTitle: String?
    var cellSubtitle: String?
    var updatesNumber: Int?
    var imageData: Data?
    var imageStatus: ImageLoadingStatus = .loading
}
