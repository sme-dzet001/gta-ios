//
//  Extensions.swift
//  ArtistPortal
//
//  Created by Margarita N. Bock on 5/14/19.
//  Copyright © 2019 SME. All rights reserved.
//

import UIKit
import CommonCrypto

extension UIColor {
    convenience init(hex: Int) {
        let components = (
            R: CGFloat((hex >> 16) & 0xff) / 255,
            G: CGFloat((hex >> 08) & 0xff) / 255,
            B: CGFloat((hex >> 00) & 0xff) / 255
        )
        self.init(red: components.R, green: components.G, blue: components.B, alpha: 1)
    }
    
    convenience init(hex: Int, alpha: CGFloat) {
        let components = (
            R: CGFloat((hex >> 16) & 0xff) / 255,
            G: CGFloat((hex >> 08) & 0xff) / 255,
            B: CGFloat((hex >> 00) & 0xff) / 255
        )
        self.init(red: components.R, green: components.G, blue: components.B, alpha: alpha)
    }
    
    /// Converts UIColor to 1x1 image and returns it
    func as1ptImage() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        setFill()
        UIGraphicsGetCurrentContext()?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
}

extension UILabel {
    func displayValueListIfFits(valueList: [String]) {
        let textToDisplay = valueList.joined(separator: ", ")
        text = textToDisplay
        let aSize = sizeThatFits(CGSize(width: 3000, height: bounds.size.height))
        if aSize.width >= bounds.size.width {
            text = ""
        }
    }
    
    func addReadMoreString(_ readMoreText: String) {
        self.font = UIFont(name: "SFProText-Regular", size: 16) ?? self.font
        guard let text = self.text, !text.isEmptyOrWhitespace() else { return }
        let readMoreAttributed = NSMutableAttributedString(string: readMoreText, attributes: [NSAttributedString.Key.font : font as Any, NSAttributedString.Key.foregroundColor: UIColor.gray])
        let lengthForVisibleString = vissibleTextLength
        if vissibleTextLength >= self.text!.count, let _ = self.attributedText {
            self.text = text
            let mutAttr = NSMutableAttributedString(attributedString: self.attributedText!)
            mutAttr.mutableString.append("... ")
            mutAttr.append(readMoreAttributed)
            self.attributedText = mutAttr
            return
        }
        let mutableString = NSMutableString(string: self.attributedText?.string ?? "")
        var trimmedString = (mutableString as NSString).replacingCharacters(in: NSMakeRange(lengthForVisibleString, ((self.text ?? "").count - lengthForVisibleString)), with: "")
        if trimmedString.last == "." || trimmedString.last == " " {
            trimmedString.removeLast()
        }
        repeat {
            let lastSpaceIndex = trimmedString.lastIndex(of: " ")
            if let _ = lastSpaceIndex {
                trimmedString.removeSubrange(lastSpaceIndex!..<trimmedString.endIndex)
            } else {
                break
            }
        } while ("... " + readMoreText).count + trimmedString.count > lengthForVisibleString - 3
        trimmedString.append("... ")
        let attrTrimm = NSMutableAttributedString(string: trimmedString)
        self.attributedText?.enumerateAttributes(in: NSRange(location: 0, length: attrTrimm.length), options: .longestEffectiveRangeNotRequired, using: { (attributes, range, _) in
            attrTrimm.addAttributes(attributes, range: range)
        })
        attrTrimm.append(readMoreAttributed)
        self.attributedText = attrTrimm
    }

    var vissibleTextLength: Int {
        let font: UIFont = UIFont(name: "SFProText-Regular", size: 16) ?? self.font
        let mode: NSLineBreakMode = self.lineBreakMode
        let labelWidth: CGFloat = self.frame.size.width
        let labelHeight: CGFloat = self.frame.size.height
        let sizeConstraint = CGSize(width: labelWidth, height: CGFloat.greatestFiniteMagnitude)

        let attributes: [AnyHashable: Any] = [NSAttributedString.Key.font: font]
        let attributedText = self.attributedText!// NSAttributedString(string: self.text!, attributes: attributes as? [NSAttributedString.Key : Any])
        let boundingRect: CGRect = attributedText.boundingRect(with: sizeConstraint, options: .usesLineFragmentOrigin, context: nil)

        if boundingRect.size.height > labelHeight {
            var index: Int = 0
            var prev: Int = 0
            let characterSet = CharacterSet.whitespacesAndNewlines
            repeat {
                prev = index
                if mode == NSLineBreakMode.byCharWrapping {
                    index += 1
                } else {
                    index = (self.attributedText!.string as NSString).rangeOfCharacter(from: characterSet, options: [], range: NSRange(location: index + 1, length: self.attributedText!.string.count - index - 1)).location
                }
            } while index != NSNotFound && index < self.attributedText!.string.count && (self.attributedText!.string as NSString).substring(to: index).boundingRect(with: sizeConstraint, options: .usesLineFragmentOrigin, attributes: attributes as? [NSAttributedString.Key : Any], context: nil).size.height <= labelHeight
            return prev + Int(Double(index - prev) / 1.5)
        }
        return self.attributedText!.string.count
    }
    
}

extension UIButton {
    @IBInspectable var bgColor: UIColor? {
        get {
            if let aColor = layer.backgroundColor {
                return UIColor(cgColor: aColor)
            }
            return nil
        }
        set {
            layer.backgroundColor = newValue?.cgColor
        }
    }
}

extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            guard let aBorderColor = layer.borderColor else {
                return nil
            }
            return UIColor(cgColor: aBorderColor)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    func addGradientBackgound(firstColor: UIColor, secondColor: UIColor, topToBottom: Bool) {
        self.layoutIfNeeded()
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = [firstColor.cgColor, secondColor.cgColor]
        gradient.locations = [0.0 , 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: topToBottom ? 0.0 : 1.0)
        gradient.endPoint = CGPoint(x: 0.0, y: topToBottom ? 1.0 : 0.0)
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: self.bounds.size.width + 2, height: self.bounds.size.height)
        gradient.name = "grad"
        self.layer.insertSublayer(gradient, at: 0)
    }
}

extension UINavigationController {
    
    func setNavigationBarSeparator(with color: UIColor) {
        let shadowImage = getSeparatorImage(for: color) ?? UIImage()
        self.navigationBar.shadowImage = shadowImage
        self.toolbar.setShadowImage(shadowImage, forToolbarPosition: .any)
    }
    
    private func getSeparatorImage(for color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContext(CGSize(width: self.view.frame.width, height: 1))
        let context = UIGraphicsGetCurrentContext()
        color.setFill()
        guard let ctx = context else { return nil }
        ctx.fill(CGRect(x: 0, y: 0, width: self.view.frame.width, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension UITableView {
    var dataHasChanged: Bool {
        guard let dataSource = dataSource else { return false }
        let sections = dataSource.numberOfSections?(in: self) ?? 0
        if numberOfSections != sections {
            return true
        }
        for section in 0..<sections {
            if numberOfRows(inSection: section) != dataSource.tableView(self, numberOfRowsInSection: section) {
                return true
            }
        }
        return false
    }
}

extension UIViewController {
    func displayError(errorMessage: String, title: String? = "Error", onClose: ((UIAlertAction?) -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: errorMessage, preferredStyle: .alert)
        let closeAction = UIAlertAction(title: "OK", style: .default, handler: onClose)
        alertController.addAction(closeAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func createErrorCell(with text: String?, textColor: UIColor = .black, withSeparator: Bool = false, verticalOffset: CGFloat = 24) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        if withSeparator {
            let separatorView = UIView()
            separatorView.backgroundColor = UIColor(hex: 0xF2F2F7)
            cell.contentView.addSubview(separatorView)
            separatorView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                NSLayoutConstraint(item: separatorView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 1.0),
                NSLayoutConstraint(item: separatorView, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: separatorView, attribute: .leading, relatedBy: .equal, toItem: cell.contentView, attribute: .leading, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: separatorView, attribute: .trailing, relatedBy: .equal, toItem: cell.contentView, attribute: .trailing, multiplier: 1.0, constant: 0.0)
                ])
        }
        let label = UILabel(frame: cell.contentView.bounds)
        cell.contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: verticalOffset),
            NSLayoutConstraint(item: label, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -verticalOffset),
            NSLayoutConstraint(item: label, attribute: .leading, relatedBy: .equal, toItem: cell.contentView, attribute: .leading, multiplier: 1.0, constant: 24.0),
            NSLayoutConstraint(item: label, attribute: .trailing, relatedBy: .equal, toItem: cell.contentView, attribute: .trailing, multiplier: 1.0, constant: -24.0)
            ])
        label.numberOfLines = 0
        label.font = UIFont(name: "SFProText-Regular", size: 16)!
        label.textAlignment = .center
        label.textColor = textColor
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.text = text
        return cell
    }
    
    func createLoadingCell(withBottomSeparator: Bool = false, withTopSeparator: Bool = false, verticalOffset: CGFloat? = nil) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        if withBottomSeparator {
            let separatorView = UIView()
            separatorView.backgroundColor = UIColor(hex: 0xF2F2F7)
            cell.contentView.addSubview(separatorView)
            separatorView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                NSLayoutConstraint(item: separatorView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 1.0),
                NSLayoutConstraint(item: separatorView, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: separatorView, attribute: .leading, relatedBy: .equal, toItem: cell.contentView, attribute: .leading, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: separatorView, attribute: .trailing, relatedBy: .equal, toItem: cell.contentView, attribute: .trailing, multiplier: 1.0, constant: 0.0)
                ])
        }
        if withTopSeparator {
            let separatorView = UIView()
            separatorView.backgroundColor = UIColor(hex: 0xF2F2F7)
            cell.contentView.addSubview(separatorView)
            separatorView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                NSLayoutConstraint(item: separatorView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 1.0),
                NSLayoutConstraint(item: separatorView, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: separatorView, attribute: .leading, relatedBy: .equal, toItem: cell.contentView, attribute: .leading, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: separatorView, attribute: .trailing, relatedBy: .equal, toItem: cell.contentView, attribute: .trailing, multiplier: 1.0, constant: 0.0)
                ])
        }
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        cell.contentView.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        if let verticalOffset = verticalOffset {
            NSLayoutConstraint.activate([
                NSLayoutConstraint(item: activityIndicator, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: verticalOffset),
                NSLayoutConstraint(item: activityIndicator, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -verticalOffset),
                NSLayoutConstraint(item: activityIndicator, attribute: .centerX, relatedBy: .equal, toItem: cell.contentView, attribute: .centerX, multiplier: 1.0, constant: 0.0)
                ])
        } else {
            NSLayoutConstraint.activate([
                NSLayoutConstraint(item: activityIndicator, attribute: .centerX, relatedBy: .equal, toItem: cell.contentView, attribute: .centerX, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: activityIndicator, attribute: .centerY, relatedBy: .equal, toItem: cell.contentView, attribute: .centerY, multiplier: 1.0, constant: 0.0)
                ])
        }
        activityIndicator.startAnimating()
        return cell
    }
    
    func addShadow(for text: String?) -> NSMutableAttributedString? {
        guard let text = text else { return nil }
        let shadow = NSShadow()
        shadow.shadowOffset = CGSize(width: 5, height: 5)
        shadow.shadowBlurRadius = 5
        shadow.shadowColor = UIColor.black
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(.shadow, value: shadow, range: NSRange(text.startIndex..., in: text))
        return attributedString
    }
        
    func addLoadingIndicator(_ loadingIndicator: UIActivityIndicatorView, isGSD: Bool = false) {
        self.view.addSubview(loadingIndicator)
        self.view.bringSubviewToFront(loadingIndicator)
        loadingIndicator.center = getActualViewCenter(isGSD: isGSD)
    }
    
    func addErrorLabel(_ errorLabel: UILabel, isGSD: Bool = false) {
        errorLabel.numberOfLines = 1
        errorLabel.font = UIFont(name: "SFProText-Regular", size: 16)!
        errorLabel.textAlignment = .center
        errorLabel.textColor = .black
        errorLabel.adjustsFontSizeToFitWidth = true
        errorLabel.minimumScaleFactor = 0.7
        errorLabel.frame.size.height = 20
        errorLabel.frame.size.width = self.view.frame.width - 40
        errorLabel.isHidden = true
        self.view.addSubview(errorLabel)
        self.view.bringSubviewToFront(errorLabel)
        errorLabel.center = getActualViewCenter(isGSD: isGSD)
    }
    
    fileprivate func getActualViewCenter(isGSD: Bool = false) -> CGPoint {
        let navigationControllerView = navigationController?.view ?? self.view
        let navigationControllerCenter = navigationControllerView?.center ?? self.view.center
        var center = navigationControllerView?.convert(navigationControllerCenter, to: self.view) ?? self.view.center
        if isGSD && center.y == self.view.center.y {
            let diff = (navigationController?.navigationBar.frame.origin.y ?? 0.0) + (navigationController?.navigationBar.frame.height ?? 0)
            center = CGPoint(x: self.view.center.x, y: self.view.center.y - (diff))
        }
        return center
    }
    
}

extension String {
    var sha512: String {
        let data = Data(self.utf8)
        let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
            CC_SHA512(bytes.baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    func isEmptyOrWhitespace() -> Bool {
        if(self.isEmpty) {
            return true
        }
        return (self.trimmingCharacters(in: NSCharacterSet.whitespaces) == "")
    }
    
    static var neededDateFormat: String {
        return "HH:mm zzz E d"
    }
    
    static var comapreDateFormat: String {
        return "yyyy-MM-dd HH:mm:ss"
    }
    
    static var ticketDateFormat: String {
        return "yyyy-MM-dd'T'HH:mm:ss.SSSZ"//"yyyy-MM-dd'T'HH:mm:ss.SSS Z"
    }
    
    static func getTicketDateFormat(for date: Date) -> String {
        return "E MMM d'\(date.daySuffix())', yyyy h:mm a"
    }
    
    static var ticketsSectionDateFormat: String {
        return "E MMM dd, yyyy hh:mm a"
    }
    
    var isValidEmail: Bool {
        let emailRegEx = "(?:[a-zA-Z0-9!#$%\\&‘*+/=?\\^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}" +
        "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" +
        "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-" +
        "z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5" +
        "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" +
        "9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" +
        "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        
        let emailPred = NSPredicate(format:"SELF MATCHES[c] %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
    
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
    
    func height(width: CGFloat, font: UIFont) -> CGFloat {
        let textSize = CGSize(width: width, height: .greatestFiniteMagnitude)
        
        let size = self.boundingRect(with: textSize,
                                     options: .usesLineFragmentOrigin,
                                     attributes: [NSAttributedString.Key.font : font],
                                     context: nil)
        return ceil(size.height)
    }
    
    func getFormattedDateStringForMyTickets() -> String {
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = String.ticketDateFormat
        guard let date = dateFormatterPrint.date(from: self) else { return self }
        dateFormatterPrint.dateFormat = String.getTicketDateFormat(for: date)
        return dateFormatterPrint.string(from: date)
    }
    
}

extension Date {
    func daySuffix() -> String {
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components(.day, from: self)
        let dayOfMonth = components.day
        switch dayOfMonth {
        case 1, 21, 31:
            return "st"
        case 2, 22:
            return "nd"
        case 3, 23:
            return "rd"
        default:
            return "th"
        }
    }
}

extension Array where Element: Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()
        for value in self {
            if !result.contains(value) {
                result.append(value)
            }
        }
        return result
    }
}

extension NSAttributedString {
    func height(containerWidth: CGFloat) -> CGFloat {
        let rect = self.boundingRect(with: CGSize.init(width: containerWidth, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return ceil(rect.size.height)
    }
}
extension NSMutableAttributedString {
    // method to change attr string font without removing other attribures
    func setFontFace(font: UIFont, color: UIColor? = nil) {
        beginEditing()
        self.enumerateAttribute(
            .font,
            in: NSRange(location: 0, length: self.length)
        ) { (value, range, stop) in

            if let f = value as? UIFont,
              let newFontDescriptor = f.fontDescriptor
                .withFamily(font.familyName)
                .withSymbolicTraits(f.fontDescriptor.symbolicTraits) {

                let newFont = UIFont(
                    descriptor: newFontDescriptor,
                    size: font.pointSize
                )
                removeAttribute(.font, range: range)
                addAttribute(.font, value: newFont, range: range)
                if let color = color {
                    removeAttribute(
                        .foregroundColor,
                        range: range
                    )
                    addAttribute(
                        .foregroundColor,
                        value: color,
                        range: range
                    )
                }
            } else if let f = value as? UIFont, f.fontName.lowercased().contains("italic") {
                removeAttribute(.font, range: range)
                if let font = UIFont(name: "SF Pro Text Italic", size: 16) {
                    addAttribute(.font, value: (font as Any), range: range)
                }
            }
        }
        endEditing()
    }
    
    // method to change attr string paragraph style without removing other paragraph attribures
    func setParagraphStyleParams(lineSpacing: CGFloat, paragraphSpacing: CGFloat? = nil) {
        beginEditing()
        self.enumerateAttribute(
            .paragraphStyle,
            in: NSRange(location: 0, length: self.length)
        ) { (value, range, stop) in
            if let parStyle = value as? NSMutableParagraphStyle {
                let newParStyle = parStyle
                newParStyle.lineSpacing = lineSpacing
                if let parSpacing = paragraphSpacing {
                    newParStyle.paragraphSpacing = parSpacing
                }
                removeAttribute(.paragraphStyle, range: range)
                addAttribute(.paragraphStyle, value: newParStyle, range: range)
            }
        }
        endEditing()
    }
}

extension UINavigationController {
    var rootViewController : UIViewController? {
        return self.viewControllers.first
    }
    
    func setNavigationBarBottomShadowColor(_ color: UIColor) {
        self.navigationBar.shadowImage = color.as1ptImage()
    }
}

extension UIWindow {
    static var key: UIWindow? {
        if #available(iOS 13, *) {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}

extension UIDevice {
    var iPhone4_4s: Bool {
        return UIScreen.main.nativeBounds.height == 960
    }
    
    var iPhone5_se: Bool {
        return UIScreen.main.nativeBounds.height == 1136
    }
    
    var iPhone7_8: Bool {
        return UIScreen.main.nativeBounds.height == 1334
    }
    
    var iPhone7_8_Zoomed: Bool {
        return UIScreen.main.nativeBounds.height == 1334 && UIScreen.main.nativeScale > UIScreen.main.scale
    }
    
    var iPhone7_8_Plus: Bool {
        return UIScreen.main.nativeBounds.height == 1920 || UIScreen.main.nativeBounds.height == 2208
    }
    
    var iPad: Bool {
        return userInterfaceIdiom == .pad
    }
}

extension NSLayoutConstraint {
    func constraintWithMultiplier(_ multiplier: CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: self.firstItem!, attribute: self.firstAttribute, relatedBy: self.relation, toItem: self.secondItem, attribute: self.secondAttribute, multiplier: multiplier, constant: self.constant)
    }
}

extension UITapGestureRecognizer {

    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize

        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        //let textContainerOffset = CGPointMake((labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
                                              //(labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y);
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)

        //let locationOfTouchInTextContainer = CGPointMake(locationOfTouchInLabel.x - textContainerOffset.x,
                                                        // locationOfTouchInLabel.y - textContainerOffset.y);
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x, y: locationOfTouchInLabel.y - textContainerOffset.y)
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        return NSLocationInRange(indexOfCharacter, targetRange)
    }

}
