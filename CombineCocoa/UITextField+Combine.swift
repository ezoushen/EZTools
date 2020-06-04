// UITextField+Combine.swift

import UIKit
import Combine

extension CBPublishers where Base: UITextField {
    public func textDidChange(containCurrentValue: Bool = false) -> AnyPublisher<String, Never> {
        let publisher = NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: base)
            .compactMap{ $0.object as? UITextField }
            .compactMap { $0.text }
            .replaceError(with: "")
            
        guard containCurrentValue else {
            return publisher.eraseToAnyPublisher()
        }
        return publisher
            .prepend(base.text ?? "")
            .eraseToAnyPublisher()
    }
    
    public func textDidBeginEditing() -> AnyPublisher<Void, Never> {
        NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification, object: base)
            .map{ _ in () }
            .eraseToAnyPublisher()
    }
    
    public func textDidEndEditing() -> AnyPublisher<Void, Never> {
        NotificationCenter.default
            .publisher(for: UITextField.textDidEndEditingNotification, object: base)
            .map{ _ in ()}
            .eraseToAnyPublisher()
    }
}
