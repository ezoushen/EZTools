// UIControl+Combine.swift

import UIKit
import Combine

public struct UIControlPublisher<Control: UIControl>: Publisher {
    
    public typealias Output = Control
    
    public typealias Failure = Never
    
    weak var control: Control?
    
    let controlEvent: UIControl.Event
    
    public func receive<S>(subscriber: S) where S : Subscriber, S.Failure == UIControlPublisher.Failure, S.Input == UIControlPublisher.Output {
        let subscription = UIControlSubscription(
            subscriber: subscriber,
            control: control,
            event: controlEvent
        )
        subscriber.receive(subscription: subscription)
    }
}

public final class UIControlSubscription<SubscribeType: Subscriber, Control: UIControl>: Subscription where SubscribeType.Input == Control {
    weak var control: Control?
    var subscriber: SubscribeType?
    let event: UIControl.Event
    
    init(subscriber: SubscribeType, control: Control?, event: UIControl.Event) {
        self.subscriber = subscriber
        self.control = control
        self.event = event
        self.control?.addTarget(self, action: #selector(eventAction), for: event)
    }
    
    public func request(_ demand: Subscribers.Demand) { }
    
    public func cancel() {
        subscriber = nil
    }
    
    @objc
    private func eventAction() {
        guard let control = control else { return }
        _ = subscriber?.receive(control)
    }
}

public extension CBPublishers where Base: UIControl {
    func event(_ event: UIControl.Event) -> UIControlPublisher<Base> {
        .init(control: base, controlEvent: event)
    }
}
