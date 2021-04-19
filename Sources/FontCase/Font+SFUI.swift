//  Font+SFUI.swift

import SwiftUI

public struct System: FontNamespace {
    public static var familyName: String { "" }
}

public extension FontSeries where Namespace == System {
    var regular: FontCustomizer<System, F> { .init(name: "Regular")}
    var light: FontCustomizer<System, F> { .init(name: "Light") }
    var medium: FontCustomizer<System, F> { .init(name: "Medium") }
    var semibold: FontCustomizer<System, F> { .init(name: "Semibold")}
    var bold: FontCustomizer<System, F> { .init(name: "Bold") }
    var black: FontCustomizer<System, F> { .init(name: "Black") }
    var heavy: FontCustomizer<System, F> { .init(name: "Heavy") }
}

public extension FontFamily where Namespace == System {
    var italic: FontFinalizer<System, F> {
        .init(parent: self, name: "Italic")
    }
}

public typealias SystemFontPlugin<F: FontPresentable> = FontPlugin<System, F>

extension FontPresentable {
    public static var system: SystemFontPlugin<Self> { .init() }
}
