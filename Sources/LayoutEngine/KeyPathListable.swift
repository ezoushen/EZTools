// KeyPathListable.swift

import Foundation

public protocol KeyPathListable {
    init()

    var valuesAsDictionary: [String: Any] { get }
    var allKeyPaths: [String: PartialKeyPath<Self>] { get }
}

public extension KeyPathListable {
    var valuesAsDictionary: [String: Any] {
        { () -> [Mirror.Child] in
            func findAllChildren(mirror: Mirror) -> [Mirror.Child] {
                guard let superMirror = mirror.superclassMirror else {
                    return Array(mirror.children)
                }
                return mirror.children + findAllChildren(mirror: superMirror)
            }
            return findAllChildren(mirror: Mirror(reflecting: self))
        }().reduce(into: [String: Any]()) { (dict, tuple) in
            guard case let (label?, value) = tuple else { return }
            dict[label] = value
        }
    }

    var allKeyPaths: [String: PartialKeyPath<Self>] {
        Self().valuesAsDictionary
            .reduce(into: [String: PartialKeyPath<Self>]()) {
                (dict, tuple) in
                dict[tuple.key] = \Self.valuesAsDictionary[tuple.key]
            }
    }
}
