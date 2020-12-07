//
//  InfoViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 18.11.2020.
//

import UIKit

class InfoViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var officeStatusLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var screenTitleLabel: UILabel!
    @IBOutlet weak var updateTitleLabel: UILabel!
    
    var dataProvider: HomeDataProvider?
    
    var infoType: infoType = .info
    var officeDataSoure: [Hardcode] = []
    var specialAlertData: SpecialAlertRow?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        officeDataSoure = [Hardcode(imageName: "phone_icon", text: "(480) 555-0103"), Hardcode(imageName: "email_icon", text: "deanna.curtis@example.com"), Hardcode(imageName: "location", text: "9 Derry Street, London, W8 5HY, United Kindom"), Hardcode(imageName: "desk_finder", text: "Sony Offices", additionalText: "Select a Sony location to see current status")]
        setUpTableView()
        setupHeaderImageView()
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        officeStatusLabel.isHidden = infoType != .office
        officeStatusLabel.layer.cornerRadius = 5
        officeStatusLabel.layer.masksToBounds = true
        infoLabel.text = self.title
        if infoType == .info {
            if let updateDate = dataProvider?.formatDateString(dateString: specialAlertData?.alertDate, initialDateFormat: "yyyy-MM-dd'T'HH:mm:ss") {
                self.updateTitleLabel.text = "Updates \(updateDate)"
            }
            self.blurView.isHidden = false
            addBlurToView()
            self.tabBarController?.tabBar.isHidden = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    private func setupHeaderImageView() {
        if let alertData = specialAlertData {
            headerImageView.image = nil
            if let imageURL = dataProvider?.formImageURL(from: alertData.posterUrl), let url = URL(string: imageURL) {
                dataProvider?.getPosterImageData(from: url) { [weak self] (data, error) in
                    if let imageData = data, error == nil {
                        let image = UIImage(data: imageData)
                        self?.headerImageView.image = image
                    }
                }
            }
            screenTitleLabel.text = specialAlertData?.alertHeadline
        } else {
            headerImageView.image = UIImage(named: "office")
            screenTitleLabel.text = "Office Status"
        }
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        self.tableView.cornerRadius = 16
        tableView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        tableView.register(UINib(nibName: "InfoArticleCell", bundle: nil), forCellReuseIdentifier: "InfoArticleCell")
        tableView.register(UINib(nibName: "AppsServiceAlertCell", bundle: nil), forCellReuseIdentifier: "AppsServiceAlertCell")
        tableView.register(UINib(nibName: "OfficeInfoCell", bundle: nil), forCellReuseIdentifier: "OfficeInfoCell")
    }

    @IBAction func backButtonDidPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

}

extension InfoViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch infoType {
        case .info:
            return 1
        default: return officeDataSoure.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return infoType == .info ? UITableView.automaticDimension : 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch infoType {
        case .info:
            let cell = tableView.dequeueReusableCell(withIdentifier: "InfoArticleCell", for: indexPath) as? InfoArticleCell
            let htmlBody = dataProvider?.formNewsBody(from: specialAlertData?.alertBody)
            if let neededFont = UIFont(name: "SFProText-Light", size: 16) {
                htmlBody?.setFontFace(font: neededFont)
            }
            cell?.infoLabel.attributedText = htmlBody
            return cell ?? UITableViewCell()
        default:
            let data = officeDataSoure[indexPath.row]
            if data.additionalText == nil {
                let cell = tableView.dequeueReusableCell(withIdentifier: "OfficeInfoCell", for: indexPath) as? OfficeInfoCell
                cell?.iconImageView.image = UIImage(named: data.imageName)
                cell?.infoLabel.text = data.text
                return cell ?? UITableViewCell()
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "AppsServiceAlertCell", for: indexPath) as? AppsServiceAlertCell
            cell?.iconImageView.image = UIImage(named: data.imageName)
            cell?.mainLabel.text = data.text
            cell?.descriptionLabel.text = data.additionalText
            cell?.separator.isHidden = false
            return cell ?? UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard infoType == .office, indexPath.row == officeDataSoure.count - 1  else { return }
        let officeLocation = OfficeLocationViewController()
        var statusBarHeight: CGFloat = 0.0
        if #available(iOS 13.0, *) {
            statusBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
            statusBarHeight = view.window?.safeAreaInsets.top ?? 0 > 24 ? statusBarHeight - 17 : statusBarHeight - 21
        } else {
            statusBarHeight = self.view.bounds.height - UIApplication.shared.statusBarFrame.height
            statusBarHeight = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0 > 24 ? statusBarHeight - 17 : statusBarHeight - 21
        }
        officeLocation.title = "Select a Sony Music Office Location"
        let panModalNavigationController = PanModalNavigationController(rootViewController: officeLocation)
        panModalNavigationController.setNavigationBarHidden(true, animated: true)
        panModalNavigationController.initialHeight = self.tableView.bounds.height - statusBarHeight
        
        presentPanModal(panModalNavigationController)
    }
    
    func addBlurToView() {
        let gradientMaskLayer = CAGradientLayer()
        gradientMaskLayer.frame = blurView.bounds
        gradientMaskLayer.colors = [UIColor.white.withAlphaComponent(0.0).cgColor, UIColor.white.withAlphaComponent(0.3) .cgColor, UIColor.white.withAlphaComponent(1.0).cgColor]
        gradientMaskLayer.locations = [0, 0.1, 0.9, 1]
        blurView.layer.mask = gradientMaskLayer
    }
    
}

//temp
struct Hardcode {
    var imageName: String
    var text: String
    var additionalText: String? = nil
}


