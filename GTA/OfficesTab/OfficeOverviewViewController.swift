//
//  OfficeOverviewViewController.swift
//  GTA
//
//  Created by Артем Хрещенюк on 08.09.2021.
//

import UIKit

class OfficeOverviewViewController: UIViewController {

    @IBOutlet weak var officeStatusLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    var officeDataProvider: MenuViewControllerDataProvider?
    weak var selectedOfficeUIUpdateDelegate: SelectedOfficeUIUpdateDelegate?
    
    var selectedOfficeData: OfficeRow?
    var officeDataSoure: [OfficeScreenData] = []
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
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        officeDataProvider?.officeSelectionDelegate = self
        officeStatusLabel.isHidden = true
        officeStatusLabel.layer.cornerRadius = 5
        officeStatusLabel.layer.masksToBounds = true
        infoLabel.attributedText = addShadow(for: self.title)
    }
    
    private func setDataSource() {
        officeDataSoure = [OfficeScreenData(imageName: "phone_icon", text: selectedOfficeData?.officePhone ?? "", infoType: "phone"), OfficeScreenData(imageName: "email_icon", text: selectedOfficeData?.officeEmail ?? "", infoType: "email"), OfficeScreenData(imageName: "location", text: selectedOfficeData?.officeLocation ?? "", infoType: "location"), OfficeScreenData(imageName: "desk_finder", text: "Sony Offices", additionalText: "Select a different Sony Music office")]
        officeDataSoure.removeAll { $0.text.isEmpty }
    }
    
    private func setupHeaderImageView() {
        headerImageView.image = UIImage(named: "office")
        headerImageView.contentMode = .scaleAspectFill
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

}

extension OfficeOverviewViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return officeDataSoure.count
    }
    
    private func getHeightForRowAt(indexPath: IndexPath) -> CGFloat {
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
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return getHeightForRowAt(indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return getHeightForRowAt(indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = officeDataSoure[indexPath.row]
        if data.additionalText == nil {
            let cell = tableView.dequeueReusableCell(withIdentifier: "OfficeInfoCell", for: indexPath) as? OfficeInfoCell
            cell?.iconImageView.image = UIImage(named: data.imageName)
            cell?.infoLabel.text = data.text.replacingOccurrences(of: "\u{00A0}", with: " ")
            cell?.infoLabel.accessibilityIdentifier = indexPath.row == 0 ? "InfoScreenCellPhoneNumberLabel" : "InfoScreenCellLocationLabel"
            return cell ?? UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "AppsServiceAlertCell", for: indexPath) as? AppsServiceAlertCell
        cell?.iconImageView.image = UIImage(named: data.imageName)
        cell?.mainLabel.text = data.text
        cell?.descriptionLabel.text = data.additionalText
        cell?.separator.isHidden = false
        cell?.mainLabel.accessibilityIdentifier = "InfoScreenOfficesCellTitle"
        cell?.descriptionLabel.accessibilityIdentifier = "InfoScreenOfficesCellSubtitle"
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == officeDataSoure.count - 1 {
            let officeLocation = OfficeLocationViewController()
            officeLocation.title = "Select Sony Music Office Region"
            officeLocation.dataProvider = officeDataProvider
            let panModalNavigationController = PanModalNavigationController(rootViewController: officeLocation)
            panModalNavigationController.setNavigationBarHidden(true, animated: true)
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
}

extension OfficeOverviewViewController: OpenLinkDelegate {
    func openUrl(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

extension OfficeOverviewViewController: OfficeSelectionDelegate {
    func officeWasSelected() {
        self.selectedOfficeUIUpdateDelegate?.updateUIWithNewSelectedOffice()
        updateUIWithSelectedOffice()
        officeDataProvider?.getCurrentOffice()
    }
    
    private func updateUIWithSelectedOffice() {
        DispatchQueue.main.async {
            self.selectedOfficeData = self.officeDataProvider?.userOffice
            self.title = self.selectedOfficeData?.officeName
            self.infoLabel.text = self.title
            self.setDataSource()
            self.tableView.reloadData()
        }
    }
}

struct OfficeScreenData {
    var imageName: String
    var text: String
    var additionalText: String? = nil
    var officeId: Int? = nil
    var infoType: String? = nil
}
