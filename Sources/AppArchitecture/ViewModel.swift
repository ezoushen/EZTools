// ViewModel.swift

import SwiftUI
import Combine

enum ViewModelKey {
    static var cancellables:    UInt = 0x1
    static var willDismiss:     UInt = 0x2
}

public typealias NavigationSubject<Data> = PassthroughSubject<Data, Never>

public protocol ViewModel: AnyObject {
    var cancellables: Set<AnyCancellable>  { get set }
    var willDismiss: PassthroughSubject<Void, Never> { get }
    
    func dismiss()
}

extension ViewModel {
    public var cancellables: Set<AnyCancellable> {
        get {
            guard let cancellables = objc_getAssociatedObject(self, &ViewModelKey.cancellables) as? NSSet else {
                let cancellables = Set<AnyCancellable>()
                defer {
                    objc_setAssociatedObject(self, &ViewModelKey.cancellables, cancellables as NSSet, .OBJC_ASSOCIATION_RETAIN)
                }
                return cancellables
            }
            return cancellables as! Set<AnyCancellable>
        }
        set {
            objc_setAssociatedObject(self, &ViewModelKey.cancellables, newValue as NSSet, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    public var willDismiss: PassthroughSubject<Void, Never> {
        guard let willDismiss = objc_getAssociatedObject(self, &ViewModelKey.willDismiss) as? PassthroughSubject<Void, Never> else {
            let willDismiss = PassthroughSubject<Void, Never>()
            objc_setAssociatedObject(self, &ViewModelKey.willDismiss, willDismiss, .OBJC_ASSOCIATION_RETAIN)
            return willDismiss
        }
        return willDismiss
    }
    
    public func dismiss() {
        willDismiss.send()
    }
}

extension ViewModel where Self: ObservableObject {
    public var bindings: Bindable<Self> {
        .init(self)
    }
}

public final class EmptyViewModel: ViewModel, ObservableObject {
    public init() { }
}

@dynamicMemberLookup
public struct Bindable<T> {
    var value: T
    
    init(_ value: T) {
        self.value = value
    }
    
    public subscript<Subject>(dynamicMember keyPath: ReferenceWritableKeyPath<T, Subject>) -> Binding<Subject> {
        Binding<Subject>(
            get: { self.value[keyPath: keyPath] },
            set: { self.value[keyPath: keyPath] = $0 }
        )
    }
}

extension Bindable where T: AnyObject {
    public subscript<Subject>(dynamicMember keyPath: ReferenceWritableKeyPath<T, Subject>) -> Binding<Subject> {
        Binding<Subject>(
            get: { [unowned value = self.value] in value[keyPath: keyPath] },
            set: { [unowned value = self.value] in value[keyPath: keyPath] = $0 }
        )
    }
}

@propertyWrapper
public final class Relay<S: Subject>: Subject {
    
    public typealias Output = S.Output
    
    public typealias Failure = S.Failure
    
    let subject: S
    
    public init(_ subject: S) {
        self.subject = subject
    }
    
    public var projectedValue: AnySubscriber<Output, Failure> {
        AnySubscriber(subject)
    }
    
    public var wrappedValue: AnyPublisher<Output, Failure> {
        subject.eraseToAnyPublisher()
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        subject.receive(subscriber: subscriber)
    }

    public func send(_ value: S.Output) {
        subject.send(value)
    }
    
    public func send(completion: Subscribers.Completion<S.Failure>) {
        subject.send(completion: completion)
    }
    
    public func send(subscription: Subscription) {
        subject.send(subscription: subscription)
    }
}
