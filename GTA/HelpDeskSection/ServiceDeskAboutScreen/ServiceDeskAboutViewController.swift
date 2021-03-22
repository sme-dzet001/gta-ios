//
//  ServiceDeskAboutViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 14.01.2021.
//

import UIKit

class ServiceDeskAboutViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    //@IBOutlet weak var errorLabel: UILabel!
    
    private var errorLabel: UILabel = UILabel()
    var dataProvider: HelpDeskDataProvider?
    var aboutData: (imageUrl: String?, desc: String?)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setUpTableView()
        setUpScreenLook()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addErrorLabel(errorLabel, isGSD: true)
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = "About"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
        navigationItem.leftBarButtonItem?.customView?.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
    }
    
    private func setUpTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "ServiceDeskAboutCell", bundle: nil), forCellReuseIdentifier: "ServiceDeskAboutCell")
    }
    
    private func setUpScreenLook() {
        if let aboutData = aboutData {
            if aboutData.imageUrl != nil || aboutData.desc != nil {
                tableView.isHidden = false
                errorLabel.isHidden = true
            } else {
                tableView.isHidden = true
                errorLabel.isHidden = false
                errorLabel.text = "No data available"
            }
        }
    }
    
    @objc private func backPressed() {
        navigationController?.popViewController(animated: true)
    }

}

extension ServiceDeskAboutViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let aboutData = aboutData, (aboutData.imageUrl != nil || aboutData.desc != nil) {
            return 1
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ServiceDeskAboutCell", for: indexPath) as? ServiceDeskAboutCell {
            let descEncoded = aboutData?.desc
            let descDecoded = dataProvider?.formQuickHelpAnswerBody(from: descEncoded)
            if let neededFont = UIFont(name: "SFProText-Light", size: 16) {
                descDecoded?.setFontFace(font: neededFont)
            }
            descDecoded?.setParagraphStyleParams(lineSpacing: 8, paragraphSpacing: 16)
            cell.descLabel.attributedText = descDecoded
            
            if let imagePath = aboutData?.imageUrl, let imageURL = dataProvider?.formImageURL(from: imagePath), let url = URL(string: imageURL) {
                cell.activityIndicator.startAnimating()
                dataProvider?.getImageData(from: url) { (data, error) in
                    cell.activityIndicator.stopAnimating()
                    if let imageData = data, error == nil {
                        let image = UIImage(data: imageData)
                        cell.serviceDeskIcon.image = image
                        cell.iconContainerView.isHidden = false
                    } else {
                        cell.iconContainerView.isHidden = true
                    }
                }
            } else {
                cell.iconContainerView.isHidden = true
            }
            
            return cell
        }
        return UITableViewCell()
    }
    
}
