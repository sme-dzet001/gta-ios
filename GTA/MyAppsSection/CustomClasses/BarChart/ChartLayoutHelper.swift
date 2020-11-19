//
//  ChartLayoutHelper.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 18.11.2020.
//

import UIKit

extension UIView {

    struct PinOptions: OptionSet {

        let rawValue: Int

        static let all: PinOptions = [.top, .trailing, .bottom, .leading]
        static let sides: PinOptions = [.trailing, .leading]

        static let top = PinOptions(rawValue: 1 << 0)
        static let trailing = PinOptions(rawValue: 1 << 1)
        static let bottom = PinOptions(rawValue: 1 << 2)
        static let leading = PinOptions(rawValue: 1 << 3)

        init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    func pinEdges(to parentView: UIView, edges: PinOptions = .all, leadingOffset: CGFloat = 0, trailingOffset: CGFloat = 0) {

        translatesAutoresizingMaskIntoConstraints = false
        if edges.contains(.leading) {
            leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: leadingOffset).isActive = true
        }

        if edges.contains(.trailing) {
            trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -trailingOffset).isActive = true
        }

        if edges.contains(.top) {
            topAnchor.constraint(equalTo: parentView.topAnchor).isActive = true
        }

        if edges.contains(.bottom) {
            bottomAnchor.constraint(equalTo:parentView.bottomAnchor).isActive = true
        }
    }

}
