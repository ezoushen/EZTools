// Iterator.swift

import Combine
import Foundation

extension Publishers {
    public struct Iterator<Sequence: Swift.Sequence, Upstream: Publisher>: Publisher {
        
        public typealias Output = Array<Upstream.Output>
        
        public typealias Failure = Upstream.Failure
        
        public typealias Generator = (Sequence.Element) -> Upstream
        
        class Subscription<Subscriber: Combine.Subscriber, Sequence: Swift.Sequence, Upstream: Publisher>: Combine.Subscription where Subscriber.Failure == Upstream.Failure, Subscriber.Input == Array<Upstream.Output> {

            private let concurrentQueue = DispatchQueue(label: "com.ezoushen.Iterator.concurrent", attributes: .concurrent)
            private let barrierQueue = DispatchQueue(label: "com.ezoushen.Iterator.barrier", attributes: .concurrent)
            
            private let semaphore: DispatchSemaphore?
            private let group: DispatchGroup
            
            private var workItem: DispatchWorkItem!
            private var subscriber: Subscriber?
            
            init(_ sequence: Sequence, concurrently size: Int?, returnOnErorr: Bool, action: @escaping ((Sequence.Element) -> Upstream), subscriber subject: Subscriber) {
                
                assert(size != nil && size! > 0, "concurrently count should always never equal to 0")
                
                subscriber = subject
                
                semaphore = size == nil
                    ? nil
                    : DispatchSemaphore(value: size!)
                
                group = DispatchGroup()
                
                workItem = DispatchWorkItem { [weak self] in
                    guard let `self` = self else { return }
                    
                    let cancellables = NSMutableArray()
                    var values: Array<Upstream.Output> = []
                    
                    var it = sequence.makeIterator()

                    while let object = it.next() {
                        
                        self.group.enter()
                        self.semaphore?.wait()
                        
                        let cancellable = action(object)
                        .sink(receiveCompletion: { [unowned self] completion in
                            defer {
                                self.semaphore?.signal()
                                self.group.leave()
                            }
                            
                            guard case .failure = completion, returnOnErorr else { return }
                            
                            DispatchQueue.main.async {
                                self.subscriber?.receive(completion: completion)
                            }
                        }, receiveValue: { [unowned self] value in
                            self.barrierQueue.sync(flags: .barrier) {
                                values.append(value)
                            }
                        })
                        
                        self.barrierQueue.sync(flags: .barrier) {
                            cancellables.add(cancellable)
                        }
                    }
                    
                    self.group.notify(queue: .main) {
                        defer {
                            self.subscriber?.receive(completion: .finished)
                        }
                        _ = self.subscriber?.receive(values)
                        cancellables.removeAllObjects()
                    }
                }
            }
            
            func fire() {
                concurrentQueue.async(execute: workItem)
            }
            
            func request(_ demand: Subscribers.Demand) { }
            
            func cancel() {
                workItem.cancel()
                subscriber = nil
            }
        }
        
        private let sequence: Sequence
        
        private let concurrentlyCount: Int?
        
        private let returnOnError: Bool
        
        private let generator: Generator
        
        public init(_ sequence: Sequence, concurrently size: Int? = 1, returnOnErorr flag: Bool = true, action: @escaping Generator) {
            self.sequence = sequence
            self.concurrentlyCount = size
            self.returnOnError = flag
            self.generator = action
        }
        
        public func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            let subscription = Subscription(sequence, concurrently: concurrentlyCount, returnOnErorr: returnOnError, action: generator, subscriber: subscriber)
            subscriber.receive(subscription: subscription)
            subscription.fire()
        }
    }
}
