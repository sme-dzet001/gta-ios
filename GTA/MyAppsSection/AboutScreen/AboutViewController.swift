//
//  AboutViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 18.11.2020.
//

import UIKit

class AboutViewController: UIViewController, DetailsDataDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerSeparator: UIView!
    
    private var dataSource: AboutDataSource?
    var appTitle: String?
    var details: AppDetailsData?
    var detailsDataResponseError: Error?
    var imageDataResponseError: Error?
    var appImageUrl: String = ""
    var isCollaborationDetails: Bool = false
    var collaborationDetails: CollaborationAppDetailsRow?
    private var appImageData: Data?
    private var errorLabel: UILabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.accessibilityIdentifier = "AppAboutTableView"
        setUpNavigationItem()
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addErrorLabel(errorLabel)
        if let _ = self.details {
            self.errorLabel.isHidden = true
        } else {
            self.errorLabel.isHidden = detailsDataResponseError == nil
        }
        self.errorLabel.text = (detailsDataResponseError as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
        configureDataSource()
        navigationController?.navigationBar.barTintColor = UIColor.white
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func didBecomeActive() {
        tableView.reloadData()
    }
    
    private func setUpNavigationItem() {
        let tlabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        tlabel.text = "About"
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
        navigationItem.leftBarButtonItem?.accessibilityIdentifier = "AppAboutBackButton"
        if #available(iOS 15.0, *) {
            headerSeparator.isHidden = false
        }
    }
    
    private func setUpTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset = tableView.menuButtonContentInset
        tableView.register(UINib(nibName: "AboutInfoCell", bundle: nil), forCellReuseIdentifier: "AboutInfoCell")
        tableView.register(UINib(nibName: "AboutSupportCell", bundle: nil), forCellReuseIdentifier: "AboutSupportCell")
        tableView.register(UINib(nibName: "AboutSupportPolicyCell", bundle: nil), forCellReuseIdentifier: "AboutSupportPolicyCell")
        tableView.register(UINib(nibName: "AboutHeaderCell", bundle: nil), forCellReuseIdentifier: "AboutHeaderCell")
    }
    
    private func configureDataSource() {
        dataSource = AboutDataSource()
        let supportData = createSupportData()
        if !supportData.isEmpty {
            dataSource?.supportData = supportData
        }
    }
    
    func detailsDataUpdated(detailsData: AppDetailsData?, error: Error?) {
        detailsDataResponseError = error
        details = detailsData
        configureDataSource()
        DispatchQueue.main.async { [weak self] in
            if let _ = self?.details {
                self?.errorLabel.isHidden = true
            } else {
                self?.errorLabel.isHidden = error == nil
            }
            self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
            self?.tableView.reloadData()
        }
    }
    
    private func createSupportData() -> [SupportData]  {
        var supportData = [SupportData]()
        if let supportPolicy = !isCollaborationDetails ? details?.appSupportPolicy : collaborationDetails?.appSupportPolicy {
            supportData.append(SupportData(title: "Support Policy: \(supportPolicy)", value: supportPolicy))
        }
        if let decription = !isCollaborationDetails ? details?.appDescription : collaborationDetails?.description {
            supportData.append(SupportData(title: decription, value: decription))
        }
        if let wikiUrlString = details?.appWikiUrl, let _ = URL(string: wikiUrlString) {
            supportData.append(SupportData(title: "Wiki URL", value: wikiUrlString))
        }
        if let supportUrlString = details?.appJiraSupportUrl, let _ = URL(string: supportUrlString) {
            supportData.append(SupportData(title: "Support URL", value: supportUrlString))
        }
        return supportData
    }
    
    @objc private func backPressed() {
        self.navigationController?.popViewController(animated: true)
    }

}

extension AboutViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return detailsDataResponseError != nil && details == nil ? 0 : 1
        case 1:
            return dataSource?.supportData?.count ?? 0
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 1))
            view.backgroundColor = UIColor(red: 234.0 / 255.0, green: 236.0 / 255.0, blue: 239.0 / 255.0, alpha: 1.0)
            return view
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "AboutHeaderCell", for: indexPath) as? AboutHeaderCell {
            let urlString = details?.appFullPath ?? appImageUrl
            let url = URL(string: urlString)
            cell.iconImageView.kf.indicatorType = .activity
            cell.iconImageView.kf.setImage(with: url, placeholder: nil, options: nil, completionHandler: { (result) in
                switch result {
                case .success(let resData):
                    cell.iconImageView.image = resData.image
                case .failure(let error):
                    if !error.isNotCurrentTask {
                        cell.iconImageView.image = UIImage(named: "empty_app_icon")
                        cell.showFirstCharFrom(self.appTitle)
                    }
                }
            })
            cell.headerTitleLabel.text = !isCollaborationDetails ? details?.appTitle : collaborationDetails?.fullTitle
            cell.headerTitleLabel.accessibilityIdentifier = "AppAboutAppTitle"
            return cell
        }
        let isDetailsNull = !isCollaborationDetails ? self.details == nil : collaborationDetails == nil
        if indexPath.section == 1, detailsDataResponseError == nil, isDetailsNull  {
            return createLoadingCell()
        } else if indexPath.section == 1, let error = detailsDataResponseError as? ResponseError, isDetailsNull {
            return createErrorCell(with: error.localizedDescription)
        }
        
        if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "AboutSupportPolicyCell", for: indexPath) as? AboutSupportPolicyCell
                cell?.policyLabel.text = dataSource?.supportData?[indexPath.row].title
                cell?.policyLabel.accessibilityIdentifier = "AppAboutSupportPolicyLabel"
                return cell ?? UITableViewCell()
            case 1:
                let isDescriptionNull = !isCollaborationDetails ? details?.appDescription == nil : collaborationDetails?.description == nil
                if isDescriptionNull {
                    return createSupportCell(for: indexPath)
                }
                let cell = tableView.dequeueReusableCell(withIdentifier: "AboutInfoCell", for: indexPath) as? AboutInfoCell
                cell?.descriptionLabel.text = dataSource?.supportData?[indexPath.row].title
                cell?.descriptionLabel.accessibilityIdentifier = "AppAboutDescriptionLabel"
                return cell ?? UITableViewCell()
            default:
                return createSupportCell(for: indexPath)
            }
        }
        return UITableViewCell()
    }
    
    private func createSupportCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AboutSupportCell", for: indexPath) as? AboutSupportCell
        cell?.supportNameLabel.text = dataSource?.supportData?[indexPath.row].title
        cell?.supportNameLabel.accessibilityIdentifier = "AppAboutSupportNameLabel\(indexPath.row)"
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1, let supData = dataSource?.supportData, indexPath.row < supData.count, let stringUrl = supData[indexPath.row].value {
            openUrl(stringUrl) {[weak self] (isSuccess) in
                if !isSuccess {
                    self?.openUrl(self?.collaborationDetails?.productPageUrl ?? "")
                }
            }
        }
    }
    
    private func openUrl(_ url: String, completion: ((Bool) -> Void)? = nil) {
        guard let url = URL(string: url) else { return }
        UIApplication.shared.open(url, options: [:]) { (isSuccess) in
            completion?(isSuccess)
        }
    }
    
}

struct AboutDataSource {
    var supportData: [SupportData]? = nil
}

struct SupportData {
    var title: String?
    var value: String?
}
