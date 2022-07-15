// Inject.swift

import Foundation
import SwiftUI

@propertyWrapper
public class Inject<Value>: ObservableObject {
        
    fileprivate weak var _reference: AnyObject?
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

            if Value.self is AnyObject.Type {
                guard let value = inject._reference as? Value else {
                    let container = observed.injectContainer
                    let value =  container.load(Value.self)
                    inject._reference = value as? AnyObject
                    return value
                }
                return value
            } else {
                guard let value = inject._value else {
                    let container = observed.injectContainer
                    let value =  container.load(Value.self)
                    inject._value = value
                    return value
                }
                return value
            }
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

    func registerLazily<T>(_ type: T.Type, value: @escaping () -> T) {
        container[String(reflecting: type)] = value
    }
    
    func load<T>(_ type: T.Type) -> T? {
        let key = String(reflecting: type)
        let value = container[key]
        if let value = value as? T {
            return value
        } else if let value = value as? () -> T {
            let lazyValue = value()
            container[key] = lazyValue
            return lazyValue
        } else {
            return nil
        }
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

    @discardableResult
    public func injectLazily<T>(_ value: @escaping () -> T) -> Self {
        injectContainer.registerLazily(T.self, value: value)
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
