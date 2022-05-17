//
//  AnyAsyncSequence.swift
//  
//
//  Created by EZOU on 2022/5/17.
//

import Foundation

public struct AnyAsyncSequence<Element>: AsyncSequence {
    public class AsyncIterator: AsyncIteratorProtocol {
        private var _next: () async throws -> Element?
        
        init<I: AsyncIteratorProtocol>(_ iterator: I) where I.Element == Element {
            var iterator = iterator
            _next = { try await iterator.next() }
        }
        
        public func next() async throws -> Element? {
            try await _next()
        }
    }
    
    private let _makeAsyncIterator: () -> AsyncIterator
    
    public init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
        _makeAsyncIterator = { AsyncIterator(sequence.makeAsyncIterator()) }
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        _makeAsyncIterator()
    }
}

extension AsyncSequence {
    public func eraseToAnyAsyncSequence() -> AnyAsyncSequence<Element> {
        AnyAsyncSequence(self)
    }
}
