//
//  ObserbedProperty.swift
//  
//
//  Created by EZOU on 2022/7/15.
//

import Combine

@propertyWrapper
public class ObservedProperty<T> {
    private let subject: CurrentValueSubject<T, Never>
    private var value: T

    public static subscript<EnclosingSelf>(
        _enclosingInstance observed: EnclosingSelf,
        wrapped wrappedKeyPath: KeyPath<EnclosingSelf, T>,
        storage storageKeyPath: KeyPath<EnclosingSelf, ObservedProperty<T>>
    ) -> T {
        get {
            let property = observed[keyPath: storageKeyPath]
            return property.value
        }
        set {
            let property = observed[keyPath: storageKeyPath]
            property.subject.send(newValue)
            property.value = newValue
        }
    }

    public var wrappedValue: T {
        get { fatalError("Please do not access this value directly") }
        set { fatalError("Please do not change this value directly") }
    }

    public init(wrappedValue: T) {
        self.value = wrappedValue
        self.subject = .init(wrappedValue)
    }

    public var projectedValue: AnyPublisher<T, Never> {
        subject.eraseToAnyPublisher()
    }
}
