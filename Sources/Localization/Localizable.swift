// Localizable.swift

import UIKit
import Foundation

public extension Notification.Name {
    static let DidChangePrefferedLanguage: Notification.Name = .init("DidChangePrefferedLanguage")
}

@objc public protocol LanguageReloadable {
    @objc func reloadLanguage()
}

public protocol Localizable: NSObject, LanguageReloadable {
    var localizedKey: String { get set }
    var isAutoFittingSize: Bool { get set }
    func registerForLanguageChange(target: LanguageReloadable)
}

public extension Localizable where Self: NSObject {
    func registerForLanguageChange(target: LanguageReloadable) {
        NotificationCenter.default.addObserver(target, selector: #selector(target.reloadLanguage), name: .DidChangePrefferedLanguage, object: nil)
    }
}

@IBDesignable
public class LocalizedLabel: UILabel, Localizable {
    @IBInspectable
    public var localizedKey: String = "" {
        didSet {
            text = NSLocalizedString(localizedKey, comment: "")
            guard isAutoFittingSize else { return }
            sizeToFit()
        }
    }
    
    public var isAutoFittingSize: Bool = true
    
    @objc public func reloadLanguage() {
        localizedKey = String(localizedKey)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerForLanguageChange(target: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerForLanguageChange(target: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

@IBDesignable
public class LocalizedButton: UIButton, Localizable {
    @IBInspectable
    public var localizedKey: String = "" {
        didSet {
            let localizedString = NSLocalizedString(localizedKey, comment: "")
            setTitle(localizedString, for: .normal)
            guard isAutoFittingSize else { return }
            sizeToFit()
        }
    }
    
    public var isAutoFittingSize: Bool = true
    
    @objc public func reloadLanguage() {
        localizedKey = String(localizedKey)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerForLanguageChange(target: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerForLanguageChange(target: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

@IBDesignable
public class LocalizedTextField: UITextField, Localizable {
    @IBInspectable
    public var localizedKey: String = "" {
        didSet {
            let localizedString = NSLocalizedString(localizedKey, comment: "")
            placeholder = localizedString
        }
    }
    
    @IBInspectable
    var placeholderColor: UIColor = .lightGray
    
    public var isAutoFittingSize: Bool = true
    
    @objc public func reloadLanguage() {
        localizedKey = String(localizedKey)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerForLanguageChange(target: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerForLanguageChange(target: self)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        subviews.compactMap{ $0 as? UILabel }.forEach {
            if let text = self.text, text.isEmpty {
                $0.textColor = placeholderColor
            } else {
                $0.textColor = textColor
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

@IBDesignable
public class LocalizedBarButtonItem: UIBarButtonItem, Localizable {
    @IBInspectable
    public var localizedKey: String = "" {
        didSet {
            let localizedString = NSLocalizedString(localizedKey, comment: "")
            title = localizedString
        }
    }
    
    public var isAutoFittingSize: Bool = true
    
    @objc public func reloadLanguage() {
        localizedKey = String(localizedKey)
    }
    
    override init() {
        super.init()
        registerForLanguageChange(target: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerForLanguageChange(target: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

@IBDesignable
public class LocalizedNavigationItem: UINavigationItem, Localizable {
    @IBInspectable
    public var localizedKey: String = "" {
        didSet {
            let localizedString = NSLocalizedString(localizedKey, comment: "")
            title = localizedString
        }
    }
    
    public var isAutoFittingSize: Bool = true
    
    @objc public func reloadLanguage() {
        localizedKey = String(localizedKey)
    }
    
    override init(title: String) {
        super.init(title: title)
        registerForLanguageChange(target: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerForLanguageChange(target: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

@IBDesignable
public class LocalizedTextView: UITextView, Localizable {
    @IBInspectable
    public var localizedKey: String = "" {
        didSet {
            let localizedString = NSLocalizedString(localizedKey, comment: "")
            text = localizedString
        }
    }
    
    public var isAutoFittingSize: Bool = true
    
    @objc public func reloadLanguage() {
        localizedKey = String(localizedKey)
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        registerForLanguageChange(target: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerForLanguageChange(target: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
