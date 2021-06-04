// Iterator.swift

import Combine
import Foundation

extension Publishers {
    public struct Iterator<Sequence: Swift.Sequence, Upstream: Publisher>: Publisher {

        public typealias Output = Array<Upstream.Output>

        public typealias Failure = Upstream.Failure

        public typealias Generator = (Sequence.Element) -> Upstream

        class Subscription<Subscriber: Combine.Subscriber, Sequence: Swift.Sequence, Upstream: Publisher>: Combine.Subscription where Subscriber.Failure == Upstream.Failure, Subscriber.Input == Array<Upstream.Output> {

            private var subscriber: Subscriber?

            private let _cancellableQ: DispatchQueue = .init(
                label: "Publishers.Iterator.cacnellables", attributes: .concurrent)
            private var _cancellables: Set<AnyCancellable> = []
            private var cancellables: Set<AnyCancellable> {
                get { _cancellableQ.sync { _cancellables } }
                set { _cancellableQ.async(flags: .barrier) { self._cancellables = newValue } }
            }

            private let _valuesQ: DispatchQueue = .init(
                label: "Publishers.Iterator.values", attributes: .concurrent)
            private var _values: Array<Upstream.Output> = []
            private var values: Array<Upstream.Output> {
                get { _valuesQ.sync { _values } }
                set { _valuesQ.async(flags: .barrier) { self._values = newValue } }
            }

            private let operationQueue: OperationQueue
            private let sequence: Sequence
            private let returnOnError: Bool
            private let action: (Sequence.Element) -> Upstream

            init(_ sequence: Sequence, concurrently size: Int?, returnOnError: Bool, action: @escaping ((Sequence.Element) -> Upstream), subscriber subject: Subscriber) {

                assert(size != nil && size! > 0, "concurrently count should always never equal to 0")

                subscriber = subject

                operationQueue = OperationQueue()
                operationQueue.maxConcurrentOperationCount = size ?? 1

                self.sequence = sequence
                self.action = action
                self.returnOnError = returnOnError
            }

            func fire() {
                var it = sequence.makeIterator()
                var cancelled = false
                while let object = it.next() {
                    operationQueue.addOperation { [weak self] in
                        guard let `self` = self, cancelled == false else { return }
                        let group = DispatchGroup()
                        var leaved = false

                        func leaveGroupSafely() {
                            guard leaved == false else { return }
                            group.leave()
                            leaved = true
                        }

                        group.enter()
                        let cancellable = self.action(object)
                            .handleEvents(receiveCancel: {
                                leaveGroupSafely()
                            })
                            .sink { [weak self] completion in
                                guard case .failure = completion,
                                      let `self` = self,
                                      self.returnOnError else { return leaveGroupSafely() }
                                cancelled = true
                                self.subscriber?.receive(completion: completion)
                                leaveGroupSafely()
                            } receiveValue: { [weak self] value in
                                guard let `self` = self else { return }
                                self.values.append(value)
                                leaveGroupSafely()
                            }
                        self.cancellables.insert(cancellable)
                        group.wait()
                    }
                }
                DispatchQueue.global().async {
                    if self.operationQueue.isSuspended == false {
                        self.operationQueue.waitUntilAllOperationsAreFinished()
                    }
                    guard cancelled == false else { return }
                    _ = self.subscriber?.receive(self.values)
                    self.subscriber?.receive(completion: .finished)
                }
            }

            func request(_ demand: Subscribers.Demand) { }

            func cancel() {
                operationQueue.cancelAllOperations()
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
            let subscription = Subscription(sequence, concurrently: concurrentlyCount, returnOnError: returnOnError, action: generator, subscriber: subscriber)
            subscriber.receive(subscription: subscription)
            subscription.fire()
        }
    }
}
