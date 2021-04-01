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
    @IBOutlet weak var byLabel: UILabel!
    @IBOutlet weak var mainLabelCenterY: NSLayoutConstraint?
    @IBOutlet weak var dateLabelTop: NSLayoutConstraint?
    @IBOutlet weak var dateLabelByLineTop: NSLayoutConstraint?
    @IBOutlet weak var byLineHeight: NSLayoutConstraint?
    
    var dataProvider: HomeDataProvider?
    
    var infoType: infoType = .info
    var selectedOfficeData: OfficeRow?
    var officeDataSoure: [Hardcode] = []
    var specialAlertData: SpecialAlertRow?
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDataSource()
        setUpTableView()
        setupHeaderImageView()
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpConstraints()
        dataProvider?.officeSelectionDelegate = self
        updateTitleLabel.isHidden = infoType == .office
        officeStatusLabel.isHidden = true//infoType != .office
        officeStatusLabel.layer.cornerRadius = 5
        officeStatusLabel.layer.masksToBounds = true
        infoLabel.attributedText = addShadow(for: self.title)
        if infoType == .info {
            self.updateTitleLabel.attributedText = nil
            if let updateDate = dataProvider?.formatDateString(dateString: specialAlertData?.alertDate, initialDateFormat: "yyyy-MM-dd'T'HH:mm:ss") {
                self.updateTitleLabel.attributedText = addShadow(for: updateDate)//text = "Updates \(updateDate)"
            }
            if let byLine = specialAlertData?.alertAuthor, !byLine.isEmpty {
                byLineHeight?.isActive = true
                byLabel.attributedText = addShadow(for: byLine)//text = specialAlertData?.alertAuthor
            } else {
                byLabel.attributedText = nil
                byLineHeight?.isActive = false
            }
            self.blurView.isHidden = false
            addBlurToView()
            self.tabBarController?.tabBar.isHidden = true
        }
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        handleBlurShowing(animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func setUpConstraints() {
        if infoType == .info {
            byLabel.isHidden = false
            var multiplier: CGFloat = 1.0
            var newConstraint: NSLayoutConstraint?
            if let byLine = specialAlertData?.alertAuthor, !byLine.isEmpty {
                multiplier = UIDevice.current.iPhone5_se ? 1.0 : 1.1
                newConstraint = mainLabelCenterY?.constraintWithMultiplier(multiplier)
            } else {
                multiplier = UIDevice.current.iPhone5_se ? 1.3 : 1.4
                newConstraint = mainLabelCenterY?.constraintWithMultiplier(multiplier)
            }
            if let _ = mainLabelCenterY, let _ = newConstraint {
                self.view.removeConstraint(mainLabelCenterY!)
                self.view.addConstraint(newConstraint!)
            }
        } else {
            byLabel.isHidden = true
            dateLabelByLineTop?.isActive = false
            dateLabelTop?.isActive = true
        }
        self.view.layoutIfNeeded()
    }
    
    private func setDataSource() {
        officeDataSoure = [Hardcode(imageName: "phone_icon", text: selectedOfficeData?.officePhone ?? "", infoType: "phone"), Hardcode(imageName: "email_icon", text: selectedOfficeData?.officeEmail ?? "", infoType: "email"), Hardcode(imageName: "location", text: selectedOfficeData?.officeLocation ?? "", infoType: "location"), Hardcode(imageName: "desk_finder", text: "Sony Offices", additionalText: "Select a different Sony Music office")]
        officeDataSoure.removeAll { $0.text.isEmpty }
    }
    
    private func setupHeaderImageView() {
        if let alertData = specialAlertData {
            headerImageView.image = nil
            headerImageView.contentMode = .scaleAspectFit
            if let imageURL = dataProvider?.formImageURL(from: alertData.posterUrl), let url = URL(string: imageURL) {
                dataProvider?.getPosterImageData(from: url) { [weak self] (data, error) in
                    if let imageData = data, error == nil {
                        let image = UIImage(data: imageData)
                        self?.headerImageView.image = image
                    }
                }
            }
            screenTitleLabel.text = specialAlertData?.alertTitle
        } else {
            headerImageView.image = UIImage(named: "office")
            headerImageView.contentMode = .scaleAspectFill
            screenTitleLabel.text = "Office"
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
    
    private func makeCallWithNumber(_ number: String?) {
        if let number = number?.components(separatedBy: ",").first, let numberURL = URL(string: "tel://" + number.filter("+0123456789.".contains)) {
            UIApplication.shared.open(numberURL, options: [:], completionHandler: nil)
        }
    }
    
    private func makeEmailForAddress(_ address: String?) {
        if let address = address, let addressURL = URL(string: "mailto:" + address) {
            UIApplication.shared.open(addressURL, options: [:], completionHandler: nil)
        }
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
    
    private func getHeightForRowAt(indexPath: IndexPath) -> CGFloat {
        if infoType == .info {
            return UITableView.automaticDimension
        } else {
            if indexPath.row < officeDataSoure.count, let infoType = officeDataSoure[indexPath.row].infoType, infoType == "location" {
                // change bottom value if leading or trailing margin will change
                let addressLabelWidth = view.frame.width - 81
                let addressLabelMinTopOffset: CGFloat = 8
                if let labelFont = UIFont(name: "SFProText-Regular", size: 16), (officeDataSoure[indexPath.row].text.replacingOccurrences(of: "\u{00A0}", with: " ").height(width: addressLabelWidth, font: labelFont) + 2 * addressLabelMinTopOffset) > 80 {
                    return UITableView.automaticDimension
                } else {
                    return 80
                }
            } else {
                return 80
            }
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return getHeightForRowAt(indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return getHeightForRowAt(indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch infoType {
        case .info:
            let cell = tableView.dequeueReusableCell(withIdentifier: "InfoArticleCell", for: indexPath) as? InfoArticleCell
            let htmlBody = dataProvider?.formNewsBody(from: specialAlertData?.alertBody)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 8
            paragraphStyle.paragraphSpacing = 22
            htmlBody?.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, htmlBody?.length ?? 0))
            if let neededFont = UIFont(name: "SFProText-Light", size: 16) {
                htmlBody?.setFontFace(font: neededFont)
            }
            cell?.infoLabel.attributedText = htmlBody
            cell?.delegate = self
            return cell ?? UITableViewCell()
        default:
            let data = officeDataSoure[indexPath.row]
            if data.additionalText == nil {
                let cell = tableView.dequeueReusableCell(withIdentifier: "OfficeInfoCell", for: indexPath) as? OfficeInfoCell
                cell?.iconImageView.image = UIImage(named: data.imageName)
                cell?.infoLabel.text = data.text.replacingOccurrences(of: "\u{00A0}", with: " ")
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
        guard infoType == .office else { return }
        if indexPath.row == officeDataSoure.count - 1 {
            let officeLocation = OfficeLocationViewController()
            var statusBarHeight: CGFloat = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
            statusBarHeight = view.window?.safeAreaInsets.bottom ?? 0 > 24 ? statusBarHeight - 10 : statusBarHeight - 20
            officeLocation.title = "Select Sony Music Office Region"
            officeLocation.dataProvider = dataProvider
            //officeLocation.officeSelectionDelegate = self
            let panModalNavigationController = PanModalNavigationController(rootViewController: officeLocation)
            panModalNavigationController.setNavigationBarHidden(true, animated: true)
            panModalNavigationController.initialHeight = self.tableView.bounds.height - statusBarHeight
            
            presentPanModal(panModalNavigationController)
        } else {
            if officeDataSoure[indexPath.row].infoType == "phone" {
                let number = officeDataSoure[indexPath.row].text
                makeCallWithNumber(number)
            } else if officeDataSoure[indexPath.row].infoType == "email" {
                let email = officeDataSoure[indexPath.row].text
                makeEmailForAddress(email)
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleBlurShowing(animated: true)
    }
    
    func handleBlurShowing(animated: Bool) {
        guard infoType == .info else { return }
        let isReachedBottom = tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height).rounded(.towardZero)
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.blurView.alpha = isReachedBottom ? 0 : 1
            }
        } else {
            blurView.alpha = isReachedBottom ? 0 : 1
        }
    }
    
    func addBlurToView() {
        let gradientMaskLayer = CAGradientLayer()
        gradientMaskLayer.frame = blurView.bounds
        gradientMaskLayer.colors = [UIColor.white.withAlphaComponent(0.0).cgColor, UIColor.white.withAlphaComponent(0.3) .cgColor, UIColor.white.withAlphaComponent(1.0).cgColor]
        gradientMaskLayer.locations = [0, 0.1, 0.9, 1]
        blurView.layer.mask = gradientMaskLayer
    }
    
}

extension InfoViewController: OpenLinkDelegate {
    func openUrl(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

extension InfoViewController: OfficeSelectionDelegate {
    func officeWasSelected() {
        updateUIWithSelectedOffice()
        dataProvider?.getCurrentOffice()
    }
    
    private func updateUIWithSelectedOffice() {
        DispatchQueue.main.async {
            self.selectedOfficeData = self.dataProvider?.userOffice
            self.title = self.selectedOfficeData?.officeName
            self.infoLabel.text = self.title
            self.setDataSource()
            self.tableView.reloadData()
        }
    }
}

//temp
struct Hardcode {
    var imageName: String
    var text: String
    var additionalText: String? = nil
    var officeId: Int? = nil
    var infoType: String? = nil
}


