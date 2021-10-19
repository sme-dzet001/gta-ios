//
//  ImageTableViewCell.swift
//  GTA
//
//  Created by Артем Хрещенюк on 18.10.2021.
//

import UIKit

class ImageTableViewCell: UITableViewCell {

    @IBOutlet weak var newsImageView: UIImageView!
    
    weak var delegate: ImageViewDidTappedDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setupCell(imagePath: String?) {
        let imageURL = formImageURL(from: imagePath)
        let url = URL(string: imageURL)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        newsImageView.kf.indicatorType = .activity
        newsImageView.kf.setImage(with: url, placeholder: nil, options: nil, completionHandler: { [weak self] (result) in
            switch result {
            case .success(let resData):
                self?.newsImageView.image = resData.image
            case .failure(let error):
                if !error.isNotCurrentTask {
                    self?.newsImageView.image = nil
                }
            }
        })
        newsImageView.alpha = 1
        newsImageView.restorationIdentifier = imagePath
        newsImageView.heroID = imagePath
        newsImageView.addGestureRecognizer(tapGestureRecognizer)
        newsImageView.isUserInteractionEnabled = true
    }
    
    private func formImageURL(from imagePath: String?) -> String {
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
    
}
