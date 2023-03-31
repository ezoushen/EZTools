//
//  Task+Publisher.swift
//  
//
//  Created by EZOU on 2022/3/4.
//

import Combine
import Foundation

extension Task: Publisher {
    public typealias Output = Success
    
    public func receive<S>(subscriber: S)
    where S : Subscriber, Failure == S.Failure, Success == S.Input {
        let subscription = Subscription(subscriber: subscriber, action: self)
        subscriber.receive(subscription: subscription)
    }
    
    class Subscription<S: Subscriber>: Combine.Subscription
    where S.Input == Output, S.Failure == Failure{
        let action: Task<Output, Failure>
        var subscriber: S?
        var task: Task<Void, Never>?
        
        init(subscriber: S, action: Task<Output, Failure>) {
            self.action = action
            self.subscriber = subscriber
        }
        
        func start() {
            task = Task<Void, Never> { [weak self] in
                guard let subscriber = self?.subscriber,
                      let action = self?.action else { return }
                do {
                    let value = try await action.value
                    _ = subscriber.receive(value)
                    subscriber.receive(completion: .finished)
                } catch let error as Failure {
                    subscriber.receive(completion: .failure(error))
                } catch {
                    fatalError("Unhandled error \(type(of: error)) \(error)")
                }
            }
        }
        
        func request(_ demand: Subscribers.Demand) {
            guard demand > 0 else { return }
            start()
        }
        
        func cancel() {
            task?.cancel()
            subscriber = nil
        }
    }
}
