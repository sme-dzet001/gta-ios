//
//  ImageTableViewCell.swift
//  GTA
//
//  Created by Артем Хрещенюк on 18.10.2021.
//

import UIKit

class ImageTableViewCell: UITableViewCell {

    
    @IBOutlet weak var newsImageView: UIImageView!
    
    internal var aspectConstraint : NSLayoutConstraint? {
        didSet {
            if oldValue != nil {
                newsImageView.removeConstraint(oldValue!)
            }
            if aspectConstraint != nil {
                newsImageView.addConstraint(aspectConstraint!)
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        aspectConstraint = nil
    }
    
    weak var delegate: ImageViewDidTappedDelegate?

    func setupCell(imagePath: String?) {
        let imageURL = formImageURL(from: imagePath)
        let url = URL(string: imageURL)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        newsImageView.kf.indicatorType = .activity
        newsImageView.kf.setImage(with: url, placeholder: nil, options: nil, completionHandler: { [weak self] (result) in
            switch result {
            case .success(let resData):
                self?.setImageViewHeight(image: resData.image)
            case .failure(let error):
                if !error.isNotCurrentTask {
                    guard let defaultImage = UIImage(named: DefaultImageNames.whatsNewPlaceholder) else { return }
                    self?.setImageViewHeight(image: defaultImage)
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
        tappedImage.alpha = 0
        delegate?.imageViewDidTapped(imageView: tappedImage)
    }
    
    private func setImageViewHeight(image: UIImage) {
        let aspect = image.size.width / image.size.height
        
        let constraint = NSLayoutConstraint(item: newsImageView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: newsImageView, attribute: NSLayoutConstraint.Attribute.height, multiplier: aspect, constant: 0.0)
        constraint.priority = UILayoutPriority(999)
        
        newsImageView.image = image
        aspectConstraint = constraint
        layoutIfNeeded()
    }
}
