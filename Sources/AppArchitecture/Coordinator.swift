// Coordinator.swift

import Foundation
import Combine
import UIKit

enum CoordinatorKey {
    static var parent:      UInt = 0x0
    static var children:    UInt = 0x1
    static var view:        UInt = 0x2
    static var viewModel:   UInt = 0x3
    static var controller:  UInt = 0x4
    static var hookStore:   UInt = 0x5
}

typealias LifecycleHookStore =
    [CoordinatorLifecycleHook: PassthroughSubject<any Coordinator, Never>]

public enum CoordinatorLifecycleHook: Hashable {
    case willCoordinate
    case didCoordinate
    case willRelease
    case didRelease
    case willAttach
    case didAttach
    case willDetach
    case didDetach
    case willPresent
    case didPresent
    case willDismiss
    case didDismiss
}

public protocol Coordinator: AnyObject {
    associatedtype Result = Void
    associatedtype Failure = Never
    associatedtype View: ViewComponent
    associatedtype Controller: ViewHost = UIViewController
    associatedtype RootController: ViewHost = UIViewController
    associatedtype ResultPublisher: Publisher = AnyPublisher<Result, Failure> where ResultPublisher.Failure == Failure, ResultPublisher.Output == Result
        
    var transitionHandler: ViewTransitionHandler<Controller, RootController> { get }
    var cancellables: Set<AnyCancellable> { get set }
    
    func makeViewModel() -> View.ViewModel
    func makeView(viewModel: View.ViewModel) -> View
    func makeController(from: UIViewController) -> Controller
        
    func route(with viewModel: View.ViewModel) -> ResultPublisher
    
    func willCoordinate<Child: Coordinator>(to coordinator: Child)
    func didCoordinate<Child: Coordinator>(to coordinator: Child)
    func willRelease<Child: Coordinator>(coordinator: Child)
    func didRelease<Child: Coordinator>(coordinator: Child)
    func willAttach<Parent: Coordinator>(to parent: Parent)
    func didAttach<Parent: Coordinator>(to parent: Parent)
    func willDetach<Parent: Coordinator>(from parent: Parent)
    func didDetach<Parent: Coordinator>(from parent: Parent)
    func willPresent(controller: Controller)
    func didPresent(controller: Controller)
    func willDismiss(controller: Controller)
    func didDismiss(controller: Controller)
    
    func coordinate<Coordinator: AppArchitecture.Coordinator>(to coordinator: Coordinator, animatePresentation: Bool, animateDismissal: Bool, waitUntilViewDismissed: Bool) -> AnyPublisher<Coordinator.Result, Coordinator.Failure>
}

public extension Coordinator {
    func willCoordinate<Child: Coordinator>(to coordinator: Child) { }
    func didCoordinate<Child: Coordinator>(to coordinator: Child) { }
    func willRelease<Child: Coordinator>(coordinator: Child) { }
    func didRelease<Child: Coordinator>(coordinator: Child) { }
    func willAttach<Parent: Coordinator>(to parent: Parent) { }
    func didAttach<Parent: Coordinator>(to parent: Parent) { }
    func willDetach<Parent: Coordinator>(from parent: Parent) { }
    func didDetach<Parent: Coordinator>(from parent: Parent) { }
    func willPresent(controller: Controller) { }
    func didPresent(controller: Controller) { }
    func willDismiss(controller: Controller) { }
    func didDismiss(controller: Controller) { }
}

extension Coordinator {
    public internal(set) var parent: (any Coordinator)? {
        get {
            objc_getAssociatedObject(self, &CoordinatorKey.parent) as? (any Coordinator)
        }
        set {
            objc_setAssociatedObject(self, &CoordinatorKey.parent, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }

    fileprivate var lifecycleHookStore: LifecycleHookStore {
        get {
            guard let store = objc_getAssociatedObject(self, &CoordinatorKey.hookStore) as? LifecycleHookStore else {
                let store = LifecycleHookStore()
                defer {
                    objc_setAssociatedObject(
                        self,
                        &CoordinatorKey.hookStore,
                        store,
                        .OBJC_ASSOCIATION_RETAIN)
                }
                return store
            }
            return store
        }
        set {
            objc_setAssociatedObject(self, &CoordinatorKey.hookStore, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    public var children: NSHashTable<AnyObject> {
        guard let table = objc_getAssociatedObject(self, &CoordinatorKey.children) as? NSHashTable<AnyObject> else {
            let table = NSHashTable<AnyObject>()
            objc_setAssociatedObject(self, &CoordinatorKey.children, table, .OBJC_ASSOCIATION_RETAIN)
            return table
        }
        return table
    }
}
extension Coordinator {
    public func find<C: Coordinator>(_ type: C.Type) -> C? {
        if self is C { return self as? C }
        
        for c in children.allObjects {
            guard let child = c as? any Coordinator,
                  let coordinator = child.find(type) else { continue }
            return coordinator
        }
        
        return nil
    }
    
    public func findAll<C: Coordinator>(_ type: C.Type) -> [C] {
        if self is C { return [self as! C] }
        
        return children.allObjects.flatMap { c -> [C] in
            guard let child = c as? any Coordinator else { return [] }
            return child.findAll(type)
        }
    }
}

extension Coordinator {
    public func lifecycleHook(_ hook: CoordinatorLifecycleHook) -> AnyPublisher<any Coordinator, Never> {
        if let hook = lifecycleHookStore[hook] {
            return hook.eraseToAnyPublisher()
        } else {
            let subject = PassthroughSubject<any Coordinator, Never>()
            lifecycleHookStore[hook] = subject
            return subject.eraseToAnyPublisher()
        }
    }

    func notify(hook: CoordinatorLifecycleHook, object: any Coordinator) {
        defer { lifecycleHookStore[hook]?.send(object) }
        switch hook {
        case .willCoordinate:   willCoordinate(to: object)
        case .didCoordinate:    didCoordinate(to: object)
        case .willRelease:      willRelease(coordinator: object)
        case .didRelease:       didRelease(coordinator: object)
        case .willAttach:       willAttach(to: object)
        case .didAttach:        didAttach(to: object)
        case .willDetach:       willDetach(from: object)
        case .didDetach:        didDetach(from: object)
        case .willPresent:      willPresent(controller: object.controller as! Self.Controller)
        case .didPresent:       didPresent(controller: object.controller as! Self.Controller)
        case .willDismiss:      willDismiss(controller: object.controller as! Self.Controller)
        case .didDismiss:       didDismiss(controller: object.controller as! Self.Controller)
        }
    }
}

extension Coordinator {
    public var cancellables: Set<AnyCancellable> {
        get {
            fatalError("please provide your own dispose bag")
        }
        set {
            guard !newValue.isEmpty else { return }
            fatalError("please provide your own dispose bag")
        }
    }
    
    public var viewModel: View.ViewModel {
        guard let viewModel = objc_getAssociatedObject(self, &CoordinatorKey.viewModel) as? View.ViewModel else {
            let viewModel = makeViewModel()
            objc_setAssociatedObject(self, &CoordinatorKey.viewModel, viewModel, .OBJC_ASSOCIATION_RETAIN)
            return viewModel
        }
        return viewModel
    }
    
    public var view: View {
        guard let view = objc_getAssociatedObject(self, &CoordinatorKey.view) as? View else {
            let view = makeView(viewModel: viewModel)
            objc_setAssociatedObject(self, &CoordinatorKey.view, view, .OBJC_ASSOCIATION_RETAIN)
            return view
        }
        return view
    }
    
    public var controller: Controller {
        guard let controller = objc_getAssociatedObject(self, &CoordinatorKey.controller) as? Controller else {
            let controller = makeController(from: view.asViewController())
            objc_setAssociatedObject(self, &CoordinatorKey.controller, controller, .OBJC_ASSOCIATION_RETAIN)
            return controller
        }
        return controller
    }
    
    public func start(with parent: RootController, animated: Bool) -> ResultPublisher {
        notify(hook: .willPresent, object: self)
        transitionHandler.present(
            viewController: controller,
            parentViewController: parent,
            animated: animated)
        { [weak self] in
            guard let self else { return }
            self.notify(hook: .didPresent, object: self)
        }
        return route(with: viewModel)
    }
    
    func store<Coordinator: AppArchitecture.Coordinator>(_ coordinator: Coordinator) {
        coordinator.notify(hook: .willAttach, object: self)
        defer {
            coordinator.notify(hook: .didAttach, object: self)
        }
        coordinator.parent = self
        children.add(coordinator)
    }
    
    func release<Coordinator: AppArchitecture.Coordinator>(_ coordinator: Coordinator) {
        coordinator.notify(hook: .willDetach, object: self)
        defer {
            coordinator.notify(hook: .didDetach, object: self)
        }
        children.remove(coordinator)
        coordinator.parent = nil
        coordinator.cancellables = []
    }
    
    public func coordinate<Coordinator: AppArchitecture.Coordinator>(to coordinator: Coordinator, animated: Bool = true, waitUntilViewDismissed: Bool = false) -> AnyPublisher<Coordinator.Result, Coordinator.Failure> {
        coordinate(to: coordinator, animatePresentation: animated, animateDismissal: animated, waitUntilViewDismissed: waitUntilViewDismissed)
    }
    
    public func coordinate<Coordinator: AppArchitecture.Coordinator>(to coordinator: Coordinator, animatePresentation: Bool = true, animateDismissal: Bool = true, waitUntilViewDismissed: Bool = false) -> AnyPublisher<Coordinator.Result, Coordinator.Failure> {
        guard !children.allObjects
            .map({ String(describing: type(of: $0))})
            .contains(String(describing: type(of: coordinator))) else {
            return Empty<Coordinator.Result, Coordinator.Failure>().eraseToAnyPublisher()
        }
        
        notify(hook: .willCoordinate, object: coordinator)
        defer {
            notify(hook: .didCoordinate, object: coordinator)
        }
        
        store(coordinator)
        
        Coordinator.View.setupAppearance()

        guard let controller = controller as? Coordinator.RootController else {
            fatalError("Wrong root controller type")
        }
        
        return coordinator.start(with: controller, animated: animatePresentation)
            .flatMap { [weak coordinator]
                value -> AnyPublisher<Coordinator.Result, Coordinator.Failure> in
                View.setupAppearance()
                guard let coordinator = coordinator else {
                    return Just(value)
                        .setFailureType(to: Coordinator.Failure.self)
                        .eraseToAnyPublisher()
                }
                coordinator.notify(hook: .willDismiss, object: coordinator)
                if waitUntilViewDismissed {
                    let subject = PassthroughSubject<Coordinator.Result, Coordinator.Failure>()
                    coordinator.transitionHandler.dismiss(viewController: coordinator.controller, animated: animateDismissal) {
                        coordinator.notify(hook: .didDismiss, object: coordinator)
                        subject.send(value)
                    }
                    return subject.eraseToAnyPublisher()
                } else {
                    coordinator.transitionHandler.dismiss(viewController: coordinator.controller, animated: animateDismissal) {
                        coordinator.notify(hook: .didDismiss, object: coordinator)
                    }
                    return Just(value)
                        .setFailureType(to: Coordinator.Failure.self)
                        .eraseToAnyPublisher()
                }
            }
            .map { [weak self, weak coordinator] value -> Coordinator.Result in
                if let coordinator = coordinator {
                    self?.notify(hook: .willRelease, object: coordinator)
                    defer {
                        self?.notify(hook: .didRelease, object: coordinator)
                    }
                    
                    self?.release(coordinator)
                }
                return value
            }
            .first()
            .eraseToAnyPublisher()
    }
}

public extension Coordinator where Controller == UIViewController {
    func makeController(from viewController: UIViewController) -> Controller {
        viewController
    }
}

public extension Coordinator where Controller == UINavigationController {
    func makeController(from viewController: UIViewController) -> Controller {
        .init(rootViewController: viewController)
    }
}

public extension Coordinator where RootController: UINavigationController, Controller: UIViewController {
    var transitionHandler: ViewTransitionHandler<Controller, RootController> {
        .navigationController
    }
}

public extension Coordinator where RootController: UIViewController, Controller: UIViewController {
    var transitionHandler: ViewTransitionHandler<Controller, RootController> {
        .default
    }
}

public extension Coordinator where View == EmptyView {
    func makeView(viewModel: View.ViewModel) -> EmptyView { .init() }
    func makeViewModel() -> View.ViewModel { .init() }
}
