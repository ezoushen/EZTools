// Font+Avenir.swift

import SwiftUI

public struct Avenir: FontNamespace { }

public extension FontSeries where Namespace == Avenir {
    var medium: FontCustomizer<Avenir, F> { .init(name: "Medium") }
    var roman: FontCustomizer<Avenir, F> { .init(name: "Roman") }
    var black: FontCustomizer<Avenir, F> { .init(name: "Black") }
    var light: FontCustomizer<Avenir, F> { .init(name: "Light") }
    var book: FontCustomizer<Avenir, F> { .init(name: "Book") }
    var heavy: FontCustomizer<Avenir, F> { .init(name: "Heavy") }
}

public extension FontFamily where Namespace == Avenir {
    var oblique: FontFinalizer<Avenir, F> {
        .init(parent: self, name: "Oblique")
    }
}

public typealias AvenirFontPlugin<F: FontPresentable> = FontPlugin<Avenir, F>

extension FontPresentable {
    public static var avenir: AvenirFontPlugin<Self> { .init() }
}
