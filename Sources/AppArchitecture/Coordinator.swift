// Coordinator.swift

import Foundation
import Combine
import UIKit

enum CoordinatorKey {
    static var children:    UInt = 0x1
    static var view:        UInt = 0x2
    static var viewModel:   UInt = 0x3
    static var controller:  UInt = 0x4
}

public protocol Coordinatable: AnyObject {
    func coordinate<Coordinator: AppArchitecture.Coordinator>(to coordinator: Coordinator) -> AnyPublisher<Coordinator.Result, Coordinator.Failure>
}

public protocol Coordinator: Coordinatable {
    associatedtype Result = Void
    associatedtype Failure = Never
    associatedtype View: ViewComponent
    associatedtype Controller: ViewHost = UIViewController
    associatedtype RootController: ViewHost = UIViewController
    associatedtype ResultPublisher: Publisher = AnyPublisher<Result, Failure> where ResultPublisher.Failure == Failure, ResultPublisher.Output == Result
        
    var cancellables: Set<AnyCancellable> { get set }
    
    func makeViewModel() -> View.ViewModel
    func makeView(viewModel: View.ViewModel) -> View
    func makeController(from: UIViewController) -> Controller
    
    func present(viewController: Controller, parentViewController: RootController)
    func dismiss(viewController: Controller)
    
    func route(with viewModel: View.ViewModel) -> ResultPublisher
    
    func willCoordinate<Child: Coordinator>(to coordinator: Child)
    func didCoordinate<Child: Coordinator>(to coordinator: Child)
    func willRelease<Child: Coordinator>(coordinator: Child)
    func didRelease<Child: Coordinator>(coordinator: Child)
}

public extension Coordinator {
    func willCoordinate<Child: Coordinator>(to coordinator: Child) { }
    
    func didCoordinate<Child: Coordinator>(to coordinator: Child) { }
    
    func willRelease<Child: Coordinator>(coordinator: Child) { }
    
    func didRelease<Child: Coordinator>(coordinator: Child) { }
}

extension Coordinatable {
    public var children: NSHashTable<AnyObject> {
        guard let table = objc_getAssociatedObject(self, &CoordinatorKey.children) as? NSHashTable<AnyObject> else {
            let table = NSHashTable<AnyObject>()
            objc_setAssociatedObject(self, &CoordinatorKey.children, table, .OBJC_ASSOCIATION_RETAIN)
            return table
        }
        return table
    }
}
extension Coordinatable {
    public func find<C: Coordinatable>(_ type: C.Type) -> C? {
        if self is C { return self as? C }
        
        for child in (children.allObjects as! [Coordinatable]) {
            guard let coordinator = child.find(type) else { continue }
            return coordinator
        }
        
        return nil
    }
    
    public func findAll<C: Coordinatable>(_ type: C.Type) -> [C] {
        if self is C { return [self as! C] }
        
        return (children.allObjects as! [Coordinatable]).flatMap {
            $0.findAll(type)
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
    
    func start(with parent: RootController) -> ResultPublisher {
        present(viewController: controller, parentViewController: parent)
        return route(with: viewModel)
    }
    
    func store<Coordinator: AppArchitecture.Coordinator>(_ coordinator: Coordinator) {
        children.add(coordinator)
    }
    
    func release<Coordinator: AppArchitecture.Coordinator>(_ coordinator: Coordinator) {
        children.remove(coordinator)
        coordinator.viewModel.cancellables = []
        coordinator.cancellables = []
    }
    
    public func coordinate<Coordinator: AppArchitecture.Coordinator>(to coordinator: Coordinator) -> AnyPublisher<Coordinator.Result, Coordinator.Failure> {
        guard !children.allObjects
            .map({ String(describing: type(of: $0))})
            .contains(String(describing: type(of: coordinator))) else {
            return Empty<Coordinator.Result, Coordinator.Failure>().eraseToAnyPublisher()
        }
        
        willCoordinate(to: coordinator)
        defer {
            didCoordinate(to: coordinator)
        }
        
        store(coordinator)
        
        Coordinator.View.setupAppearance()

        guard let controller = controller as? Coordinator.RootController else {
            fatalError("Wrong root controller type")
        }
        
        return coordinator.start(with: controller)
            .map { [weak coordinator] value -> Coordinator.Result in
                View.setupAppearance()
                guard let coordinator = coordinator else { return value }
                coordinator.dismiss(viewController: coordinator.controller)
                return value
            }
            .map { [weak self, weak coordinator] value -> Coordinator.Result in
                if let coordinator = coordinator {
                    self?.willRelease(coordinator: coordinator)
                    defer {
                        self?.didRelease(coordinator: coordinator)
                    }
                    
                    self?.release(coordinator)
                    objc_removeAssociatedObjects(coordinator)
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
    func present(viewController: Controller, parentViewController: RootController) {
        parentViewController.pushViewController(viewController, animated: true)
    }
    
    func dismiss(viewController: Controller) {
        viewController.navigationController?.popViewController(animated: true)
    }
}

public extension Coordinator where RootController: UIViewController, Controller: UIViewController {
    func present(viewController: Controller, parentViewController: RootController) {
        parentViewController.present(viewController, animated: true, completion: nil)
    }
    
    func dismiss(viewController: Controller) {
        viewController.dismiss(animated: true, completion: nil)
    }
}

public extension Coordinator where RootController == UIWindow {
    func dismiss(viewController: Controller) { }
}

public extension Coordinator where View == EmptyView {
    func makeView(viewModel: View.ViewModel) -> EmptyView { .init() }
    
    func makeViewModel() -> View.ViewModel { .init() }
}

public protocol RootCoordinator: Coordinator
where RootController == UIWindow, View == EmptyView {
    var window: UIWindow { get }
    func route() -> ResultPublisher
}

public extension RootCoordinator where Controller == UIWindow {
    func makeController(from viewController: UIViewController) -> Controller {
        window
    }
}

public extension RootCoordinator {
    func present(viewController: Controller, parentViewController: RootController) { }
    
    func dismiss(viewController: Controller) { }
    
    func route(with viewModel: View.ViewModel) -> ResultPublisher {
        route()
    }
    
    func active() -> AnyCancellable {
        if window.isKeyWindow {
            UIWindow.rootWindow = window
        }
        
        return route().sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    }
}

public final class PlainCoordinator<View: ViewComponent, ViewModel: ObservableObject>: Coordinator where View.ViewModel == ViewModel {
    
    public init(view: View) {
        self.view = view
    }
    
    let view: View
    
    public func present(viewController: UIViewController, parentViewController: UIViewController) {
        viewController.modalPresentationStyle = .overFullScreen
        parentViewController.present(viewController, animated: false, completion: nil)
    }
    
    public func makeViewModel() -> ViewModel {
        view.viewModel
    }
    
    public func makeView(viewModel: ViewModel) -> View {
        view
    }
    
    public func route(with viewModel: View.ViewModel) -> AnyPublisher<Void, Never> {
        viewModel.willDismiss.eraseToAnyPublisher()
    }
}

open class ActionCoordinator: Coordinator {
    
    private let action: () -> Void
    
    public init(action: @escaping () -> Void) {
        self.action = action
    }
    
    public func present(viewController: UIViewController, parentViewController: UIViewController) { }
    
    open func route(with viewModel: EmptyViewModel) -> AnyPublisher<Void, Never> {
        
        action()
        
        return Just(()).eraseToAnyPublisher()
    }
}
