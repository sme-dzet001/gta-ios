//
//  ImageTableViewCell.swift
//  GTA
//
//  Created by Артем Хрещенюк on 18.10.2021.
//

import UIKit
import Kingfisher

protocol ImageViewDidTappedDelegate: AnyObject {
    func imageViewDidTapped(imageView: UIImageView)
}

class ImageTableViewCell: UITableViewCell {

    @IBOutlet weak var newsImageView: UIImageView!
    
    weak var delegate: ImageViewDidTappedDelegate?
    lazy var defaultHeightConstraint = NSLayoutConstraint(item: newsImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 160)

    internal var aspectConstraint : NSLayoutConstraint? {
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
        newsImageView.image = nil
    }
    
    func setupCell(imagePath: String?, completion: @escaping () -> ()) {
        let imageURL = formImageURL(from: imagePath)
        let url = URL(string: imageURL)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        if !ImageCache.default.isCached(forKey: imageURL) {
            aspectConstraint = defaultHeightConstraint
        }
        self.newsImageView.kf.indicatorType = .activity
        self.newsImageView.kf.setImage(with: url, placeholder: nil, options: nil, completionHandler: { [weak self] (result) in
            switch result {
            case .success(let resData):
                self?.setImageViewHeight(image: resData.image, completion: completion)
            case .failure(let error):
                if !error.isNotCurrentTask {
                    guard let defaultImage = UIImage(named: DefaultImageNames.whatsNewPlaceholder) else { return }
                    self?.setImageViewHeight(image: defaultImage, completion: completion)
                }
            }
        })
        newsImageView.alpha = 1
        newsImageView.restorationIdentifier = imagePath
        newsImageView.heroID = imagePath
        newsImageView.addGestureRecognizer(tapGestureRecognizer)
        newsImageView.isUserInteractionEnabled = true
    }
    
    func formImageURL(from imagePath: String?) -> String {
        let apiManager: APIManager = APIManager(accessToken: KeychainManager.getToken())
        guard let imagePath = imagePath else { return "" }
        guard !imagePath.contains("https://") else  { return imagePath }
        let imageURL = apiManager.baseUrl + "/" + imagePath.replacingOccurrences(of: "assets/", with: "assets/\(KeychainManager.getToken() ?? "")/")
        return imageURL
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        guard let tappedImage = tapGestureRecognizer.view as? UIImageView else { return }
        delegate?.imageViewDidTapped(imageView: tappedImage)
    }
    
    private func setImageViewHeight(image: UIImage, completion: @escaping () -> ()) {
        let height = image.size.height * (UIScreen.main.bounds.width / image.size.width)
        let aspect = image.size.width / image.size.height
        
        if height > 250 {
            aspectConstraint = NSLayoutConstraint(item: newsImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 250)
        } else {
            aspectConstraint = NSLayoutConstraint(item: newsImageView, attribute: .width, relatedBy: .equal, toItem: newsImageView, attribute: .height, multiplier: aspect, constant: 0.0)
        }
        completion()
    }
}
