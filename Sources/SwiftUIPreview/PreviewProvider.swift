#if canImport(SwiftUI) && DEBUG
// PreviewProvider.swift

import SwiftUI
import UIKit

@available(iOS 13, *)
public protocol ViewControllerPreviewable: UIViewController, UIViewControllerRepresentable {
    static func dummy() -> Self
}

@available(iOS 13, *)
public typealias PreviewProvider = SwiftUI.PreviewProvider & ViewControllerPreviewable

@available(iOS 13, *)
public extension SwiftUI.PreviewProvider where Self: ViewControllerPreviewable {
    static func dummy() -> Self {
        Self.init()
    }
    
    static var previews: some View {
        Self.dummy()
    }
}

@available(iOS 13, *)
public extension ViewControllerPreviewable where Self: SwiftUI.PreviewProvider & UIViewController {
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<Self>) -> Self {
        self
    }
    
    func updateUIViewController(_ uiViewController: Self, context: UIViewControllerRepresentableContext<Self>) {
        
    }
}
#endif
