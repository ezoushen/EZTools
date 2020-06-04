// Publishers.swift

import Foundation


public struct CBPublishers<Base> {
    public let base: Base
    
    public init(_ base: Base) {
        self.base = base
    }
}

public protocol Publishee { }

extension Publishee {
    public var publishers: CBPublishers<Self> {
        CBPublishers(self)
    }
}

extension NSObject: Publishee {
    
}
