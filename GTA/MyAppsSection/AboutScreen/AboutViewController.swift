//
//  AboutViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 18.11.2020.
//

import UIKit

class AboutViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    private var dataSource: AboutDataSource?
    private var lastUpdateDate: Date?
    var appName: String? = ""
    var appContactsData: AppContactsData?
    var dataProvider: MyAppsDataProvider?
    var details: AppDetailsData?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setHardCodeData()
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barTintColor = UIColor.white
        if lastUpdateDate == nil || Date() >= lastUpdateDate ?? Date() {
            getAppContactsData()
        }
    }
    
    private func getAppContactsData() {
        dataProvider?.getAppContactsData(for: appName) { [weak self] (contactsData, _, error) in
            self?.appContactsData = contactsData
            self?.lastUpdateDate = Date().addingTimeInterval(60)
            self?.dataSource?.contactsData = self?.appContactsData?.contactsData ?? []
            self?.stopAnimation()
        }
    }
    
    private func startAnimation() {
        guard appContactsData == nil else { return }
        self.tableView.alpha = 0
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.view.addSubview(self.activityIndicator)
        self.activityIndicator.center = CGPoint(x: view.frame.size.width  / 2,
                                                y: view.frame.size.height / 2)
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.startAnimating()
    }
    
    private func stopAnimation() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.alpha = 1
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
        }
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = "About"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
    }
    
    private func setUpTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "AboutInfoCell", bundle: nil), forCellReuseIdentifier: "AboutInfoCell")
        tableView.register(UINib(nibName: "AboutContactsCell", bundle: nil), forCellReuseIdentifier: "AboutContactsCell")
        tableView.register(UINib(nibName: "AboutSupportCell", bundle: nil), forCellReuseIdentifier: "AboutSupportCell")
    }
    
    private func setHardCodeData() {
        dataSource = AboutDataSource(description: [DescriptionData(text: details?.appDescription)], contactsData: [ContactData(contactName: "Jane Cooper", contactPosition: "Administrator", phoneNumber: "(480) 555-0103", email: "janecooper@mail.com"), ContactData(contactName: "Marvin McKinney", contactPosition: "Administrator", phoneNumber: "(480) 555-0103", email: "marvinmckinney@mail.com")])
        let supportData = createSupportDataString()
        if supportData.string.count > 0 {
            dataSource?.supportData = [SupportData(text: supportData)]
        }
    }
    
    private func createSupportDataString() -> NSMutableAttributedString  {
        let resultString = NSMutableAttributedString()
        if let wikiUrlString = details?.appWikiUrl, let url = URL(string: wikiUrlString) {
            let stringValue = "Wiki Url: "
            let attrString = NSMutableAttributedString(string: stringValue + "\(wikiUrlString)")
            attrString.setAttributes([.link: url], range: NSMakeRange(stringValue.count, wikiUrlString.count))
            resultString.append(attrString)
        }
        if let supportUrlString = details?.appJiraSupportUrl, let url = URL(string: supportUrlString) {
            var stringValue = "Jira Support URL: "
            if !resultString.string.isEmpty {
                stringValue = "\n" + stringValue
            }
            let attrString = NSMutableAttributedString(string: stringValue + "\(supportUrlString)")
            attrString.setAttributes([.link: url], range: NSMakeRange(stringValue.count, supportUrlString.count))
            resultString.append(attrString)
        }
        if let supportPolicy = details?.appSupportPolicy {
            var stringValue = "Support Policy: "
            if !resultString.string.isEmpty {
                stringValue = "\n" + stringValue
            }
            resultString.append(NSMutableAttributedString(string: stringValue + " \(supportPolicy)"))
        }
        return resultString
    }
    
    @objc private func backPressed() {
        self.navigationController?.popViewController(animated: true)
    }

}

extension AboutViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return dataSource?.description.count ?? 0
        case 1:
            return dataSource?.supportData?.count ?? dataSource?.contactsData.count ?? 0
        default:
            return dataSource?.contactsData.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 1))
            view.backgroundColor = UIColor(red: 234.0 / 255.0, green: 236.0 / 255.0, blue: 239.0 / 255.0, alpha: 1.0)
            return view
        }
        guard section == 2 else { return nil }
        let header = AboutContactsHeader.instanceFromNib()
        header.headerTitleLabel.text = "Contacts"
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 1:
            return 1
        case 2:
            return 69
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "AboutInfoCell", for: indexPath) as? AboutInfoCell {
            let cellDataSource = dataSource?.description[indexPath.row]
            cell.setUpCell(with: cellDataSource?.text)
            return cell
        }
        if indexPath.section == 1, let cell = tableView.dequeueReusableCell(withIdentifier: "AboutSupportCell", for: indexPath) as? AboutSupportCell {
            let cellDataSource = dataSource?.supportData?[indexPath.row]
            cell.setUpCell(with: cellDataSource?.text)
            return cell
        }
        if let cell = tableView.dequeueReusableCell(withIdentifier: "AboutContactsCell", for: indexPath) as? AboutContactsCell {
            let cellDataSource = dataSource?.contactsData[indexPath.row]
            cell.setUpCell(with: cellDataSource)
            return cell
        }
        return UITableViewCell()
    }
}

struct AboutDataSource {
    var description: [DescriptionData]
    var supportData: [SupportData]? = nil
    var contactsData: [ContactData]
}

struct DescriptionData {
    var text: String?
}

struct SupportData {
    var text: NSMutableAttributedString?
}

struct ContactData {
    var contactName: String?
    var contactPosition: String?
    var phoneNumber: String?
    var email: String?
}
