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

extension UIViewController {
    func displayError(errorMessage: String, title: String? = "Error", onClose: @escaping ((UIAlertAction) -> Void) = { _ in }) {
        let alertController = UIAlertController(title: title, message: errorMessage, preferredStyle: .alert)
        let closeAction = UIAlertAction(title: "OK", style: .default, handler: onClose)
        alertController.addAction(closeAction)
        present(alertController, animated: true, completion: nil)
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
