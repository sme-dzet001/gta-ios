//
//  StatsBarView.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 18.11.2020.
//

import UIKit

class StatsBarView: UIView {

    struct Constants {
        static let legendFont = UIFont.systemFont(ofSize: 10.0, weight: .regular)
        static let legendFontColor = UIColor(hex: 0x8A8A99)
        static let itemSpacing: CGFloat = 13.0
        static let barCornerRadius: CGFloat = 4
    }

    var containerHeight: CGFloat = 100.0 {
        didSet {
            updateBarHeight()
        }
    }

    var barHeightConstant: CGFloat? {
        didSet {
            updateBarHeight()
        }
    }

    var barHeightPercentage: CGFloat? {
        didSet {
            updateBarHeight()
        }
    }

    let stackView: UIStackView

    let bar = UIView()
    let legendLabel = UILabel()

    private let barHeightConstraint: NSLayoutConstraint

    private var barMaxHeight: CGFloat {
        return max(0, containerHeight - Constants.legendFont.lineHeight - Constants.itemSpacing)
    }
    
    private func updateBarHeight() {

        guard let barHeightPercentage = barHeightPercentage else {
            barHeightConstraint.constant = barHeightConstant ?? 0
            return
        }

        barHeightConstraint.constant = barMaxHeight * barHeightPercentage
    }

    override init(frame: CGRect) {
        stackView = UIStackView(arrangedSubviews: [bar, legendLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Constants.itemSpacing

        barHeightConstraint = bar.heightAnchor.constraint(equalToConstant: 0)

        super.init(frame: frame)

        bar.backgroundColor = .white
        bar.cornerRadius = Constants.barCornerRadius

        addSubview(stackView)
        stackView.pinEdges(to: self)
        bar.pinEdges(to: self, edges: .sides, leadingOffset: 12, trailingOffset: 12)

        legendLabel.text = "n/a"
        legendLabel.textAlignment = .center
        legendLabel.adjustsFontSizeToFitWidth = true
        legendLabel.minimumScaleFactor = 0.7
        legendLabel.font = Constants.legendFont
        legendLabel.textColor = Constants.legendFontColor

        barHeightConstraint.isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented!")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        updateBarHeight()
    }

}
