//
//  AboutViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 18.11.2020.
//

import UIKit

class AboutViewController: UIViewController, DetailsDataDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var dataSource: AboutDataSource?
    var appTitle: String?
    var dataProvider: MyAppsDataProvider?
    var details: AppDetailsData?
    var detailsDataResponseError: Error?
    var imageDataResponseError: Error?
    var appImageUrl: String = ""
    private var appImageData: Data?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureDataSource()
        navigationController?.navigationBar.barTintColor = UIColor.white
        dataProvider?.getAppImageData(from: appImageUrl, completion: { (imageData, error) in
            self.imageDataResponseError = error
            self.appImageData = imageData
        })
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        detailsDataResponseError = nil
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func didBecomeActive() {
        tableView.reloadData()
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = "About"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
    }
    
    private func setUpTableView() {
        tableView.rowHeight = UITableView.automaticDimension
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
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    private func createSupportData() -> [SupportData]  {
        var supportData = [SupportData]()
        if let supportPolicy = details?.appSupportPolicy {
            supportData.append(SupportData(title: "Support Policy: \(supportPolicy)", value: supportPolicy))
        }
        if let decription = details?.appDescription {
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
            return 1
        case 1:
            return dataSource?.supportData?.count ?? 1 
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
            if imageDataResponseError == nil, appImageData == nil {
                cell.startAnimation()
            } else if let _ = appImageData, let image = UIImage(data: appImageData!) {
                cell.iconImageView.image = image
                cell.stopAnimation()
            } else {
                cell.showFirstCharFrom(appTitle)
                cell.stopAnimation()
            }
            cell.headerTitleLabel.text = details?.appTitle
            return cell
        }
        
        if indexPath.section == 1, detailsDataResponseError == nil, details == nil  {
            return createLoadingCell()
        } else if indexPath.section == 1, let error = detailsDataResponseError as? ResponseError {
            return createErrorCell(with: error.localizedDescription)
        }
        
        if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "AboutSupportPolicyCell", for: indexPath) as? AboutSupportPolicyCell
                cell?.policyLabel.text = dataSource?.supportData?[indexPath.row].title
                return cell ?? UITableViewCell()
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "AboutInfoCell", for: indexPath) as? AboutInfoCell
                cell?.descriptionLabel.text = dataSource?.supportData?[indexPath.row].title
                return cell ?? UITableViewCell()
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "AboutSupportCell", for: indexPath) as? AboutSupportCell
                cell?.supportNameLabel.text = dataSource?.supportData?[indexPath.row].title
                return cell ?? UITableViewCell()
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1, let supData = dataSource?.supportData, indexPath.row < supData.count, let stringUrl = supData[indexPath.row].value, let url = URL(string: stringUrl) {
            UIApplication.shared.open(url, options: [:]) { (isSuccess) in
                if !isSuccess {
                    self.displayError(errorMessage: "", title: "Invalid link")
                }
            }
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
