// LayoutManager.swift

import UIKit

public protocol Layoutee: AnyObject {
    associatedtype LayoutManager: LayoutEngine.LayoutManager
    var layoutManager: LayoutManager! { get }
}

public protocol Layouter: AnyObject {
    var view: UIView! { get set }
    
    init<L: Layoutee>(host: L, viewport: UIView)
    
    func layout()
}

public typealias LayoutManager = Layouter & KeyPathListable

extension Layouter where Self: KeyPathListable {
    public init<L: Layoutee>(host: L, viewport: UIView) {
        self.init()
        view = viewport
    }
}
