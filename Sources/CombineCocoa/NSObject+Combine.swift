// NSObject+Combine.swift

import Combine
import Foundation

// MARK: Deallocation

private var lifecycleTokenKey: UInt32 = 0

public extension CBPublishers where Base: NSObject {

    private class LifecycleToken {
        let deallocatedSubject = PassthroughSubject<Void, Never>()
        deinit {
            deallocatedSubject.send()
        }
    }

    private var token: LifecycleToken {
        guard let token = objc_getAssociatedObject(base, &lifecycleTokenKey) as? LifecycleToken else {
            let t = LifecycleToken()
            objc_setAssociatedObject(base, &lifecycleTokenKey, t, .OBJC_ASSOCIATION_RETAIN)
            return t
        }
        return token
    }

    func deallocated() -> AnyPublisher<Void, Never> {
        token.deallocatedSubject.eraseToAnyPublisher()
    }
}

// MARK: KVO

public extension CBPublishers where Base: NSObject {
    func observe<T>(for key: String, type: T.Type, options: NSKeyValueObservingOptions = [.initial, .new]) -> KVOPublisher<Base, T> {
        KVOPublisher<Base, T>(subject: base, keyPath: key, options: options)
    }
    
    func observe<T>(for key: KeyPath<Base, T>, options: NSKeyValueObservingOptions = [.initial, .new]) -> NSObject.KeyValueObservingPublisher<Base, T> {
        base.publisher(for: key, options: options)
    }
}

public struct KVOPublisher<T: NSObject, Output>: Combine.Publisher {
    public typealias Failure = Never

    public let subject: T
    public let keyPath: String
    public let options: NSKeyValueObservingOptions

    public func receive<S>(subscriber: S)
    where S : Subscriber, Never == S.Failure, Output == S.Input {
        let subscription = Subscription(
            subject: subject,
            subscriber: subscriber,
            keyPath: keyPath,
            options: options)
        subscriber.receive(subscription: subscription)
    }

    public class Subscription<S: Combine.Subscriber>: NSObject, Combine.Subscription
    where S.Input == Output {
        private let keyPath: String
        private let options: NSKeyValueObservingOptions

        private var subscriber: S?
        private var subject: NSObject?

        private var waitingForCancellation: Bool = false
        private var lock = os_unfair_lock()

        private var demand: Subscribers.Demand = .none

        init(subject: NSObject, subscriber: S, keyPath: String, options: NSKeyValueObservingOptions) {
            self.subscriber = subscriber
            self.keyPath = keyPath
            self.options = options
            self.subject = subject

            super.init()
        }

        public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            sendValue(change: change, key: .oldKey)
            sendValue(change: change, key: .newKey)
        }

        private func sendValue(change: [NSKeyValueChangeKey : Any]?, key: NSKeyValueChangeKey) {
            guard change?.keys.contains(key) == true,
                  let value = change?[key] as? Output
            else { return }
            send(value: value)
        }

        private func send(value: S.Input) {
            guard demand > 0 else { return }
            demand -= 1
            demand += subscriber?.receive(value) ?? .none
        }

        func subscribe() {
            os_unfair_lock_lock(&lock)
            subject?.addObserver(
                self, forKeyPath: keyPath, options: options, context: nil)
            if waitingForCancellation {
                removeObservation()
            }
            os_unfair_lock_unlock(&lock)
        }

        public func request(_ demand: Subscribers.Demand) {
            self.demand += demand
            self.subscribe()
        }

        public func cancel() {
            if os_unfair_lock_trylock(&lock) {
                removeObservation()
                os_unfair_lock_unlock(&lock)
            } else {
                waitingForCancellation = true
            }
        }

        private func removeObservation() {
            subject?.removeObserver(self, forKeyPath: keyPath)
            subscriber?.receive(completion: .finished)
            subject = nil
            subscriber = nil
        }
    }
}
