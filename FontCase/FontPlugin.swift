// FontPlugin.swift

import SwiftUI

public protocol FontNamespace { }

extension FontNamespace {
    static var familyName: String {
        String(describing: Self.self)
    }
}

public protocol FontTarget {
    associatedtype F: FontPresentable
}

public protocol FontScope: FontTarget {
    associatedtype N: FontNamespace
    typealias Namespace = N
}

public protocol FontFamily: FontScope { }

public protocol FontSeries: FontFamily { }

internal protocol FontModifier {
    var name: String { get }
}

public protocol FontPresentable {
    static func create(name: String, size: CGFloat) -> Self
}

public protocol FontFinalizable: FontTarget {
    func size(_ size: CGFloat) -> F
}

public struct FontPlugin<N: FontNamespace, F: FontPresentable>: FontModifier, FontSeries, FontFinalizable {
    internal let name: String = ""
    
    public init() { }
    
    public func size(_ size: CGFloat) -> F {
        F.create(name: fullName(with: name), size: size)
    }
}

public struct FontCustomizer<N: FontNamespace, F: FontPresentable>: FontModifier, FontFamily, FontFinalizable {
    internal let name: String
    
    public init(name: String) {
        self.name = name
    }
    
    public func size(_ size: CGFloat) -> F {
        F.create(name: fullName(with: name), size: size)
    }
}

public struct FontFinalizer<N: FontNamespace, F: FontPresentable>: FontModifier, FontScope, FontFinalizable {
    internal let name: String
    
    public init<FF: FontFamily>(parent: FF, name: String) where FF.F == F, FF.N == N{
        let parentName: String = {
            if let parent = parent as? FontModifier {
                return parent.name
            }
            assertionFailure( "Invalid Font Family")
            return ""
        }()
        
        self.name = "\(parentName)\(name)"
    }
    
    public init(name: String) {
        self.name = name
    }
    
    public func size(_ size: CGFloat) -> F {
        F.create(name: fullName(with: name), size: size)
    }
}

extension FontFinalizable where Self: FontModifier & FontScope {
    fileprivate func fullName(with name: String) -> String {
        "\(N.familyName)\(name.isEmpty ? "" : "-\(name)")"
    }
}

extension SwiftUI.Font: FontPresentable {
    public static func create(name: String, size: CGFloat) -> SwiftUI.Font {
        return Font.custom(name, size: size)
    }
}

extension UIFont: FontPresentable {
    public static func create(name: String, size: CGFloat) -> Self {
        Self.init(name: name, size: size)!
    }
}
