//
//  ImageTableViewCell.swift
//  GTA
//
//  Created by Артем Хрещенюк on 18.10.2021.
//

import UIKit
import Kingfisher

protocol ImageCellDelegate: AnyObject {
    func imageViewDidTapped(imageView: UIImageView)
    func updateTableView()
}

class ImageTableViewCell: UITableViewCell {

    @IBOutlet weak var newsImageView: UIImageView!
    
    weak var delegate: ImageCellDelegate?
    var aspectConstraint : NSLayoutConstraint? {
        didSet {
            if oldValue != nil {
                newsImageView.removeConstraint(oldValue!)
            }
            if aspectConstraint != nil {
                aspectConstraint?.priority = UILayoutPriority(999)
                newsImageView.addConstraint(aspectConstraint!)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        aspectConstraint = nil
        newsImageView.kf.cancelDownloadTask()
    }
    
    func setupCell(imagePath: String?) {
        let imageURL = formImageURL(from: imagePath)
        let url = URL(string: imageURL)
        let imageIsCached = ImageCache.default.isCached(forKey: imageURL)
        
        imageViewConfiguration(path: imagePath)
        aspectConstraint = newsImageView.heightAnchor.constraint(equalToConstant: 184)
        if Reachability.isConnectedToNetwork() || imageIsCached {
            setImage(url: url, cached: imageIsCached)
        } else {
            guard let defaultImage = UIImage(named: DefaultImageNames.whatsNewPlaceholder) else { return }
            newsImageView.contentMode = .scaleAspectFill
            newsImageView.image = defaultImage
        }
    }
    
    private func imageViewConfiguration(path: String?) {
        newsImageView.layer.cornerRadius = 16
        newsImageView.layer.masksToBounds = true
        newsImageView.alpha = 1
        newsImageView.restorationIdentifier = path
        newsImageView.heroID = path
    }
    
    private func setImage(url: URL?, cached: Bool) {
        newsImageView.kf.indicatorType = .activity
        newsImageView.kf.setImage(with: url, placeholder: nil, options: nil, completionHandler: { [weak self] (result) in
            switch result {
            case .success(let resData):
                self?.newsImageView.contentMode = .scaleAspectFit
                self?.updateImageView(image: resData.image)
            case .failure(let error):
                if !error.isNotCurrentTask {
                    guard let defaultImage = UIImage(named: DefaultImageNames.whatsNewPlaceholder) else { return }
                    self?.newsImageView.contentMode = .scaleAspectFill
                    self?.newsImageView.image = defaultImage
                    self?.updateImageView(image: defaultImage)
                }
            }
        })
    }
    
    func formImageURL(from imagePath: String?) -> String {
        let apiManager: APIManager = APIManager(accessToken: KeychainManager.getToken())
        guard let imagePath = imagePath else { return "" }
        guard !imagePath.contains("https://") else  { return imagePath }
        let imageURL = apiManager.baseUrl + "/" + imagePath.replacingOccurrences(of: "assets/", with: "assets/\(KeychainManager.getToken() ?? "")/")
        return imageURL
    }
    
    @objc private func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        guard let tappedImage = tapGestureRecognizer.view as? UIImageView else { return }
        delegate?.imageViewDidTapped(imageView: tappedImage)
    }
    
    private func updateImageView(image: UIImage) {
        let height = image.size.height * (UIScreen.main.bounds.width / image.size.width)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        newsImageView.addGestureRecognizer(tapGestureRecognizer)
        newsImageView.isUserInteractionEnabled = true
        aspectConstraint?.constant = height > 250 ? 250 : height
        delegate?.updateTableView()
    }
}
