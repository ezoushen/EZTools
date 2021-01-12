// Layout.swift

import UIKit

@propertyWrapper
public struct Layout<T> {
    let keyPath: AnyKeyPath
    
    @available(*, unavailable)
    public var wrappedValue: T {
        fatalError("Do not access wrapped value directly")
    }
    
    public static subscript<EnclosingSelf: Layoutee>(
        _enclosingInstance observed: EnclosingSelf,
        wrapped wrappedKeyPath: KeyPath<EnclosingSelf, T>,
        storage storageKeyPath: KeyPath<EnclosingSelf, Layout<T>>
    ) -> T {
        let layout = observed[keyPath: storageKeyPath]
        let manager = observed.layoutManager
        guard let view = manager?[keyPath: layout.keyPath] as? T else {
                fatalError("""
                1. The view is not initialized in the LayoutManager
                2. The name of the vairable doesn't match any in the LayoutManager
                """)
        }
        return view
    }
    
    public init<L: LayoutManager>(_ keyPath: KeyPath<L, T>) {
        self.keyPath = keyPath
    }
}
