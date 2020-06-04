// Submodel.swift

import Combine

protocol SubmodelProtocol {
    mutating func bind<T: ViewModel & ObservableObject>(to: T)
}

@propertyWrapper
public class Submodel<T: ObservableObject>: SubmodelProtocol {
    
    var subscription: AnyCancellable?
    
    weak var model: AnyObject?
    
    public var wrappedValue: T
        
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}

extension Submodel {
    func bind<T>(to model: T) where T : ViewModel & ObservableObject {
        subscription = wrappedValue.objectWillChange.sink { [weak model] _ in
            (model?.objectWillChange as? ObservableObjectPublisher)?.send()
        }
    }
}
