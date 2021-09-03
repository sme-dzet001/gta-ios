//
//  HomepageFilterTabsCollectionCell.swift
//  GTA
//
//  Created by Margarita N. Bock on 02.09.2021.
//

import UIKit

class HomepageFilterTabsCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var selectedTabUnderlineView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override var isSelected: Bool {
        didSet {
            selectedTabUnderlineView.isHidden = !isSelected
        }
    }

}
