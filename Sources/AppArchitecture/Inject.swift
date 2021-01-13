// Inject.swift

import Foundation
import SwiftUI

@propertyWrapper
public class Inject<Value>: ObservableObject {
        
    fileprivate var _value: Value?
    
    public var wrappedValue: Value {
        fatalError("Do not access wrappedValue directly")
    }
        
    public init() { }
    
    public static subscript<EnclosingSelf: Injectee & AnyObject>(
        _enclosingInstance observed: EnclosingSelf,
        wrapped wrappedKeyPath: KeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: KeyPath<EnclosingSelf, Inject<Value>>
    ) -> Value {
        let currentValue: Value? = {
            let inject = observed[keyPath: storageKeyPath]
            guard let value = inject._value else {
                let container = observed.injectContainer
                inject._value = container.load(Value.self)
                return inject._value
            }
            return value
        }()
        
        guard let result = currentValue else {
            fatalError("Value not injected")
        }
        return result
    }
}

public protocol Injectee { }

extension Injectee where Self: View {
    public func inject<T: ObservableObject>(_ value: T) -> Self {
        _ = environmentObject(value)
        return self
    }
}

fileprivate class InjectContainer {
    static var key: UInt = 0x123
    
    var container: [String: Any] = [:]
    
    func register<T>(_ type: T.Type, value: T) {
        container[String(reflecting: type)] = value
    }
    
    func load<T>(_ type: T.Type) -> T? {
        container[String(reflecting: type)] as? T
    }
    
    func revoke<T>(_ type: T.Type) {
        container[String(reflecting: type)] = nil
    }
}

extension Injectee where Self: AnyObject {
    @discardableResult
    public func inject<T>(_ value: T) -> Self {
        injectContainer.register(T.self, value: value)
        return self
    }
    
    fileprivate var injectContainer: InjectContainer {
        guard let container = objc_getAssociatedObject(self, &InjectContainer.key) as? InjectContainer else {
            let container = InjectContainer()
            objc_setAssociatedObject(self, &InjectContainer.key, container, .OBJC_ASSOCIATION_RETAIN)
            return container
        }
        return container
    }
}
