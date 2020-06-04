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
        exposeViews(to: host)
    }
    
    public func exposeViews<L: Layoutee>(to host: L) {
        let keyPaths = allKeyPaths
        
        Mirror(reflecting: host).children.forEach {
            guard let layout = $0.value as? AnyLayout,
                  let substring = $0.label?.dropFirst() else { return }
            layout.anyManager = self
            layout.name = String(substring)
            layout.keyPath = layout.keyPath ?? keyPaths[layout.name]
        }
    }
}
