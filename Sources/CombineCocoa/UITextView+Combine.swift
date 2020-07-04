// UITextView+Combine.swift

import Combine
import UIKit

extension CBPublishers where Base: UITextView {
    public func textDidChange(containCurrentValue: Bool = false) -> AnyPublisher<String, Never> {
        let publisher = NotificationCenter.default.publisher(for: UITextView.textDidChangeNotification, object: base)
            .compactMap{ $0.object as? UITextView }
            .compactMap { $0.text }
            .replaceError(with: "")
            
        guard containCurrentValue else {
            return publisher.eraseToAnyPublisher()
        }
        return publisher
            .prepend(base.text)
            .eraseToAnyPublisher()
    }
    
    public func textDidBeginEditing() -> AnyPublisher<Void, Never> {
        NotificationCenter.default.publisher(for: UITextView.textDidBeginEditingNotification, object: base)
            .map{ _ in () }
            .eraseToAnyPublisher()
    }
    
    public func textDidEndEditing() -> AnyPublisher<Void, Never> {
        NotificationCenter.default
            .publisher(for: UITextView.textDidEndEditingNotification, object: base)
            .map{ _ in ()}
            .eraseToAnyPublisher()
    }
}
