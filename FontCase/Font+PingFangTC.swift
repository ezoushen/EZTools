// Font+PingFangTC.swift

import Foundation

public struct PingFangTC: FontNamespace { }

public extension FontSeries where Namespace == PingFangTC {
    var regular: FontCustomizer<Namespace, F> { .init(name: "Regular") }
    var ultralight: FontCustomizer<Namespace, F> { .init(name: "Ultralight") }
    var light: FontCustomizer<Namespace, F> { .init(name: "Light") }
    var thin: FontCustomizer<Namespace, F> { .init(name: "Thin") }
    var medium: FontCustomizer<Namespace, F> { .init(name: "Medium") }
    var semibold: FontCustomizer<Namespace, F> { .init(name: "Semibold") }
}

public typealias PingFangTCFontPlugin<F: FontPresentable> = FontPlugin<PingFangTC, F>

extension FontPresentable {
    public static var pingFangTC: PingFangTCFontPlugin<Self> { .init() }
}
