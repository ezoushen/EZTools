// Localized.swift

import Foundation

@dynamicCallable
@dynamicMemberLookup
public struct Localized {
    /// Locale use for formatting string
    public static var locale: Locale? = nil

    @usableFromInline
    static var cache = NSCache<NSString, NSString>()

    @inline(__always)
    @inlinable
    static func loadFromCache(key: String) -> String? {
        cache.object(forKey: key as NSString) as? String
    }
    @inline(__always)
    @inlinable
    static func updateCache(key: String, value: String) {
        cache.setObject(key as NSString, forKey: value as NSString)
    }

    /// Invalidate cached strings and overriden data in debug mode
    public static func invalidateCache() {
        cache.removeAllObjects()
    }

    public static subscript(dynamicMember key: String) -> Localized {
        Localized(key: key)
    }

#if DEBUG
    public static subscript(dynamicMember key: String) -> String {
        get { Localized(key: key).description }
        set { updateCache(key: key, value: newValue) }
    }
#else
    public static subscript(dynamicMember key: String) -> String {
        Localized(key: key).description
    }
#endif
    @inline(__always)
    @inlinable
    public subscript(dynamicMember key: String) -> Localized {
        Localized(key: key, args: args, tableName: tableName, comment: comment)
    }

    @inline(__always)
    @inlinable
    public subscript(dynamicMember key: String) -> String {
        Localized(key: key, args: args, tableName: tableName, comment: comment).description
    }

    @usableFromInline let tableName: String?
    @usableFromInline let bundle: Bundle
    @usableFromInline let comment: String?
    @usableFromInline let key: String
    @usableFromInline var args: [CVarArg]

    @usableFromInline init(key: String,
                           args: [CVarArg] = [],
                           tableName: String? = nil,
                           bundle: Bundle = .main,
                           comment: String? = nil)
    {
        self.key = key
        self.bundle = bundle
        self.args = args
        self.tableName = tableName
        self.comment = comment
    }

    public init(_ key: String,
         tableName: String? = nil,
         bundle: Bundle = .main,
         comment: String? = nil,
         args: CVarArg...)
    {
        self.key = key
        self.bundle = bundle
        self.args = args
        self.tableName = tableName
        self.comment = comment
    }

    @inline(__always)
    @inlinable
    public func callAsFunction(_ args: CVarArg...) -> String {
        var this = self
        this.args = args
        return this.string
    }

    @inline(__always)
    @inlinable
    public func dynamicallyCall(withKeywordArguments pairs: KeyValuePairs<String, CVarArg>) -> String {
        var this = self
        this.args = pairs.map{ $0.value }
        return this.string
    }

    public var string: String {
        let format: String = {
            if let cachedValue = Localized.loadFromCache(key: key) {
                return cachedValue
            }
            let value = load()
            Localized.updateCache(key: key, value: value)
            return value
        }()
        guard args.isEmpty == false, format.isEmpty == false
        else { return format.isEmpty ? key : format }
        return String(format: format, locale: Localized.locale, arguments: args)
    }

    @inline(__always)
    @inlinable
    func load() -> String {
        NSLocalizedString(key, tableName: tableName, comment: comment ?? "")
    }
}

extension Localized: Equatable {
    public static func == (lhs: Localized, rhs: Localized) -> Bool {
        lhs.key == rhs.key
    }
}

extension Localized: CustomStringConvertible {
    @inline(__always)
    @inlinable
    public var description: String {
        string
    }
}

extension Localized: ExpressibleByStringLiteral {
    @inline(__always)
    @inlinable
    public init(stringLiteral value: String) {
        self.init(key: value)
    }
}
