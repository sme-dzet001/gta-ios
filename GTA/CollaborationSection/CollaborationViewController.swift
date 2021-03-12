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
    @IBOutlet weak var headerTextView: UITextView!
    @IBOutlet weak var headerTypeLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var dataSource: [CollaborationCellData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setUpHardCodeData()
        dataProvider.appSuiteIconDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        getCollaborationDetails()
    }
    
    private func getCollaborationDetails() {
        if dataProvider.collaborationDetails == nil {
            activityIndicator.startAnimating()
            errorLabel.isHidden = true
        }
        dataProvider.getCollaborationDetails(appSuite: "Office365") {[weak self] (errorCode, error) in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                if error == nil && errorCode == 200 {
                    self?.errorLabel.isHidden = true
                    self?.fillData()
                } else {
                    self?.errorLabel.isHidden = self?.dataProvider.collaborationDetails != nil
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
            }
        }
    }
    
    private func fillData() {
        let data = self.dataProvider.collaborationDetails
        self.headerTitleLabel.text = data?.title
        self.headerTextView.attributedText = createAttributedString(for: data?.description)
        self.headerTypeLabel.text = data?.type
    }
    
    private func createAttributedString(for text: String?) -> NSAttributedString? {
        let attributedText = NSMutableAttributedString(string: text ?? "")
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        if let font = UIFont(name: "SFProDisplay-Medium", size: 15.0) {
            attributedText.addAttribute(.font, value: font, range: NSRange(location: 0, length: attributedText.length))
        }
        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
        return attributedText
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80
        tableView.register(UINib(nibName: "HelpDeskCell", bundle: nil), forCellReuseIdentifier: "HelpDeskCell")
    }
    
    private func setUpHardCodeData() {
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
        quickHelpVC.isTipsAndTricks = true
        navigationController?.pushViewController(quickHelpVC, animated: true)
    }

}

extension CollaborationViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "HelpDeskCell", for: indexPath) as? HelpDeskCell {
            let cellData = dataSource[indexPath.row]
            cell.setUpCell(with: cellData, isActive: true, isNeedCornerRadius: true)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            showTipsAndTricksScreen()
        case 1:
            showContactsScreen()
        default:
            return
        }
    }
}

extension CollaborationViewController: AppSuiteIconDelegate {
    func appSuiteIconChanged(with data: Data?) {
        DispatchQueue.main.async {
            if let _ = data {
                self.headerImageView.image = UIImage(data: data!)
            }
        }
    }
}

struct CollaborationCellData: ContactsCellDataProtocol {
    var imageName: String?
    var cellTitle: String?
    var cellSubtitle: String?
    var updatesNumber: Int?
}
