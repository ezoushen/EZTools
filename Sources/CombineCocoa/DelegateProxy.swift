// DelegateProxy.swift

import Combine
import UIKit

struct DelegateProxyPublisher<Control: UIControl, Delegate: NSObjectProtocol>: Publisher {
    typealias Output = Control
    
    typealias Failure = Never
    
    let subject: Control
    
    let delegate: Delegate?
    
    func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
        let subscription = DelegateProxySubscription(
            subscriber: subscriber,
            subject: subject,
            forwordingDelegate: delegate
        )
        subscriber.receive(subscription: subscription)
    }
}

final class DelegateProxySubscription<SubscribeType: Subscriber, Control: UIControl, Delegate: NSObjectProtocol>
: NSObject, Subscription, UITextFieldDelegate {
    var subscriber: SubscribeType?
    
    weak var subject: Control?
    weak var forwordingDelegate: Delegate?
    
    init(subscriber: SubscribeType, subject: Control, forwordingDelegate: Delegate?) {
        self.subscriber = subscriber
        self.subject = subject
        self.forwordingDelegate = forwordingDelegate
        
        super.init()
    }
    
    func request(_ demand: Subscribers.Demand) {
        
    }
    
    func cancel() {
        subscriber = nil
    }
}

