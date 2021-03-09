// Relay.swift

import Combine

public final class PassthroughRelay<T, E: Error>: Publisher, Subscriber {
    
    public typealias Output = T
    
    public typealias Failure = E
    
    public typealias Input = T
    
    private let subject: PassthroughSubject<T, E> = .init()
    
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

public final class CurrentValueRelay<T, E: Error>: Publisher, Subscriber {
    
    public typealias Output = T
    
    public typealias Failure = E
    
    public typealias Input = T
    
    private let subject: CurrentValueSubject<T, E>
    
    init(_ value: T) {
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
