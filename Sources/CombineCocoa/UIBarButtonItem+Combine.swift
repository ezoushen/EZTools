// UIBarButtonItem+Combine.swift

import UIKit
import Combine

public struct UIBarButtonItemPublisher: Publisher {
    public typealias Output = Void

    public typealias Failure = Never

    weak var barButtonItem: UIBarButtonItem?

    public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Void == S.Input {
        let subscription = UIBarButtonItemSubscription<S>(
            barButtonItem: barButtonItem, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }

    final class UIBarButtonItemSubscription<S: Subscriber>: NSObject, Subscription where S.Input == Output {
        weak var barButtonItem: UIBarButtonItem?

        weak var previousObject: AnyObject?

        var previousSelector: Selector?

        weak var nextObject: AnyObject?

        var nextSelector: Selector?

        var subscriber: S?

        var demand: Subscribers.Demand = .none

        init(barButtonItem: UIBarButtonItem?, subscriber: S) {
            self.subscriber = subscriber
            self.barButtonItem = barButtonItem

            previousObject = barButtonItem?.target
            previousSelector = barButtonItem?.action

            super.init()

            if let subscription = barButtonItem?.target as? UIBarButtonItemSubscription {
                subscription.nextObject = self
                subscription.nextSelector = #selector(buttonAction(_:))
            }

            barButtonItem?.target = self
            barButtonItem?.action = #selector(buttonAction(_:))
        }

        func request(_ demand: Subscribers.Demand) {
            self.demand = demand
        }

        func cancel() {
            subscriber = nil

            if let previousSubscription = previousObject as? UIBarButtonItemSubscription {
                previousSubscription.nextObject = nextObject
                previousSubscription.nextSelector = nextSelector
            }

            if let nextSubscription = nextObject as? UIBarButtonItemSubscription {
                nextSubscription.previousObject = previousObject
                nextSubscription.previousSelector = previousSelector
            }

            if nextObject == nil {
                barButtonItem?.target = previousObject
                barButtonItem?.action = previousSelector
            }

            nextObject = nil
            nextSelector = nil
            previousObject = nil
            previousSelector = nil
        }

        @objc
        func buttonAction(_ sender: Any?) {
            if let target = previousObject, let action = previousSelector {
                target.performSelector(onMainThread: action, with: sender, waitUntilDone: true)
            }
            if demand > 0 {
                demand -= 1
                if let result = subscriber?.receive(()) {
                    demand += result
                }
            }
        }
    }
}

public extension CBPublishers where Base: UIBarButtonItem {
    var tap: UIBarButtonItemPublisher {
        .init(barButtonItem: base)
    }
}
