// Relays.swift

import Combine

public protocol Relay:
    Publisher,
    Subscriber
where
    Input == Output { }

public protocol ValueRelay: Relay {
    var currentValue: Output { get }
}

public final class PassthroughRelay<T, E: Error>: Relay {
    
    public typealias Output = T
    
    public typealias Failure = E
    
    public typealias Input = T
    
    fileprivate let subject: PassthroughSubject<T, E> = .init()
    
    public init() { }
    
    public func receive<S>(subscriber: S)
    where S : Subscriber, Failure == S.Failure, Output == S.Input {
        subject.receive(subscriber: subscriber)
    }
    
    public func receive(subscription: Subscription) {
        subject.send(subscription: subscription)
    }
    
    public func receive(completion: Subscribers.Completion<E>) {
        subject.send(completion: completion)
    }
    
    public func receive(_ input: T) -> Subscribers.Demand {
        subject.send(input)
        return .unlimited
    }
}

public final class CurrentValueRelay<T, E: Error>: ValueRelay {
    
    public typealias Output = T
    
    public typealias Failure = E
    
    public typealias Input = T
    
    fileprivate let subject: CurrentValueSubject<T, E>
    
    public var currentValue: T {
        subject.value
    }
    
    public init(_ value: T) {
        subject = .init(value)
    }
    
    public func receive<S>(subscriber: S)
    where S : Subscriber, Failure == S.Failure, Output == S.Input {
        subject.receive(subscriber: subscriber)
    }
    
    public func receive(subscription: Subscription) {
        subject.send(subscription: subscription)
    }
    
    public func receive(completion: Subscribers.Completion<E>) {
        subject.send(completion: completion)
    }
    
    public func receive(_ input: T) -> Subscribers.Demand {
        subject.send(input)
        return .unlimited
    }
}

extension Publisher {
    public func subscribe<R: CombineCocoa.Relay>(_ relay: R) -> AnyCancellable
    where
        Failure == R.Failure,
        Output == R.Input
    {
        sink {
            relay.receive(completion: $0)
        } receiveValue: {
            _ = relay.receive($0)
        }
    }
}
