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

            init(_ sequence: Sequence, concurrently size: Int?, returnOnErorr: Bool, action: @escaping ((Sequence.Element) -> Upstream), subscriber subject: Subscriber) {

                assert(size != nil && size! > 0, "concurrently count should always never equal to 0")

                subscriber = subject

                operationQueue = OperationQueue()
                operationQueue.maxConcurrentOperationCount = size ?? 1

                var it = sequence.makeIterator()

                while let object = it.next() {
                    operationQueue.addOperation { [weak self] in
                        let group = DispatchGroup()
                        group.enter()
                        let cancellable = action(object)
                            .sink { [weak self] completion in
                                guard case .failure = completion,
                                      returnOnErorr,
                                      let `self` = self else { return }
                                self.subscriber?.receive(completion: completion)
                            } receiveValue: { [weak self] value in
                                guard let `self` = self else { return }
                                self.values.append(value)
                                group.leave()
                            }

                        guard let `self` = self else { return }
                        self.cancellables.insert(cancellable)

                        group.wait()
                    }
                }
                DispatchQueue.global().async {
                    self.operationQueue.waitUntilAllOperationsAreFinished()
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
            let subscription = Subscription(sequence, concurrently: concurrentlyCount, returnOnErorr: returnOnError, action: generator, subscriber: subscriber)
            subscriber.receive(subscription: subscription)
        }
    }
}
