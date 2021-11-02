//
//  ImageZoomViewController.swift
//  GTA
//
//  Created by Артем Хрещенюк on 15.10.2021.
//

import UIKit
import Hero

class ImageZoomViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var zoomImage: UIImageView!
    @IBOutlet weak var closeButton: UIButton!
    
    var imageID: String?
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setTitle("", for: .normal)
        
        zoomImage.layer.cornerRadius = 16
        zoomImage.layer.masksToBounds = true
        
        zoomImage.image = image
        zoomImage.heroID = imageID
        setupScrollView()
    }
    
    @IBAction func closeAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
    }
    
    private func menuButton(enable: Bool) {
        guard let tabBar = self.tabBarController?.navigationController else { return }
        guard let mainVC = tabBar.viewControllers.first(where: { $0 is MainViewController}) as? MainViewController else {return}
        mainVC.menuButton.alpha = enable ? 1 : 0
    }
    
}

extension ImageZoomViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomImage
    }
}
