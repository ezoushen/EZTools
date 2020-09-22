//  File.swift

import Combine
import UIKit

public struct TogglePublisher: Publisher {
    public typealias Output = Bool
    
    public typealias Failure = Never
    
    let toggle: UISwitch
    
    init(_ toggle: UISwitch) {
        self.toggle = toggle
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
        let subscription = Subscription(subscriber, toggle: toggle)
        subscriber.receive(subscription: subscription)
    }
    
    class Subscription<S: Subscriber>: Combine.Subscription where S.Input == Bool, S.Failure == Never {
        
        var subscriber: S?
        
        var toggle: UISwitch?
        
        init(_ subscriber: S, toggle: UISwitch) {
            self.subscriber = subscriber
            self.toggle = toggle
            
            toggle.addTarget(self, action: #selector(onValueChanged(_:)), for: .valueChanged)
        }
        
        @objc func onValueChanged(_ toggle: UISwitch) {
            _ = subscriber?.receive(toggle.isOn)
        }
        
        func request(_ demand: Subscribers.Demand) {
            
        }
        
        func cancel() {
            subscriber = nil
            toggle = nil
        }
    }
}

extension CBPublishers where Base: UISwitch {
    public var isOn: TogglePublisher {
        return .init(base)
    }
}
