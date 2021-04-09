//
//  WhatsNewViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 05.04.2021.
//

import UIKit
import SwiftyGif

class WhatsNewViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var dataProvider: CollaborationDataProvider?
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private var errorLabel: UILabel = UILabel()
    
    private var cellForAnimation: WhatsNewCell?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addErrorLabel(errorLabel)
        getWhatsNewData()
    }
    
    private func getWhatsNewData() {
        startAnimation()
        dataProvider?.getWhatsNewData(completion: {[weak self] (dataWasChanged, errorCode, error) in
            DispatchQueue.main.async {
                if error != nil && errorCode != 200 {
                    self?.errorLabel.isHidden = !(self?.dataProvider?.collaborationNewsData.isEmpty ?? true)
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
                if dataWasChanged {
                    self?.tableView.reloadData()
                }
                self?.stopAnimation()
            }
        })
    }
    
    private func startAnimation() {
        guard dataProvider?.collaborationNewsData.isEmpty ?? true  else { return }
        self.tableView.alpha = 0
        errorLabel.isHidden = true
        self.addLoadingIndicator(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    private func stopAnimation() {
        if !(dataProvider?.collaborationNewsData.isEmpty ?? true) {
            errorLabel.isHidden = true
            self.tableView.alpha = 1
        }
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "WhatsNewCell", bundle: nil), forCellReuseIdentifier: "WhatsNewCell")
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = "What’s New"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
    }
    
    @objc private func backPressed() {
        self.navigationController?.popViewController(animated: true)
    }

}

extension WhatsNewViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataProvider?.collaborationNewsData.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard (dataProvider?.collaborationNewsData.count ?? 0) > indexPath.row else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: "WhatsNewCell", for: indexPath) as? WhatsNewCell
        let cellDataSource = dataProvider?.collaborationNewsData[indexPath.row]
        cell?.titleLabel.text = cellDataSource?.headline
        cell?.subtitleLabel.text = cellDataSource?.subHeadline
        cell?.descriptionLabel.attributedText = dataProvider?.formAnswerBody(from: cellDataSource?.body)
        cell?.relativePath = cellDataSource?.imageUrl
        if let imageURL = dataProvider?.formImageURL(from: cellDataSource?.imageUrl), let _ = URL(string: imageURL) {
            cell?.activityIndicator.startAnimating()
            cell?.imageUrl = imageURL
            dataProvider?.getAppImageData(from: cellDataSource?.imageUrl) { (data, error) in
                if cell?.imageUrl != imageURL { return }
                cell?.activityIndicator.stopAnimating()
                if let imageData = data, error == nil {
                    let image = UIImage(data: imageData)
                    if !imageURL.contains(".gif"), let _ = image {
                        cell?.mainImageView.setImage(image!)
                    } else {
                        if let gif = try? UIImage(gifData: imageData) {
                            cell?.mainImageView.setGifImage(gif)
                        } else {
                            cell?.mainImageView.image = nil
                        }
                    }
                } else {
                    cell?.mainImageView.image = nil// UIImage(named: "contact_default_photo")
                }
            }
        } else {
            cell?.mainImageView.image = nil// UIImage(named: "contact_default_photo")
        }
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard (dataProvider?.collaborationNewsData.count ?? 0) > indexPath.row else { return }
        let whatsNewMoreScreen = WhatsNewMoreViewController()
        let cellDataSource = dataProvider?.collaborationNewsData[indexPath.row]
        whatsNewMoreScreen.dataProvider = dataProvider
        whatsNewMoreScreen.dataSource = cellDataSource
        if let article = cellDataSource?.body {
            dataProvider?.addArticle(article)
        }
        self.navigationController?.pushViewController(whatsNewMoreScreen, animated: true)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let _ = cellForAnimation, tableView.visibleCells.contains(cellForAnimation!) else { return }
        cellForAnimation?.mainImageView.startAnimatingGif()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let _ = cellForAnimation, tableView.visibleCells.contains(cellForAnimation!) else { return }
        cellForAnimation?.mainImageView.startAnimatingGif()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let cells = tableView.visibleCells as? [WhatsNewCell] else { return }
        if scrollView.contentOffset.y <= 0 {
            cells.forEach({$0.mainImageView.stopAnimatingGif()})
            cells.first?.mainImageView.startAnimatingGif()
            return
        }
        var distanceToCenter: CGFloat = 0
        for cell in cells {
            let row = dataProvider?.collaborationNewsData.firstIndex(where: {((cell.relativePath ?? "").contains($0.imageUrl ?? ""))})
            guard let _ = row else { continue }
            let rect = self.tableView.rectForRow(at: IndexPath(row: row!, section: 0))
            let currentDistanceToCenter = self.view.center.y - tableView.convert(rect, to: self.tableView.superview).origin.y
            if distanceToCenter == 0 || (distanceToCenter > currentDistanceToCenter && currentDistanceToCenter > 0) {
                distanceToCenter = currentDistanceToCenter
                cellForAnimation = cell
            }
        }
        cells.forEach({$0.mainImageView.stopAnimatingGif()})
    }

    
}
