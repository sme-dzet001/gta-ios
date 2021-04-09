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
    //@IBOutlet weak var errorLabel: UILabel!

    private var headerTitleView: CollaborationHeader = CollaborationHeader.instanceFromNib()
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private var errorLabel: UILabel = UILabel()
    
    private var dataSource: [CollaborationCellData] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setUpHardCodeData()
        setUpHeaderView()
        dataProvider.appSuiteIconDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        
        addErrorLabel(errorLabel)
        getCollaborationDetails()
        self.navigationController?.setNavigationBarSeparator(with: UIColor(hex: 0xF2F2F7))
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func startAnimation() {
        self.tableView.alpha = 0
        errorLabel.isHidden = true
        self.addLoadingIndicator(activityIndicator)
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
        headerTitleView.headerSubtitle.text = data?.type
        headerTitleView.showViews()
    }
    
    private func setUpHeaderView() {
        DispatchQueue.main.async {
            let header = self.headerTitleView
            self.headerView.addSubview(header)
            header.pinEdges(to: self.headerView)
        }
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
        dataSource.append(CollaborationCellData(imageName: "applications_icon", cellTitle: "Office 365 Applications", cellSubtitle: "Create, Collaborate & Connect", updatesNumber: nil, imageStatus: .loading))
        dataSource.append(CollaborationCellData(imageName: "usage_metrics_icon", cellTitle: "Usage Metrics", cellSubtitle: "Collaboration Analytics", updatesNumber: nil))
        dataSource.append(CollaborationCellData(imageName: "tips_n_tricks_icon", cellTitle: "Tips & Tricks", cellSubtitle: "Get the most from the app", updatesNumber: nil))
        dataSource.append(CollaborationCellData(imageName: "team_contacts_icon", cellTitle: "Team Contacts", cellSubtitle: "Key Contacts and Member Profiles", updatesNumber: nil))
    }
    
    private func showContactsScreen() {
        let contactsScreen = AppContactsViewController()
        contactsScreen.collaborationDataProvider = dataProvider
        contactsScreen.isCollaborationContacts = true
        contactsScreen.appName = "Office365"
        navigationController?.pushViewController(contactsScreen, animated: true)
    }
    
    private func showTipsAndTricksScreen() {
        let quickHelpVC = QuickHelpViewController()
        quickHelpVC.appName = "Office365"
        quickHelpVC.screenType = .collaborationTipsAndTricks
        quickHelpVC.collaborationDataProvider = dataProvider
        navigationController?.pushViewController(quickHelpVC, animated: true)
    }
    
    private func showUsageMetricsScreen() {
        let usageMetricsVC = UsageMetricsViewController()
        usageMetricsVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(usageMetricsVC, animated: true)
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
            cell.descriptionLabel.text = dataProvider.collaborationDetails?.description//createAttributedString(for: dataProvider.collaborationDetails?.description)
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
            showUsageMetricsScreen()
        case 3:
            showTipsAndTricksScreen()
        case 4:
            showContactsScreen()
        default:
            return
        }
    }
}

extension CollaborationViewController: AppSuiteIconDelegate {
    func appSuiteIconChanged(with data: Data?, status: LoadingStatus) {
        DispatchQueue.main.async {
            if let _ = data {
                self.headerTitleView.headerImageView.image = UIImage(data: data!)
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
    var imageStatus: LoadingStatus = .loading
}
