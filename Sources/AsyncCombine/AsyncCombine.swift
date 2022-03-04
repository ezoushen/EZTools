//
//  AsyncCombine.swift
//  
//
//  Created by EZOU on 2022/3/3.
//

import Combine
import Foundation

public struct Single<Output, Failure>: Publisher where Failure: Error{

    let publisher: AnyPublisher<Output, Failure>

    public init<P: Publisher>(_ publisher: P) where P.Output == Output, P.Failure == Failure {
        self.publisher = publisher.eraseToAnyPublisher()
    }

    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        publisher.first().receive(subscriber: subscriber)
    }
}

extension Publisher {
    public func asSingle() -> Single<Output, Failure> {
        Single(self)
    }
}

extension Single {
    public func getResult() async throws -> Output? {
        var cancellables: Set<AnyCancellable> = []
        return try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Output?, Error>) in
            var result: Output? = nil
            self.sink { completion in
                switch completion {
                case .finished:
                    continuation.resume(returning: result)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            } receiveValue: { output in
                result = output
            }
            .store(in: &cancellables)
        }
    }
}

extension Single where Failure == Never {
    public func getResult() async -> Output? {
        var cancellables: Set<AnyCancellable> = []
        return await withCheckedContinuation {
            (continuation: CheckedContinuation<Output?, Never>) in
            var result: Output? = nil
            self.sink { completion in
                switch completion {
                case .finished:
                    continuation.resume(returning: result)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            } receiveValue: { output in
                result = output
            }
            .store(in: &cancellables)
        }
    }
}

extension Publisher {
    public func getSingleResult() async throws -> Output? {
        return try await asSingle().getResult()
    }
    
    public func getResult() async throws -> [Output] {
        var cancellables: Set<AnyCancellable> = []
        return try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<[Output], Error>) in
            var results: [Output] = []
            self.sink { completion in
                switch completion {
                case .finished:
                    continuation.resume(returning: results)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            } receiveValue: { output in
                results.append(output)
            }
            .store(in: &cancellables)
        }
    }
}

extension Publisher where Failure == Never {
    public func getSingleResult() async -> Output? {
        return await asSingle().getResult()
    }
    
    public func getResult() async -> [Output] {
        var cancellables: Set<AnyCancellable> = []
        return await withCheckedContinuation {
            (continuation: CheckedContinuation<[Output], Never>) in
            var results: [Output] = []
            self.collect().sink { completion in
                switch completion {
                case .finished:
                    continuation.resume(returning: results)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            } receiveValue: { output in
                results = output
            }
            .store(in: &cancellables)
        }
    }
}

// reference: https://trycombine.com/posts/combine-async-sequence-1/
public struct AsyncPublisherSequence<P: Publisher>:
    AsyncSequence,
    AsyncIteratorProtocol
where
    P.Failure == Never
{
    public typealias Element = P.Output
    public typealias AsyncIterator = AsyncPublisherSequence<P>

    private let stream: AsyncStream<P.Output>
    private var iterator: AsyncStream<P.Output>.Iterator
    private var cancellable: AnyCancellable?

    public init(
        _ upstream: P,
        bufferingPolicy limit: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded)
    {
        var subscription: AnyCancellable?

        stream = AsyncStream(P.Output.self, bufferingPolicy: limit) { continuation in
            subscription = upstream
                .sink(receiveValue: { value in
                    continuation.yield(value)
                })
        }
        cancellable = subscription
        iterator = stream.makeAsyncIterator()
    }

    public func makeAsyncIterator() -> Self {
        return self
    }

    public mutating func next() async -> P.Output? {
        await iterator.next()
    }
}

public extension Publisher where Self.Failure == Never {
    var sequence: AsyncPublisherSequence<Self> {
        AsyncPublisherSequence(self)
    }
}

extension Future {
    public static func asyncThrowing(_ block: @escaping () async throws -> Output) -> Future<Output, Failure> {
        Future { resolver in
            Task {
                do {
                    let output = try await block()
                    resolver(.success(output))
                } catch let error as Failure {
                    resolver(.failure(error))
                }
            }
        }
    }
}

extension Future where Failure == Never {
    public static func async(_ block: @escaping () async -> Output) -> Future<Output, Failure> {
        Future { resolver in
            Task {
                let output = await block()
                resolver(.success(output))
            }
        }
    }
}
