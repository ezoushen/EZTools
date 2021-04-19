// FontPlugin.swift

import SwiftUI

public protocol FontNamespace {
    static var familyName: String { get }
}

extension FontNamespace {
    public static var familyName: String {
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
    associatedtype Weight: FontWeight
    static func create(name: String, size: CGFloat, weight: Weight) -> Self
}

public protocol FontFinalizable: FontTarget {
    func size(_ size: CGFloat) -> F
}

public struct FontPlugin<N: FontNamespace, F: FontPresentable>: FontModifier, FontSeries, FontFinalizable {
    internal let name: String = ""
    
    public init() { }
    
    public func size(_ size: CGFloat) -> F {
        F.create(
            name: fullName(with: name),
            size: size,
            weight: F.Weight.createFromString("Regular"))
    }
}

public struct FontCustomizer<N: FontNamespace, F: FontPresentable>: FontModifier, FontFamily, FontFinalizable {
    internal let name: String
    
    public init(name: String) {
        self.name = name
    }
    
    public func size(_ size: CGFloat) -> F {
        F.create(
            name: fullName(with: name),
            size: size,
            weight: F.Weight.createFromString(name))
    }
}

public struct FontFinalizer<N: FontNamespace, F: FontPresentable>: FontModifier, FontScope, FontFinalizable {
    internal let name: String

    internal let weight: F.Weight
    
    public init<FF: FontFamily>(parent: FF, name: String) where FF.F == F, FF.N == N{
        let parentName: String = {
            if let parent = parent as? FontModifier {
                return parent.name
            }
            assertionFailure( "Invalid Font Family")
            return ""
        }()
        self.weight = .createFromString(parentName)
        self.name = "\(parentName)\(name)"
    }
    
    public init(name: String) {
        self.name = name
        self.weight = .createFromString("Regular")
    }
    
    public func size(_ size: CGFloat) -> F {
        F.create(name: fullName(with: name), size: size, weight: weight)
    }
}

extension FontFinalizable where Self: FontModifier & FontScope {
    fileprivate func fullName(with name: String) -> String {
        "\(N.familyName)\(name.isEmpty ? "" : "-\(name)")"
    }
}

extension SwiftUI.Font: FontPresentable {
    public static func create(name: String, size: CGFloat, weight: Weight) -> SwiftUI.Font {
        if name.hasPrefix("-") {
            return Font.system(size: size).weight(weight)
        }
        return Font.custom(name, size: size)
    }
}

extension UIFont: FontPresentable {
    public static func create(name: String, size: CGFloat, weight: Weight) -> Self {
        Self.init(name: name, size: size) ?? {
            let font = Self.systemFont(ofSize: size, weight: weight)
            if name.hasSuffix("Italic") {
                return UIFont(
                    descriptor: font.fontDescriptor.withSymbolicTraits(.traitItalic)!,
                    size: size) as! Self
            }
            return font as! Self
        }()
    }
}

public protocol FontWeight {
    static func createFromString(_ string: String) -> Self
}

extension UIFont.Weight: FontWeight {
    public static func createFromString(_ string: String) -> Self {
        switch string.split(separator: "-").last {
        case "UltraLight": return .ultraLight
        case "Thin": return .thin
        case "Light": return .light
        case "Regular": return .regular
        case "Medium": return .medium
        case "Semibold": return .semibold
        case "Bold": return .bold
        case "Heavy": return .heavy
        case "Black": return .black
        default: return .regular
        }
    }
}

extension Font.Weight: FontWeight {
    public static func createFromString(_ string: String) -> Self {
        switch string.split(separator: "-").last {
        case "UltraLight": return .ultraLight
        case "Thin": return .thin
        case "Light": return .light
        case "Regular": return .regular
        case "Medium": return .medium
        case "Semibold": return .semibold
        case "Bold": return .bold
        case "Heavy": return .heavy
        case "Black": return .black
        default: return .regular
        }
    }
}
