// Localized.swift

import Foundation

@dynamicCallable
@dynamicMemberLookup
public struct Localized {
    public static subscript(dynamicMember key: String) -> Localized {
        Localized(key: key)
    }
    
    public static subscript(dynamicMember key: String) -> String {
        Localized(key: key).description
    }
    
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
        Localized(key: key, args: pairs.map{ $0.value }, tableName: tableName, comment: comment).description
    }
}

extension Localized: Equatable {
    public static func == (lhs: Localized, rhs: Localized) -> Bool {
        lhs.description == rhs.description
    }
}

extension Localized: CustomStringConvertible {
    public var description: String {
        String(format: NSLocalizedString(key, tableName: tableName, comment: comment ?? ""), arguments: args)
    }
}

extension Localized: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(key: value)
    }
}
