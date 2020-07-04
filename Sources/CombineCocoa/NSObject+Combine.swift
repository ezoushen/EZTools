// NSObject+Combine.swift

import Combine
import Foundation

public extension CBPublishers where Base: NSObject {
    func observe<T>(for key: String, type: T.Type, options: NSKeyValueObservingOptions = [.initial, .new]) -> KVOPublisher<Base, T> {
        KVOPublisher<Base, T>(subject: base, keyPath: key, options: options)
    }
    
    func observe<T>(for key: KeyPath<Base, T>, options: NSKeyValueObservingOptions = [.initial, .new]) -> NSObject.KeyValueObservingPublisher<Base, T> {
        base.publisher(for: key, options: options)
    }
}

public struct KVOPublisher<Object: NSObject, Output>: Publisher {
    
    public typealias Failure = Never
    
    public let subject: Object
    public let keyPath: String
    public let options: NSKeyValueObservingOptions
    
    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = KVOSubscription(subject: subject, subscriber: subscriber, keyPath: keyPath, options: options)
        subscriber.receive(subscription: subscription)
        subscription.subscribe()
    }
}

public class KVOSubscription<SubscribeType: Subscriber, Output>: NSObject, Subscription where SubscribeType.Input == Output {
    private var context: Int = 0
    private let keyPath: String
    private let options: NSKeyValueObservingOptions
    private var subscriber: SubscribeType?
    private var subject: NSObject?
    
    init(subject: NSObject, subscriber: SubscribeType, keyPath: String, options: NSKeyValueObservingOptions) {
        self.subscriber = subscriber
        self.keyPath = keyPath
        self.options = options
        self.subject = subject
        
        super.init()
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard self.keyPath == keyPath,
            let value = change?[.newKey] as? Output else { return }
        _ = subscriber?.receive(value)
    }
    
    func subscribe() {
        subject?.addObserver(self, forKeyPath: keyPath, options: options, context: &context)
    }
    
    public func request(_ demand: Subscribers.Demand) { }
    
    public func cancel() {
        subject?.removeObserver(self, forKeyPath: keyPath)
        subject = nil
        subscriber = nil
    }
}
