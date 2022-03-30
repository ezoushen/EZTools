//
//  AsyncCombine.swift
//  
//
//  Created by EZOU on 2022/3/3.
//

import Combine
import Foundation

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
                .sink(receiveCompletion: { _ in
                    continuation.finish()
                }, receiveValue: { value in
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

public struct AsyncThrowingPublisherSequence<P: Publisher>:
    AsyncSequence,
    AsyncIteratorProtocol
{
    public typealias Element = P.Output
    public typealias AsyncIterator = AsyncThrowingPublisherSequence<P>

    private let stream: AsyncThrowingStream<P.Output, Error>
    private var iterator: AsyncThrowingStream<P.Output, Error>.Iterator
    private var cancellable: AnyCancellable?

    public init(
        _ upstream: P,
        bufferingPolicy limit: AsyncThrowingStream<Element, Error>.Continuation.BufferingPolicy = .unbounded)
    {
        var subscription: AnyCancellable?

        stream = AsyncThrowingStream(P.Output.self, bufferingPolicy: limit) { continuation in
            subscription = upstream
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished: continuation.finish(throwing: nil)
                    case .failure(let error): continuation.yield(with: .failure(error))
                    }
                    continuation.finish()
                }, receiveValue: { value in
                    continuation.yield(value)
                })
        }
        cancellable = subscription
        iterator = stream.makeAsyncIterator()
    }

    public func makeAsyncIterator() -> Self {
        return self
    }

    public mutating func next() async throws -> P.Output? {
        try await iterator.next()
    }
}

public extension Publisher {
    var sequence: AsyncThrowingPublisherSequence<Self> {
        AsyncThrowingPublisherSequence(self)
    }
    
    var firstValue: Output {
        get async throws {
            for try await value in sequence.prefix(1) {
                return value
            }
            throw CancellationError()
        }
    }
    
    var allValues: [Output] {
        get async throws {
            try await sequence.reduce(into: [Output]()) { $0.append($1) }
        }
    }
}

public extension Publisher where Self.Failure == Never {
    var sequence: AsyncPublisherSequence<Self> {
        AsyncPublisherSequence(self)
    }
    
    var firstValue: Output {
        get async throws {
            for await value in sequence.prefix(1) {
                return value
            }
            throw CancellationError()
        }
    }
    
    var allValues: [Output] {
        get async {
            await sequence.reduce(into: [Output]()) { $0.append($1) }
        }
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
