// Layout.swift

import UIKit

public class AnyLayout {
    var anyManager: Any? = nil
    var name: String = ""
    var keyPath: AnyKeyPath? = nil
}

@propertyWrapper
public class Layout<T: NSObject>: AnyLayout {
    public var wrappedValue: T {
        guard let keyPath = keyPath,
            let view = manager[keyPath: keyPath] as? T else {
                fatalError("""
                1. The view is not initialized in the LayoutManager
                2. The name of the vairable doesn't match any in the LayoutManager
                """)
        }
        return view
    }
    
    public override init() { }
    
    public init<L: LayoutManager>(_ keyPath: KeyPath<L, T>) {
        super.init()
        self.keyPath = keyPath
    }
    
    private weak var manager: Layouter! {
        return anyManager as? Layouter
    }
}
