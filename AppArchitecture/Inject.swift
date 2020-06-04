// Inject.swift

import Foundation
import SwiftUI

@propertyWrapper
public class Inject<Value>: ObservableObject {
        
    fileprivate var _value: Value?
    
    public var wrappedValue: Value {
        guard let value = _value else {
            fatalError("Value not injected")
        }
        return value
    }
        
    public init() { }
}

public protocol Injectee { }

extension Injectee where Self: View {
    public func inject<T: ObservableObject>(_ value: T) -> Self {
        _ = environmentObject(value)
        return self
    }
}

extension Injectee where Self: NSObject {
    @discardableResult
    public func inject<T: ObservableObject>(_ value: T) -> Self {
        children(of: Mirror(reflecting: self), recursive: true)
            .forEach { (_, val) in
                if let injecter = val as? Inject<T> {
                    injecter._value = value
                }
            }
        return self
    }
}
