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
    var localized: Localized? { get set }
    var isAutoFittingSize: Bool { get set }
    func registerForLanguageChange(target: LanguageReloadable)
}

public extension Localizable where Self: NSObject {
    func registerForLanguageChange(target: LanguageReloadable) {
        NotificationCenter.default.addObserver(target, selector: #selector(target.reloadLanguage), name: .DidChangePrefferedLanguage, object: nil)
    }
}

@IBDesignable
open class LocalizedLabel: UILabel, Localizable {
    
    @IBInspectable
    public var localizedKey: String? = "" {
        didSet {
            if let key = localizedKey {
                localized = Localized[dynamicMember: key]
            } else {
                localized = nil
            }
        }
    }
    
    public var localized: Localized? = nil {
        didSet {
            reloadLanguage()
        }
    }
    
    public var isAutoFittingSize: Bool = true
    
    @objc public func reloadLanguage() {
        text = localized?.description
        guard isAutoFittingSize else { return }
        sizeToFit()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        registerForLanguageChange(target: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerForLanguageChange(target: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

@IBDesignable
open class LocalizedButton: UIButton, Localizable {
    @IBInspectable
    public var localizedKey: String? = "" {
        didSet {
            if let key = localizedKey {
                localized = Localized[dynamicMember: key]
            } else {
                localized = nil
            }
        }
    }
    
    public var localized: Localized? = nil {
        didSet {
            reloadLanguage()
        }
    }
    
    public var isAutoFittingSize: Bool = true
    
    @objc public func reloadLanguage() {
        let localizedString = localized?.description
        setTitle(localizedString, for: .normal)
        guard isAutoFittingSize else { return }
        sizeToFit()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        registerForLanguageChange(target: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerForLanguageChange(target: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

@IBDesignable
open class LocalizedTextField: UITextField, Localizable {
    @IBInspectable
    public var localizedKey: String? = "" {
        didSet {
            if let key = localizedKey {
                localized = Localized[dynamicMember: key]
            } else {
                localized = nil
            }
        }
    }
    
    public var localized: Localized? = nil {
        didSet {
            reloadLanguage()
        }
    }
    
    @IBInspectable
    var placeholderColor: UIColor = .lightGray
    
    public var isAutoFittingSize: Bool = true
    
    @objc public func reloadLanguage() {
        placeholder = localized?.description
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerForLanguageChange(target: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
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
open class LocalizedBarButtonItem: UIBarButtonItem, Localizable {
    @IBInspectable
    public var localizedKey: String? = "" {
        didSet {
            if let key = localizedKey {
                localized = Localized[dynamicMember: key]
            } else {
                localized = nil
            }
        }
    }
    
    public var localized: Localized? = nil {
        didSet {
            reloadLanguage()
        }
    }
    
    public var isAutoFittingSize: Bool = true
    
    @objc public func reloadLanguage() {
        title = localized?.description
    }
    
    override init() {
        super.init()
        registerForLanguageChange(target: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerForLanguageChange(target: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

@IBDesignable
open class LocalizedNavigationItem: UINavigationItem, Localizable {
    @IBInspectable
    public var localizedKey: String? = "" {
        didSet {
            if let key = localizedKey {
                localized = Localized[dynamicMember: key]
            } else {
                localized = nil
            }
        }
    }
    
    public var localized: Localized? = nil {
        didSet {
            reloadLanguage()
        }
    }
    
    public var isAutoFittingSize: Bool = true
    
    @objc public func reloadLanguage() {
        title = localized?.description
    }
    
    override init(title: String) {
        super.init(title: title)
        registerForLanguageChange(target: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerForLanguageChange(target: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

@IBDesignable
open class LocalizedTextView: UITextView, Localizable {
    @IBInspectable
    public var localizedKey: String? = "" {
        didSet {
            if let key = localizedKey {
                localized = Localized[dynamicMember: key]
            } else {
                localized = nil
            }
        }
    }
    
    public var localized: Localized? = nil {
        didSet {
            reloadLanguage()
        }
    }
    
    public var isAutoFittingSize: Bool = true
    
    @objc public func reloadLanguage() {
        text = localized?.description
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        registerForLanguageChange(target: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerForLanguageChange(target: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

