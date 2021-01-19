//
//  HyperlinkTextView.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 15.01.2021.
//

import UIKit

class HyperlinkTextView: UITextView {

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
    
    override func caretRect(for position: UITextPosition) -> CGRect {
        return .zero
    }
    

    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        return []
    }

}
