// Localized.swift

import Foundation

@dynamicCallable
@dynamicMemberLookup
public struct Localized {
    private static let cache: NSCache<NSString, NSString> = .init()

    public static subscript(dynamicMember key: String) -> Localized {
        Localized(key: key)
    }

#if DEBUG
    private static var overridenData: [String: String] = [:]

    public static subscript(dynamicMember key: String) -> String {
        get { Localized(key: key).description }
        set { overridenData[key] = newValue }
    }
#else
    public static subscript(dynamicMember key: String) -> String {
        Localized(key: key).description
    }
#endif
    
    public subscript(dynamicMember key: String) -> Localized {
        Localized(key: key, args: args, tableName: tableName, comment: comment)
    }
    
    public subscript(dynamicMember key: String) -> String {
        Localized(key: key, args: args, tableName: tableName, comment: comment).description
    }

    let tableName: String?
    let bundle: Bundle
    let comment: String?
    let key: String
    let args: [CVarArg]
    
    private init(key: String, args: [CVarArg] = [], tableName: String? = nil, bundle: Bundle = .main, comment: String? = nil) {
        self.key = key
        self.bundle = bundle
        self.args = args
        self.tableName = tableName
        self.comment = comment
    }
    
    public static func callAsFunction(tableName: String? = nil, bundle: Bundle = .main, comment: String? = nil) -> Localized {
        Localized(key: "", args: [], tableName: tableName, comment: comment)
    }
    
    public func callAsFunction(_ args: CVarArg...) -> String {
        Localized(key: key, args: args, tableName: tableName, comment: comment).description
    }
    
    public func dynamicallyCall(withKeywordArguments pairs: KeyValuePairs<String, CVarArg>) -> String {
        Localized(key: key, args: pairs.map{ $0.value }, tableName: tableName, comment: comment).string
    }

    public var string: String {
        let cachedValue = Self.cache.object(forKey: key as NSString) as? String
#if DEBUG
        let format = Self.cache.object(forKey: key as NSString) as? String
            ?? Localized.overridenData[key]
            ?? NSLocalizedString(key, tableName: tableName, comment: comment ?? "")
#else
        let format = Self.cache.object(forKey: key as NSString) as? String
            ?? NSLocalizedString(key, tableName: tableName, comment: comment ?? "")
#endif
        if cachedValue == nil {
            Self.cache.setObject(format as NSString, forKey: key as NSString)
        }
        guard args.isEmpty == false, format.isEmpty == false
        else { return format.isEmpty ? key : format }
        return String(format: format, arguments: args)
    }
}

extension Localized: Equatable {
    public static func == (lhs: Localized, rhs: Localized) -> Bool {
        lhs.key == rhs.key
    }
}

extension Localized: CustomStringConvertible {
    public var description: String {
        string
    }
}

extension Localized: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(key: value)
    }
}
